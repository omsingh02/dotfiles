import os
import sys
import time
import struct
import numpy as np
import threading
import subprocess
import pulsectl

class AudioMonitor:
    def __init__(self):
        self.running = False
        self.thread = None
        
        # 4 frequency bands: Bass, Low-Mid, Mid, High
        self.bands = [0.0, 0.0, 0.0, 0.0]
        
        # Smoothing (attack/release for snappiness + low jitter)
        self.smooth_bands = [0.0, 0.0, 0.0, 0.0]
        self.attack = 0.2  # Fast rise (low latency)
        self.release = 0.85 # Slow fall (removes jitter)
        
        # Audio params
        self.rate = 44100
        self.chunk_size = 512  # Smaller chunk = lower latency
        
    def _get_monitor_device(self):
        try:
            with pulsectl.Pulse('livewall') as pulse:
                return pulse.server_info().default_sink_name + '.monitor'
        except Exception as e:
            print(f"[livewall-audio] Warning: Could not get pulse monitor: {e}")
            return None

    def start(self):
        if self.running: return
        self.running = True
        self.thread = threading.Thread(target=self._audio_loop, daemon=True)
        self.thread.start()

    def stop(self):
        self.running = False
        if self.thread:
            self.thread.join(timeout=1.0)
            
    def get_bands(self):
        return tuple(self.smooth_bands)

    def _audio_loop(self):
        device = self._get_monitor_device()
        if not device:
            return

        print(f"[livewall-audio] Listening on {device}")
        
        cmd = [
            'parec',
            '--format=s16le',
            '--rate=44100',
            '--channels=1',
            '--latency-msec=10',
            '--process-time-msec=10',
            f'--device={device}'
        ]
        
        try:
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            
            bytes_to_read = self.chunk_size * 2 # 16-bit = 2 bytes per sample
            
            while self.running:
                data = process.stdout.read(bytes_to_read)
                if not data or len(data) != bytes_to_read:
                    time.sleep(0.01)
                    continue
                    
                # Convert binary to numpy array of 16-bit ints
                samples = np.frombuffer(data, dtype=np.int16)
                
                # Apply Hann window to reduce spectral leakage
                windowed = samples * np.hanning(len(samples))
                
                # Compute FFT
                fft_out = np.abs(np.fft.rfft(windowed)) / len(samples)
                
                # Normalize kinda
                fft_out = fft_out / 256.0
                
                # Frequency bins mapping (rate=44100, chunk=512 -> ~86Hz per bin)
                # Band 0 (Bass): 20Hz - 250Hz (bins 1-3)
                # Band 1 (Low Mid): 250Hz - 1000Hz (bins 3-12)
                # Band 2 (Mid): 1000Hz - 4000Hz (bins 12-46)
                # Band 3 (High): 4000Hz - 16000Hz (bins 46-186)
                
                b0 = np.mean(fft_out[1:3])   if len(fft_out) > 3 else 0
                b1 = np.mean(fft_out[3:12])  if len(fft_out) > 12 else 0
                b2 = np.mean(fft_out[12:46]) if len(fft_out) > 46 else 0
                b3 = np.mean(fft_out[46:186]) if len(fft_out) > 186 else 0
                
                # Update current bands (reduced multipliers for much lower sensitivity)
                self.bands = [
                    min(1.0, b0 * 0.4),
                    min(1.0, b1 * 0.5),
                    min(1.0, b2 * 0.6),
                    min(1.0, b3 * 0.7),
                ]
                
                # Smooth the data with attack/release envelopes
                for i in range(4):
                    if self.bands[i] > self.smooth_bands[i]:
                        # Attack: fast rise
                        self.smooth_bands[i] = (self.smooth_bands[i] * self.attack) + (self.bands[i] * (1.0 - self.attack))
                    else:
                        # Release: slow fall to reduce jitter
                        self.smooth_bands[i] = (self.smooth_bands[i] * self.release) + (self.bands[i] * (1.0 - self.release))
                    
        except Exception as e:
            print(f"[livewall-audio] Audio loop error: {e}")
        finally:
            if 'process' in locals():
                process.terminate()
