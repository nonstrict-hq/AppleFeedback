# FB18313670

## Nested FileImporter in SwiftUI doesn't work without any error or warning

When a FileImporter is nested in a view hierarchy that already has a FileImporter, the importer that’s deeper nested into the view hierarchy doesn’t do anything at all. This is problematic because it’s unclear this isn’t allowed and is hard to troubleshoot without any feedback towards the developer.

Expected:
- The deeper nested FileImporter was shown as it’s declared on the view and it’s value binding is changed to true
- OR at least get a very clear runtime error that this isn’t allowed

Actual:
- Nothing happens when the value of the binding is true
