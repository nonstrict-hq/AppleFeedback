#  Appending a single AVTimedMetadataGroup writes out incorrect data

Appending a single AVTimedMetadataGroup with no defined end time to a metadata track using AVAssetWriter writes out incorrect data. In some cases it isn’t written to the file at all, in other cases it’s written with an unexpected end time.

Once two or more AVTimedMetadataGroups are appended to the input the problem disappears.

(Sample project attached)

Software:
Xcode 15.0 / macOS 14.1.1

## Scenario 1:
Appending a single AVTimedMetadataGroup with a time range starting before the AVAssetWriter.startSession source time and the end set to `.invalid`.

Expected: The AVTimedMetadataGroup time range is adjusted so it spans the whole  AVAssetWriter session duration.

Actual: No AVTimedMetadataGroup is written to the file at all.

## Scenario 2:
Appending a single AVTimedMetadataGroup with a time range starting after the AVAssetWriter.startSession source time and the end set to `.invalid`.

Expected: The AVTimedMetadataGroup time range is adjusted so it ends at the time the AVAssetWriter end session is set to.

Actual: The AVTimedMetadataGroup is written to the file with a very short duration.

# Reproduction steps with attached project

- Run the project
- The app explains Scenario 1, Scenario 2 and the workaround descibed above
- Hit the run button for the scenario you want to test
- An media file is written out and read in again according to the scenario
- The read AVTimedMetadataGroup.timeranges are shown in the UI under Output

# Use case

We encounter this problem because we have a stream of real time data. The users hits record at a certain point in time, the current metadata is appended to the writer. However we’re never sure if new metadata is produced, the situation could be stable and never change. 

If such a stable scenario is the case we only write one metadata group to the track and it doesn’t appear at all in the resulting file.

## Feedback Assistant / Radar

Submitted as feedback to Apple with id: FB13420918
