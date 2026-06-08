# FB22966216

## AVAssetWriter finishWriting hangs forever when a large CMSampleBuffer is appended

Appending a single audio `CMSampleBuffer` whose sample (frame) count is ≥ 2^27 (134,217,728) to an `AVAssetWriterInput` configured to encode AAC (`kAudioFormatMPEG4AAC`) causes the Core Media audio-compression thread to spin at 100% CPU indefinitely. `AVAssetWriter.finishWriting(completionHandler:)` never calls its completion handler. The writer never finalizes, so the operation hangs forever and the output file is never produced.

Below 2^27 frames, encoding time is linear and fast (~0.7 ms per second of audio). At 2^27 frames it jumps from ~2 s to never completing. Appending the **same total audio** as multiple smaller buffers (e.g. 1-second buffers) finalizes normally in seconds.

## Steps to Reproduce

Append a CMSampleBuffer with a large amount of audio to an AVAssetWriter and then call finishWriting on that writer.

A swift file with the reproduction example that shows the issue on macOS is attached.

## Expected result

Either it should just work as expected or it should throw/report an error.

## Actual Results

The audio-compression thread loops at 100% CPU and `finishWriting`'s completion handler is never called.
