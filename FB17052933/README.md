# FB17052933

## Studio Display Camera does not produce frames, once every 24 times

This might be a hardware/driver issue specially with the Apple Studio Display Camera.

Occasionally this camera doesn’t return CMSampleBuffers, the delegate isn’t called, and AVCaptureVideoPreviewLayer remains black.

This example project starts an AVCaptureSession and waits for frames, until a timeout occurs. Once a frame is returned, the session is stopped again, and then it loops.

For every other camera tested, this loops more than 100 times without problems, but for Apple Studio Display Camera, this fails after 24 times.

This issue doesn't occur if:
- A different app also uses the camera (it never shuts down)
- Center Stage is active (either by user or app)

Reproduced on 3 different physical Studio Display devices, different Macs and on macOS 14 and 15.
