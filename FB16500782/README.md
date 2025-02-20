# FB16500782

## AVCaptureAudioDataOutputSampleBufferDelegate reports single sample buffer in different ASBD format

In certain situations, when recording audio on macOS using AVCaptureSession and AVAssetWriter, the resulting audio file can sound distorted. This issue is caused by AVCaputureSession reporting CMSampleBuffers of different formats.

This example project creates microphone recordings using AVCaptureSession. Create multiple recordings using a 24 bit (USB) microphone. Sometimes the AVCaptureAudioDataOutput delegate will get 24 bit samples before receiving 32 bit samples, which causes the AVAssetWriter to get confused.

This issue is happens consistently on macOS 15.2 and 15.3. I’ve also managed to reproduce it on macOS 14.6, but there it only happens once in 10 recordings.

