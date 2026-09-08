#!/usr/bin/env python3
"""
LiveWall — GPU-animated wallpaper with album cover overlay for Hyprland.

Uses GTK3 + gtk-layer-shell for Wayland wallpaper layer,
GtkGLArea for GLSL shader rendering, and file-based IPC
for receiving cover art updates from medianotify-daemon.

Usage:
    livewall.py [--shader aurora.glsl] [--cover /path/to/image]
    livewall.py --kill
"""

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_version("Gdk", "3.0")
gi.require_version("PangoCairo", "1.0")

from gi.repository import Gtk, GtkLayerShell, GLib, Gdk, Gio, Pango, PangoCairo
from OpenGL.GL import *
from PIL import Image
import argparse
import cairo
import numpy as np
import os
import signal
import sys
import struct
import time
import ctypes
from audio import AudioMonitor
from camera import CameraMonitor

# ─── Constants ──────────────────────────────────────────

IPC_DIR        = "/tmp/livewall"
COVER_FILE     = os.path.join(IPC_DIR, "cover.jpg")
COLORS_FILE    = os.path.join(IPC_DIR, "colors")
META_FILE      = os.path.join(IPC_DIR, "meta")
SHADER_FILE    = os.path.join(IPC_DIR, "shader")
TRANSITION_FILE = os.path.join(IPC_DIR, "transition")
RESTORE_FILE   = os.path.join(IPC_DIR, "restore")
PID_FILE       = os.path.join(IPC_DIR, "pid")

TRANSITION_TYPES = ["simple", "center"]

COVER_FRACTION = 0.60      # Cover height as fraction of screen height (~650px on 1080p)
COVER_RADIUS   = 0.012     # Corner radius in normalized coords
CROSSFADE_MS   = 1200      # Crossfade duration in ms
COLOR_LERP_MS  = 2000      # Color transition duration
SCREEN_TRANS_MS = 800      # Full-screen transition duration
FPS            = 60
FRAME_MS       = 1000 // FPS

DEFAULT_COLORS = [
    (0.2, 0.5, 0.8),   # Calm blue
    (0.1, 0.3, 0.6),   # Deep blue
    (0.4, 0.2, 0.7),   # Purple accent
]


# ─── Helpers ────────────────────────────────────────────

def hex_to_rgb(h):
    """Convert '#RRGGBB' or 'RRGGBB' to (r, g, b) floats."""
    h = h.strip().lstrip("#")
    if len(h) != 6:
        return None
    try:
        return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    except ValueError:
        return None

def lerp3(a, b, t):
    """Linearly interpolate between two 3-tuples."""
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


# ─── Texture Loading ────────────────────────────────────

def load_texture_from_file(path):
    """Load an image file into an OpenGL texture. Returns tex ID or None."""
    try:
        img = Image.open(path).convert("RGBA")
        data = img.tobytes()
        w, h = img.size

        tex = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, tex)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, data)
        return tex
    except Exception as e:
        print(f"[livewall] Failed to load texture {path}: {e}", file=sys.stderr)
        return None

def create_placeholder_texture(r=0.1, g=0.1, b=0.1, a=0.0):
    """Create a 1x1 transparent placeholder texture."""
    tex = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, tex)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    data = struct.pack("BBBB", int(r*255), int(g*255), int(b*255), int(a*255))
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, data)
    return tex


# ─── Shader Compilation ─────────────────────────────────

VERTEX_SHADER = """
#version 330 core
in vec2 position;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
"""

def compile_shader(source, shader_type):
    """Compile a GLSL shader, raise on error."""
    shader = glCreateShader(shader_type)
    glShaderSource(shader, source)
    glCompileShader(shader)
    if not glGetShaderiv(shader, GL_COMPILE_STATUS):
        log = glGetShaderInfoLog(shader).decode()
        raise RuntimeError(f"Shader compile error:\n{log}")
    return shader

def build_program(frag_path):
    """Build shader program from background-only shader + injected cover code."""
    with open(frag_path, "r") as f:
        frag_source = f.read()

    # If shader already has a main() (full/legacy shader), use as-is
    if "void main()" in frag_source:
        if not frag_source.startswith("#version"):
            frag_source = "#version 330 core\nout vec4 fragColor;\n" + frag_source
    else:
        # Background-only shader: inject cover compositing code
        frag_source = _build_full_shader(frag_source)

    vert = compile_shader(VERTEX_SHADER, GL_VERTEX_SHADER)
    frag = compile_shader(frag_source, GL_FRAGMENT_SHADER)

    prog = glCreateProgram()
    glAttachShader(prog, vert)
    glAttachShader(prog, frag)
    glLinkProgram(prog)

    if not glGetProgramiv(prog, GL_LINK_STATUS):
        log = glGetProgramInfoLog(prog).decode()
        raise RuntimeError(f"Shader link error:\n{log}")

    glDeleteShader(vert)
    glDeleteShader(frag)
    return prog


# Shared cover compositing code injected after the background function
COVER_TEMPLATE = """
// ─── Shared Cover Compositing (auto-injected) ──────────

uniform sampler2D uCoverTex;
uniform sampler2D uCoverNextTex;
uniform sampler2D uPrevFrame;
uniform float     uBlend;
uniform float     uCoverAlpha;
uniform vec2      uCoverCenter;
uniform vec2      uCoverSize;
uniform float     uCoverRadius;
uniform float     uScreenBlend;      // 0=old frame, 1=new state
uniform int       uScreenTransition; // 0..3

float roundedBoxSDF(vec2 center, vec2 halfSize, float radius) {
    vec2 d = abs(center) - halfSize + radius;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
}

vec4 renderCover(vec2 uv) {
    vec2 coverUV = (uv - uCoverCenter) / uCoverSize + 0.5;
    if (coverUV.x < 0.0 || coverUV.x > 1.0 || coverUV.y < 0.0 || coverUV.y > 1.0)
        return vec4(0.0);

    vec2 pixelPos = uv - uCoverCenter;
    float dist = roundedBoxSDF(pixelPos, uCoverSize * 0.5, uCoverRadius);
    if (dist > 0.002) return vec4(0.0);
    float aa = 1.0 - smoothstep(-0.003, 0.002, dist);

    vec2 tc = vec2(coverUV.x, 1.0 - coverUV.y);
    vec4 cover = mix(texture(uCoverTex, tc), texture(uCoverNextTex, tc), uBlend);
    cover.a *= aa * uCoverAlpha;
    return cover;
}

float coverShadow(vec2 uv) {
    vec2 sp = uv - uCoverCenter - vec2(0.0, -0.012);
    float d = roundedBoxSDF(sp, uCoverSize * 0.52, uCoverRadius * 1.2);
    return 0.5 * smoothstep(0.0, 0.06, -d);
}

// ─── Transition Helpers ────────────────────────────────

// Cubic ease-in-out
float easeInOut(float t) {
    return t < 0.5 ? 4.0*t*t*t : 1.0 - pow(-2.0*t + 2.0, 3.0) / 2.0;
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;

    // Render current state
    vec3 bg = background(uv);

    if (uCoverAlpha > 0.001) {
        bg *= (1.0 - coverShadow(uv) * uCoverAlpha);
        vec4 cover = renderCover(uv);
        bg = mix(bg, cover.rgb, cover.a);
    }

    // Full-screen transition
    if (uScreenBlend < 0.999) {
        float t = easeInOut(uScreenBlend);
        vec3 prev = texture(uPrevFrame, uv).rgb;

        float mask = t; // simple crossfade (default)

        if (uScreenTransition == 1) {
            // ── center ── circle growing from center
            float dist = length((uv - 0.5) * vec2(uResolution.x / uResolution.y, 1.0));
            float radius = t * 1.0;
            float coverMask = 0.0;
            if (uCoverAlpha > 0.001) {
                float cd = roundedBoxSDF(uv - uCoverCenter, uCoverSize * 0.55, uCoverRadius);
                coverMask = smoothstep(0.01, -0.01, cd);
            }
            float geo = 1.0 - smoothstep(radius - 0.06, radius, dist);
            mask = mix(geo, t, coverMask);
        }

        bg = mix(prev, bg, mask);
    }

    fragColor = vec4(bg, 1.0);
}
"""

def _build_full_shader(bg_source):
    """Combine a background-only shader with shared cover code."""
    header = "#version 330 core\nout vec4 fragColor;\n\n"
    header += "uniform vec2  uResolution;\n"
    header += "uniform float uTime;\n"
    header += "uniform vec2  uMouse;\n"
    header += "uniform vec4  uAudio;\n"
    header += "uniform sampler2D uCamera;\n"
    header += "uniform samplerCube uCubeMap;\n"
    header += "uniform vec3  uColor1, uColor2, uColor3;\n\n"
    return header + bg_source + "\n" + COVER_TEMPLATE


# ─── LiveWall Application ───────────────────────────────

class LiveWall:
    def __init__(self, shader_path, initial_cover=None):
        self.shader_path = shader_path
        self.initial_cover = initial_cover
        self.start_time = time.monotonic()

        # State
        self.program = None
        self.vao = None
        self.vbo = None
        self.width = 1920
        self.height = 1080

        # Cover textures
        self.tex_current = None
        self.tex_next = None
        self.cover_alpha = 0.0
        self.cover_alpha_target = 0.0

        # Crossfade state
        self.blend = 0.0
        self.blend_start = 0.0
        self.blending = False

        # Color state
        self.colors_current = list(DEFAULT_COLORS)
        self.colors_target = list(DEFAULT_COLORS)
        self.color_lerp_start = 0.0
        self.color_lerping = False

        # File monitor state
        self.cover_mtime = 0
        self.colors_mtime = 0
        self.meta_mtime = 0
        self.shader_mtime = 0
        self.transition_mtime = 0

        # Song metadata for text overlay
        self.song_title = ""
        self.song_artist = ""
        self.text_alpha = 0.0
        self.text_alpha_target = 0.0
        self.show_music_info = True

        # Full-screen transition (awww-style)
        # 0=fade, 1=grow, 2=wipe_left, 3=wipe_up
        self.transition_type = 0
        self.snapshot_tex = None
        self.screen_blending = False
        self.screen_blend = 1.0  # 1.0 = fully new (no transition)
        self.screen_blend_start = 0.0
        self.snapshot_ready = False

        # Mouse tracking
        self.mouse_x = 0.5
        self.mouse_y = 0.5

        # Pending shader swap (deferred to render for GL context)
        self.pending_shader_path = None

        # Background threads (lazy loading based on shader uniform usage)
        self.audio_monitor = None
        self.camera_monitor = None
        
        # Camera GL state
        self.camera_tex = None
        
        # Cubemap GL state
        self.cubemap_tex = None

        self._setup_ipc_dir()
        self._build_window()

    def _setup_ipc_dir(self):
        """Create IPC directory and write PID file."""
        os.makedirs(IPC_DIR, exist_ok=True)
        with open(PID_FILE, "w") as f:
            f.write(str(os.getpid()))
        # Remove stale restore file
        try:
            os.unlink(RESTORE_FILE)
        except FileNotFoundError:
            pass

    def _build_window(self):
        """Create GTK window with layer-shell and GL area."""
        self.window = Gtk.Window()

        # Layer shell setup — anchor to all edges, background layer
        GtkLayerShell.init_for_window(self.window)
        GtkLayerShell.set_layer(self.window, GtkLayerShell.Layer.BACKGROUND)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.LEFT, True)
        GtkLayerShell.set_anchor(self.window, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_exclusive_zone(self.window, -1)
        GtkLayerShell.set_namespace(self.window, "livewall")

        # GL area
        self.gl_area = Gtk.GLArea()
        self.gl_area.set_has_depth_buffer(False)
        self.gl_area.set_has_stencil_buffer(False)
        self.gl_area.set_required_version(3, 3)

        self.gl_area.connect("realize", self._on_realize)
        self.gl_area.connect("render", self._on_render)
        self.gl_area.connect("resize", self._on_resize)

        # Use an Overlay so we can draw text on top of the GL area
        overlay = Gtk.Overlay()
        overlay.add(self.gl_area)

        # Transparent text overlay
        self.text_area = Gtk.DrawingArea()
        self.text_area.set_halign(Gtk.Align.FILL)
        self.text_area.set_valign(Gtk.Align.FILL)
        self.text_area.connect("draw", self._on_draw_text)
        overlay.add_overlay(self.text_area)

        self.window.add(overlay)
        self.window.connect("destroy", self._on_quit)
        self.window.show_all()

        # Render loop
        GLib.timeout_add(FRAME_MS, self._tick)

        # File monitor — check every 150ms for responsiveness
        GLib.timeout_add(150, self._poll_files)

    def _on_realize(self, gl_area):
        """Initialize GL resources when the context is ready."""
        gl_area.make_current()
        if gl_area.get_error():
            print(f"[livewall] GL error: {gl_area.get_error()}", file=sys.stderr)
            return

        print(f"[livewall] GL Version: {glGetString(GL_VERSION).decode()}")
        print(f"[livewall] Shader: {os.path.basename(self.shader_path)}")

        self._check_shader_metadata(self.shader_path)

        # Build shader program
        try:
            self.program = build_program(self.shader_path)
        except RuntimeError as e:
            print(f"[livewall] {e}", file=sys.stderr)
            self._on_quit()
            return

        # VAO is required in Core Profile
        self.vao = glGenVertexArrays(1)
        glBindVertexArray(self.vao)

        # Fullscreen quad vertices
        vertices = [
            -1.0, -1.0,
             1.0, -1.0,
            -1.0,  1.0,
             1.0,  1.0,
        ]
        vertex_data = (ctypes.c_float * len(vertices))(*vertices)

        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER,
                     ctypes.sizeof(vertex_data), vertex_data, GL_STATIC_DRAW)

        # Placeholder textures
        self.tex_current = create_placeholder_texture()
        self.tex_next = create_placeholder_texture()

        # Snapshot texture for full-screen transitions
        self.snapshot_tex = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, self.snapshot_tex)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.width, self.height, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, None)

        # Load initial cover if provided
        if self.initial_cover and os.path.isfile(self.initial_cover):
            tex = load_texture_from_file(self.initial_cover)
            if tex:
                old = self.tex_current
                self.tex_current = tex
                glDeleteTextures(1, [old])
                if self.show_music_info:
                    self.cover_alpha = 1.0
                    self.cover_alpha_target = 1.0
                self._load_colors_from_cover(self.initial_cover)

        self._load_cubemap()

    def _load_cubemap(self):
        """Loads a predetermined set of 6 cubemap faces into a GL_TEXTURE_CUBE_MAP."""
        faces_dir = os.path.join(os.path.dirname(self.shader_path), "butterfly-cubemap-faces")
        if not os.path.isdir(faces_dir):
            return
            
        faces = [
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0.png",   # Face 0: Right (+X)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_1.png", # Face 1: Left (-X)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_2.png", # Face 2: Top (+Y)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_3.png", # Face 3: Bottom (-Y)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_4.png", # Face 4: Front (+Z)
            "94284d43be78f00eb6b298e6d78656a1b34e2b91b34940d02f1ca8b22310e8a0_5.png"  # Face 5: Back (-Z)
        ]
        
        self.cubemap_tex = glGenTextures(1)
        glBindTexture(GL_TEXTURE_CUBE_MAP, self.cubemap_tex)
        
        for i, face_name in enumerate(faces):
            filepath = os.path.join(faces_dir, face_name)
            try:
                img = Image.open(filepath).convert('RGB')
                img_data = np.array(list(img.getdata()), np.uint8)
                glTexImage2D(
                    GL_TEXTURE_CUBE_MAP_POSITIVE_X + i,
                    0, GL_RGB, img.width, img.height, 0,
                    GL_RGB, GL_UNSIGNED_BYTE, img_data
                )
            except Exception as e:
                print(f"[livewall-cubemap] Failed to load {filepath}: {e}")
                
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE)

    def _on_quit(self, *args):
        """Cleanup and exit."""
        if self.audio_monitor:
            self.audio_monitor.stop()
        if self.camera_monitor:
            self.camera_monitor.stop()
        Gtk.main_quit()

    def _on_resize(self, gl_area, width, height):
        """Handle window resize."""
        self.width = width
        self.height = height
        # Resize snapshot texture
        if self.snapshot_tex:
            gl_area.make_current()
            glBindTexture(GL_TEXTURE_2D, self.snapshot_tex)
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0,
                         GL_RGBA, GL_UNSIGNED_BYTE, None)

    def _check_shader_metadata(self, path):
        """Parse shader for metadata flags and required uniforms."""
        self.show_music_info = True
        uses_audio = False
        uses_camera = False
        
        try:
            with open(path) as f:
                source = f.read()
                if "// @NoMusicInfo" in source:
                    self.show_music_info = False
                    
                # Lazy-load required peripherals based on shader signature
                if "uAudio" in source:
                    uses_audio = True
                if "uCamera" in source:
                    uses_camera = True
        except IOError:
            pass
            
        # Manage AudioMonitor
        if uses_audio and self.audio_monitor is None:
            self.audio_monitor = AudioMonitor()
            self.audio_monitor.start()
        elif not uses_audio and self.audio_monitor is not None:
            self.audio_monitor.stop()
            self.audio_monitor = None
            
        # Manage CameraMonitor
        if uses_camera and self.camera_monitor is None:
            self.camera_monitor = CameraMonitor()
            self.camera_monitor.start()
        elif not uses_camera and self.camera_monitor is not None:
            self.camera_monitor.stop()
            self.camera_monitor = None
            if self.camera_tex:
                # We can't immediately delete GL textures outside the context, 
                # but we stop fetching new frames.
                pass

        if not self.show_music_info:
            self.cover_alpha_target = 0.0
            self.text_alpha_target = 0.0
        else:
            if os.path.isfile(COVER_FILE):
                self.cover_alpha_target = 1.0
            if self.song_title:
                self.text_alpha_target = 1.0

    def _take_snapshot(self):
        """Copy current framebuffer into snapshot texture for transitions."""
        if self.snapshot_tex:
            glBindTexture(GL_TEXTURE_2D, self.snapshot_tex)
            glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0,
                                self.width, self.height)

    def _start_screen_transition(self):
        """Begin full-screen transition. Snapshot must already be current."""
        self.screen_blending = True
        self.screen_blend = 0.0
        self.screen_blend_start = time.monotonic()

    def _on_render(self, gl_area, ctx):
        """Render one frame."""
        if not self.program:
            return True

        # Handle deferred shader swap (needs GL context)
        if self.pending_shader_path:
            self._check_shader_metadata(self.pending_shader_path)
            # Snapshot is already current from end-of-frame capture
            self._start_screen_transition()
            try:
                new_prog = build_program(self.pending_shader_path)
                old_prog = self.program
                self.program = new_prog
                self.shader_path = self.pending_shader_path
                glDeleteProgram(old_prog)
                print(f"[livewall] Shader loaded: {os.path.basename(self.shader_path)}")
            except RuntimeError as e:
                print(f"[livewall] Shader swap failed: {e}", file=sys.stderr)
                self.screen_blending = False
            self.pending_shader_path = None

        now = time.monotonic()
        t = now - self.start_time

        glViewport(0, 0, self.width, self.height)
        glClear(GL_COLOR_BUFFER_BIT)

        glUseProgram(self.program)

        # ── Update animations ──

        # Crossfade blend (cover art)
        if self.blending:
            elapsed = (now - self.blend_start) * 1000
            self.blend = min(elapsed / CROSSFADE_MS, 1.0)
            if self.blend >= 1.0:
                self._finish_crossfade()

        # Color lerp
        colors_now = None
        if self.color_lerping:
            elapsed = (now - self.color_lerp_start) * 1000
            ct = min(elapsed / COLOR_LERP_MS, 1.0)
            colors_now = [lerp3(self.colors_current[i], self.colors_target[i], ct)
                          for i in range(3)]
            if ct >= 1.0:
                self.colors_current = list(self.colors_target)
                self.color_lerping = False
                colors_now = None

        # Cover alpha
        da = 0.05 if self.cover_alpha_target > self.cover_alpha else -0.03
        if abs(self.cover_alpha - self.cover_alpha_target) > 0.01:
            self.cover_alpha = max(0.0, min(1.0, self.cover_alpha + da))
        else:
            self.cover_alpha = self.cover_alpha_target

        # Screen transition blend
        if self.screen_blending:
            elapsed = (now - self.screen_blend_start) * 1000
            self.screen_blend = min(elapsed / SCREEN_TRANS_MS, 1.0)
            if self.screen_blend >= 1.0:
                self.screen_blending = False
                self.snapshot_ready = False

        # ── Set uniforms ──

        def u(name):
            return glGetUniformLocation(self.program, name)

        glUniform2f(u("uResolution"), float(self.width), float(self.height))
        glUniform1f(u("uTime"), t)

        # Colors
        c = colors_now if colors_now else self.colors_current
        glUniform3f(u("uColor1"), *c[0])
        glUniform3f(u("uColor2"), *c[1])
        glUniform3f(u("uColor3"), *c[2])

        # Cover geometry
        aspect = self.width / max(self.height, 1)
        cover_h = COVER_FRACTION
        cover_w = cover_h / aspect
        glUniform2f(u("uCoverCenter"), 0.5, 0.5)
        glUniform2f(u("uCoverSize"), cover_w, cover_h)
        glUniform1f(u("uCoverRadius"), COVER_RADIUS)
        glUniform1f(u("uCoverAlpha"), self.cover_alpha)
        glUniform1f(u("uBlend"), self.blend)
        glUniform2f(u("uMouse"), self.mouse_x, self.mouse_y)
        
        # Audio bands
        if self.audio_monitor:
            b0, b1, b2, b3 = self.audio_monitor.get_bands()
            glUniform4f(u("uAudio"), float(b0), float(b1), float(b2), float(b3))
        else:
            glUniform4f(u("uAudio"), 0.0, 0.0, 0.0, 0.0)
        
        # Camera Texture update
        if self.camera_monitor:
            frame, is_new = self.camera_monitor.get_frame()
            if self.camera_tex is None:
                self.camera_tex = glGenTextures(1)
                glBindTexture(GL_TEXTURE_2D, self.camera_tex)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
                
            if is_new and frame is not None:
                glBindTexture(GL_TEXTURE_2D, self.camera_tex)
                h, w, _ = frame.shape
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, frame)

        # Full-screen transition uniforms
        sb = self.screen_blend if self.screen_blending else 1.0
        glUniform1f(u("uScreenBlend"), sb)
        glUniform1i(u("uScreenTransition"), self.transition_type)

        # Textures
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, self.tex_current or 0)
        glUniform1i(u("uCoverTex"), 0)

        glActiveTexture(GL_TEXTURE1)
        glBindTexture(GL_TEXTURE_2D, self.tex_next or 0)
        glUniform1i(u("uCoverNextTex"), 1)

        glActiveTexture(GL_TEXTURE2)
        glBindTexture(GL_TEXTURE_2D, self.snapshot_tex or 0)
        glUniform1i(u("uSnapshotTex"), 2)
        
        glActiveTexture(GL_TEXTURE3)
        glBindTexture(GL_TEXTURE_2D, self.camera_tex or 0)
        glUniform1i(u("uCamera"), 3)

        # Cubemap texture
        glActiveTexture(GL_TEXTURE4)
        glBindTexture(GL_TEXTURE_CUBE_MAP, self.cubemap_tex or 0)
        glUniform1i(u("uCubeMap"), 4)

        # Snapshot texture for screen transitions redundant mapping
        glActiveTexture(GL_TEXTURE5)
        glBindTexture(GL_TEXTURE_2D, self.snapshot_tex or 0)
        glUniform1i(u("uPrevFrame"), 5)

        # ── Draw quad ──

        glBindVertexArray(self.vao)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        pos_loc = glGetAttribLocation(self.program, "position")
        glEnableVertexAttribArray(pos_loc)
        glVertexAttribPointer(pos_loc, 2, GL_FLOAT, GL_FALSE, 0, None)

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)

        glDisableVertexAttribArray(pos_loc)
        glBindVertexArray(0)

        # Keep snapshot fresh — only when NOT transitioning
        if not self.screen_blending:
            self._take_snapshot()

        return True  # We handled the rendering

    def _tick(self):
        """Request redraw each frame and track mouse."""
        self.gl_area.queue_render()

        # Update mouse position
        seat = Gdk.Display.get_default().get_default_seat()
        if seat:
            pointer = seat.get_pointer()
            if pointer:
                screen, x, y = pointer.get_position()
                # Normalize to 0.0-1.0 and flip Y to match GL coords
                self.mouse_x = x / self.width
                self.mouse_y = 1.0 - (y / self.height)

        # Also update text overlay alpha
        da = 0.05 if self.text_alpha_target > self.text_alpha else -0.03
        if abs(self.text_alpha - self.text_alpha_target) > 0.01:
            self.text_alpha = max(0.0, min(1.0, self.text_alpha + da))
            self.text_area.queue_draw()
        elif self.text_alpha != self.text_alpha_target:
            self.text_alpha = self.text_alpha_target
            self.text_area.queue_draw()
        return True  # Keep the timeout alive

    def _on_draw_text(self, widget, cr):
        """Draw song title and artist with Cairo — bottom-left like gen-cover-wall."""
        if self.text_alpha < 0.01 or (not self.song_title and not self.song_artist):
            return

        w = widget.get_allocated_width()
        h = widget.get_allocated_height()

        x_offset = 80  # 80px from left edge

        # Artist (closer to bottom: 50px from bottom)
        if self.song_artist:
            layout = PangoCairo.create_layout(cr)
            font = Pango.FontDescription.from_string("Cal Sans 13")
            layout.set_font_description(font)
            layout.set_text(self.song_artist, -1)

            cr.set_source_rgba(1.0, 1.0, 1.0, self.text_alpha * 0.55)
            cr.move_to(x_offset, h - 50)
            PangoCairo.show_layout(cr, layout)

        # Title (above artist: 72px from bottom)
        if self.song_title:
            layout = PangoCairo.create_layout(cr)
            font = Pango.FontDescription.from_string("Cal Sans 44")
            layout.set_font_description(font)
            layout.set_text(self.song_title, -1)

            cr.set_source_rgba(1.0, 1.0, 1.0, self.text_alpha * 0.95)
            cr.move_to(x_offset, h - 72 - 44)  # account for font height
            PangoCairo.show_layout(cr, layout)

    # ─── Cover Management ────────────────────────────────

    def _start_crossfade(self, new_tex):
        """Begin crossfading from current cover to new texture."""
        if self.blending:
            self._finish_crossfade()

        # Move new texture into the 'next' slot
        old_next = self.tex_next
        self.tex_next = new_tex
        if old_next:
            glDeleteTextures(1, [old_next])

        self.blend = 0.0
        self.blend_start = time.monotonic()
        self.blending = True
        self.cover_alpha_target = 1.0

    def _finish_crossfade(self):
        """Complete the crossfade — swap textures."""
        old = self.tex_current
        self.tex_current = self.tex_next
        self.tex_next = create_placeholder_texture()
        if old:
            glDeleteTextures(1, [old])
        self.blend = 0.0
        self.blending = False

    def _start_color_lerp(self, new_colors):
        """Begin lerping background colors to new palette."""
        if self.color_lerping:
            # Snap current to wherever the lerp is
            now = time.monotonic()
            elapsed = (now - self.color_lerp_start) * 1000
            ct = min(elapsed / COLOR_LERP_MS, 1.0)
            self.colors_current = [lerp3(self.colors_current[i],
                                         self.colors_target[i], ct)
                                   for i in range(3)]

        self.colors_target = new_colors
        self.color_lerp_start = time.monotonic()
        self.color_lerping = True

    def _load_colors_from_cover(self, path):
        """Extract dominant colors from an image using Pillow."""
        try:
            img = Image.open(path).convert("RGB").resize((64, 64))
            raw = img.tobytes()
            pixels = [(raw[i], raw[i+1], raw[i+2]) for i in range(0, len(raw), 3)]

            # Simple dominant color extraction: sort by brightness buckets
            from collections import Counter
            # Quantize to reduce palette
            quantized = [(r // 32 * 32, g // 32 * 32, b // 32 * 32)
                         for r, g, b in pixels]
            common = Counter(quantized).most_common(10)

            # Pick 3 distinct colors
            colors = []
            for color, _ in common:
                r, g, b = color[0] / 255.0, color[1] / 255.0, color[2] / 255.0
                # Skip very dark or very light
                lum = 0.299 * r + 0.587 * g + 0.114 * b
                if 0.05 < lum < 0.9:
                    colors.append((r, g, b))
                if len(colors) >= 3:
                    break

            # Pad with defaults if needed
            while len(colors) < 3:
                colors.append(DEFAULT_COLORS[len(colors)])

            self._start_color_lerp(colors)
        except Exception as e:
            print(f"[livewall] Color extraction failed: {e}", file=sys.stderr)

    # ─── File Monitoring IPC ─────────────────────────────

    def _poll_files(self):
        """Poll IPC files for changes (runs every 500ms)."""

        # Check restore signal
        if os.path.isfile(RESTORE_FILE):
            if self.cover_alpha_target > 0:
                print("[livewall] Restore signal — hiding cover")
                self.cover_alpha_target = 0.0
                self.text_alpha_target = 0.0
                self._start_color_lerp(list(DEFAULT_COLORS))
            # Don't remove the file — let toggle manage it
        else:
            # Check for new cover
            try:
                mt = os.path.getmtime(COVER_FILE)
                if mt > self.cover_mtime:
                    self.cover_mtime = mt
                    print(f"[livewall] New cover detected")
                    self.gl_area.make_current()
                    tex = load_texture_from_file(COVER_FILE)
                    if tex:
                        # Screen transition handles the visual blend.
                        # Swap cover instantly — no crossfade needed.
                        self._start_screen_transition()
                        old = self.tex_current
                        self.tex_current = tex
                        if old:
                            glDeleteTextures(1, [old])
                        self.blend = 0.0
                        self.blending = False
                        if self.show_music_info:
                            self.cover_alpha = 1.0
                            self.cover_alpha_target = 1.0
                        self._load_colors_from_cover(COVER_FILE)
            except FileNotFoundError:
                pass

        # Check for metadata (title/artist)
        try:
            mt = os.path.getmtime(META_FILE)
            if mt > self.meta_mtime:
                self.meta_mtime = mt
                with open(META_FILE) as f:
                    lines = f.read().strip().split("\n")
                self.song_title = lines[0] if len(lines) > 0 else ""
                self.song_artist = lines[1] if len(lines) > 1 else ""
                if self.show_music_info:
                    self.text_alpha_target = 1.0 if self.song_title else 0.0
                print(f"[livewall] Meta: {self.song_title} — {self.song_artist}")
                self.text_area.queue_draw()
        except FileNotFoundError:
            pass

        # Check for shader hot-swap (deferred — needs GL context in render)
        try:
            mt = os.path.getmtime(SHADER_FILE)
            if mt > self.shader_mtime:
                self.shader_mtime = mt
                with open(SHADER_FILE) as f:
                    shader_name = f.read().strip()
                if shader_name:
                    new_path = find_shader(shader_name)
                    if new_path != self.shader_path:
                        print(f"[livewall] Queuing shader swap → {os.path.basename(new_path)}")
                        self.pending_shader_path = new_path
        except FileNotFoundError:
            pass

        # Check for transition style change
        try:
            mt = os.path.getmtime(TRANSITION_FILE)
            if mt > self.transition_mtime:
                self.transition_mtime = mt
                with open(TRANSITION_FILE) as f:
                    tname = f.read().strip().lower()
                if tname in TRANSITION_TYPES:
                    self.transition_type = TRANSITION_TYPES.index(tname)
                    print(f"[livewall] Transition: {tname}")
                elif tname.isdigit() and 0 <= int(tname) < len(TRANSITION_TYPES):
                    self.transition_type = int(tname)
                    print(f"[livewall] Transition: {TRANSITION_TYPES[self.transition_type]}")
        except FileNotFoundError:
            pass

        # Check for explicit color file
        try:
            mt = os.path.getmtime(COLORS_FILE)
            if mt > self.colors_mtime:
                self.colors_mtime = mt
                with open(COLORS_FILE) as f:
                    lines = [l.strip() for l in f.readlines() if l.strip()]
                colors = []
                for line in lines[:3]:
                    rgb = hex_to_rgb(line)
                    if rgb:
                        colors.append(rgb)
                if len(colors) >= 3:
                    print(f"[livewall] New colors: {colors}")
                    self._start_color_lerp(colors)
        except FileNotFoundError:
            pass

        return True  # Keep polling

    def cleanup(self):
        """Remove PID file on exit."""
        try:
            os.unlink(PID_FILE)
        except FileNotFoundError:
            pass


# ─── CLI ─────────────────────────────────────────────────

def kill_existing():
    """Kill any running livewall instance."""
    try:
        with open(PID_FILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        print(f"[livewall] Killed PID {pid}")
        os.unlink(PID_FILE)
    except (FileNotFoundError, ProcessLookupError, ValueError):
        print("[livewall] No running instance found")

def find_shader(name):
    """Resolve shader path — check local shaders/ dir."""
    # Direct path
    if os.path.isfile(name):
        return os.path.abspath(name)

    # Relative to script's shaders/ directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    shader_dir = os.path.join(script_dir, "shaders")
    candidate = os.path.join(shader_dir, name)
    if os.path.isfile(candidate):
        return candidate

    # Without extension
    candidate_ext = candidate + ".glsl"
    if os.path.isfile(candidate_ext):
        return candidate_ext

    print(f"[livewall] Shader not found: {name}", file=sys.stderr)
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="GPU-animated wallpaper with album cover")
    parser.add_argument("--shader", "-s", default="aurora.glsl",
                        help="GLSL shader file (default: aurora.glsl)")
    parser.add_argument("--cover", "-c", default=None,
                        help="Initial album cover image path")
    parser.add_argument("--kill", "-k", action="store_true",
                        help="Kill running livewall instance")
    args = parser.parse_args()

    if args.kill:
        kill_existing()
        return

    # Kill existing before starting new
    try:
        with open(PID_FILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, signal.SIGTERM)
        import time as _t
        _t.sleep(0.3)
    except (FileNotFoundError, ProcessLookupError, ValueError):
        pass

    shader_path = find_shader(args.shader)
    print(f"[livewall] Starting with shader: {shader_path}")

    app = LiveWall(shader_path, initial_cover=args.cover)

    # Graceful shutdown
    def on_signal(sig, frame):
        print(f"\n[livewall] Signal {sig}, shutting down...")
        app.cleanup()
        Gtk.main_quit()

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)

    try:
        Gtk.main()
    finally:
        app.cleanup()


if __name__ == "__main__":
    main()
