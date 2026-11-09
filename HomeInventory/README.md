# Home Inventory MVP

Drop-in Swift source package for the existing Xcode project.

## Install
1. Back up the current project folder.
2. In Xcode, delete the existing Swift files from the HomeInventory group using **Remove Reference** or replace matching files.
3. Drag all `.swift` files from this package into the blue HomeInventory folder. Check the HomeInventory target.
4. Add `Privacy - Camera Usage Description` with value `Scan product barcodes for household inventory.` under Target > Info.
5. Build and run on the iPhone.

## Included
- Five-tab UI
- Locations: add, rename, reorder, archive
- Products and package variants
- Barcode scan with VisionKit
- Open Food Facts lookup service scaffold
- Sealed packages and opened percentage
- Per-location stock
- Low, out, and Needs Review status
- Automatic shopping-list entry when stock is low/out
- Ranked preferred stores stored per product
- Activity history
- Local offline SwiftData storage

## Deferred / requires paid Apple Developer membership
- CloudKit household sharing and production iCloud sync
- Push/background daily 8:00 AM summary
- Member identity and owner permissions
- Conflict replication across multiple iPhones
- Product photo download/camera replacement
- Siri, widgets, expiration tracking, export

The project currently uses local SwiftData so it works with a Personal Team. CloudKit sharing should be enabled after enrollment in the Apple Developer Program.
