# FB21290873

## MacBook Pro M4 cannot record build-in camera and screen at the same time

On MacBook Pro M4 Pro, we cannot record the 12MP Center Stage camera at its highest resolution (1920x1080), when also screen recording the build-in display at its maximum resolution (1800x1169 retina).
The camera preview becomes very laggy, and the `AVCaptureVideoDataOutputSampleBufferDelegate` reports lots of dropped frames.

This exact same setup does work on MacBook Pro M1. Presumably because it does not have Center Stage camera.

## Reproduction steps
- Create AVCaptureSession add AVCaptureDevice from build-in camera
- Add AVCaptureVideoDataOutput and record using AVAssetWriter (see WebcamRecorder in example project)
- Create SCStream for any screen with resolution of at least 1800 width (which it also build-in screen set to More Space)
- Add SCStreamOutput and record video using AVAssetWriter (see ScreenRecorder in example project)
- Do something on recorded display that triggers many screen updates (for example move mouse quickly)
- See log from captureOutput(didDrop:from:) that many frames are dropped in WebcamRecorder

## Workarounds
To be able to record without framedrops:

- Use different camera
- Switch to HEVC recording instead of H264
- Record screen or webcam at lower resolution
- Record screen or webcam at lower fps


Reproduced on macOS Sequoia 15.7.2
