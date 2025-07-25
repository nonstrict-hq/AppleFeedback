# FB19068829

## Crash when running multiple VTSuperResolutionScalerConfiguration VTFrameProcessor sessions simultaneously

If I create multiple VTFrameProcessors and call startSession using VTSuperResolutionScalerConfiguration, the whole app crashes (doesn’t hang in the debugger).

This does not happen if I call endSession on all previous processors, and also doesn’t happen when using another configuration like VTTemporalNoiseFilterConfiguration.

This is the last log in Xcode console:

```
Missing E5 bundle resource required for loading ExecutionStreamOperation. Must re-compile the E5. Resource path = /var/mobile/Containers/Data/Application/1A71E1BD-57BB-43B8-900F-312B7EE37540/Library/Caches/com.nonstrict.VTSuperResolutionTest/com.apple.e5rt.e5bundlecache/23A5297i/3C73FD0CD9BE1EB21435BEE72B53D9B01C7C69322207A7C44517938698BDC010/11CFE1F5F203BC4863980BD5C863F0CF07F6B2B5E854E327CE5CD5D9B2614B8C.bundle/H17.bundle/main_480x272/main_mps_graph/main_mps_graph.mpsgraphpackage @ PrepareOpForEncode
FAILURE: "e5rt_execution_stream_operation_create_precompiled_compute_operation_with_options(&_operation, create_options)" returned error = 13. msg = Missing E5 bundle resource required for loading ExecutionStreamOperation. Must re-compile the E5. Resource path = /var/mobile/Containers/Data/Application/1A71E1BD-57BB-43B8-900F-312B7EE37540/Library/Caches/com.nonstrict.VTSuperResolutionTest/com.apple.e5rt.e5bundlecache/23A5297i/3C73FD0CD9BE1EB21435BEE72B53D9B01C7C69322207A7C44517938698BDC010/11CFE1F5F203BC4863980BD5C863F0CF07F6B2B5E854E327CE5CD5D9B2614B8C.bundle/H17.bundle/main_480x272/main_mps_graph/main_mps_graph.mpsgraphpackage
```
