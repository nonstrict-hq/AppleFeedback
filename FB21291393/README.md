# FB21291393

## AVCaptureVideoDataOutputSampleBufferDelegate does not report dropped frames when also recording audio

When recording video using AVCaputureSession using a AVCaptureVideoDataOutput, it reports framedrops via captureOutput(didDrop:from:) delegate.

This works correctly. Until we also add a AVCaptureAudioDataOutput to the AVCaptureSession.

When the session has both video and audio output, the delegate is no longer called, instead in console it logs:

```
CMIO_Unit_Helpers_VTUtilities.cpp:1990:CloneBuffer ( NULL == blockBuffer ) && ( NULL == imageBuffer ) == true
CMIO_Unit_Convertor_VideoToolboxDecompressor.cpp:1607:DoOneToOne [0x11d99e400] EXCEPTION ON ERROR -6742
```

## Reproduction steps
- Create AVCaptureSession add AVCaptureDevice for both microphone and camera.
- Do something that causes a lot of framedrops.
- See that captureOutput(didDrop:from:) is not called, until microphone output is removed.

To help with debugging, see the attached example project.
This example project comes from a different bug report (FB21290873), where a lot of framedrops are triggered when recording full screen display together with built-in camera on MacBook Pro M4 (possibibly because of Center Stage camera).
These dropped frames only happen on MacBook Pro M4, not on MacBook Pro M1.

If you do not have access to a MacBook with Center Stage camera, you must cause frame drops in some other way to reproduce this issue.

Note that this test project doesn't correctly record a file to disk, but that's not the point, it should log about dropped frames.


Reproduced on macOS Sequoia 15.7.2
