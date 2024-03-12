# FB13684421 - Audio stretch issue

When using `AVMutableComposition` and `scaleTimeRange` to stretch an audio file, the result gets clipped.

This example project has an input audio file "AudioStretchTest-10min.m4a" which is 10 minutes long, and ends with the words "nineteen, twenty, ending".
When running this through the `stretch` function and scaling it to the exact size of the original audio, this works correctly.
However when either scaling down or up by a couple of seconds, the resulting audio doesn't just get scaled, it also gets cut off. In this example, the word "ending" gets cut off.

For the example file "AudioStretchTest-90min.m4a" which is 90 minutes long, the cut off is larger.
