# FB18720024

## OnChange with parameter pack and CGSizes crashes while demangling witness for associated type

When adding an onChange to my view where the monitored value is a type using parameter packs and passing into that type a CGSize the app crashes at runtime on iOS 17.

STEPS TO REPRODUCE
- Create a type using parameter packs that confirms to Equatable: `struct Equatables<each T: Equatable>: Equatable { /* … */ }`
- Use this in onChange on a SwiftUI view with a CGSize: `.onChange(of: Equatables(CGSize.zero)) { /* … */ }`
- Run the app on a device or simulator

EXPECTED
The app builds & runs as expected.

ACTUAL
On iOS 17 the app crashes as soon as the view with the onChange is needed with the following message on the console:
```
failed to demangle witness for associated type 'Body' in conformance 'OnChangeCrash.ContentView: View' from mangled name '32' - TypeDecoder.h:1369: Node kind 264 "" - unexpected kind
```

On iOS 18 & iOS 26 the app runs as expected.
