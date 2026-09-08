import cv2
import threading
import time
import numpy as np

class CameraMonitor:
    def __init__(self, camera_index=0, width=640, height=480):
        self.camera_index = camera_index
        self.width = width
        self.height = height
        self.running = False
        self.thread = None
        self.cap = None
        
        # Latest frame as RGB numpy array
        self.current_frame = None
        self.frame_lock = threading.Lock()
        
        # Flag to indicate if a new frame is available for texture upload
        self.new_frame = False

    def start(self):
        if self.running: return
        self.running = True
        self.thread = threading.Thread(target=self._camera_loop, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=1.0)
        if self.cap:
            self.cap.release()

    def get_frame(self):
        """Returns (frame_rgb, is_new). If no frame, returns (None, False)."""
        with self.frame_lock:
            if self.current_frame is not None:
                is_new = self.new_frame
                self.new_frame = False
                return self.current_frame, is_new
            return None, False

    def _camera_loop(self):
        # Open the default camera using V4L2 (Linux)
        self.cap = cv2.VideoCapture(self.camera_index, cv2.CAP_V4L2)
        if not self.cap.isOpened():
            print(f"[livewall-camera] Error: Could not open camera {self.camera_index}.")
            self.running = False
            return
            
        # Try to set resolution
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.width)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.height)
        
        print(f"[livewall-camera] Started capturing from camera {self.camera_index}")
        
        while self.running:
            ret, frame = self.cap.read()
            if not ret:
                time.sleep(0.05)
                continue
                
            # OpenCV returns BGR, convert to RGB for OpenGL
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Flip horizontally for mirror effect (standard for webcams)
            frame_rgb = cv2.flip(frame_rgb, 1)
            
            with self.frame_lock:
                self.current_frame = frame_rgb
                self.new_frame = True
                
            # ~30fps limit
            time.sleep(0.033)
