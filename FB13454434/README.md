# Transferable with only a FileRepresentation can't be dropped on other apps 

On Ventura and Sonoma, a FileRepresentation can't be dropped on other apps.

In code I have a struct conforming to `Transferable`:

```swift
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .jpeg) { imageFromBundle in
            SentTransferredFile(imageFromBundle.url)
    }
```

This is using in the `draggable` view modifier:

```swift
    Image(.someImage)
        .draggable(myTransferableType)
```

Dropping this draggable isn't doing anything on Finder and most other apps. Putting a `NSImage` in the `draggable` view modifier has the same issue.

## Sample project
Reproduction steps with attached project.

- Run the project
- Drag one of the sample images to Finder

**Expected:** The file is copied by Finder to the folder you drop it on
**Actual:** Finder does nothing with the dropped file

## Workaround

Adding a `ProxyRepresentation` that is returning the URL does work as expected in Finder and most other apps.

## Feedback Assistant / Radar

Submitted as feedback to Apple with id: FB13454434
