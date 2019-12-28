# CollectionView

A SwiftUI implementation of a grid layout similar to UICollectionView with UICollectionViewFlowLayout.

Updates and documentation to follow.

## Usage

Add `import CollectionView` to your SwiftUI file and add `CollectionView(...)` to your view hierarchy. 

```swift
import SwiftUI
import CollectionView

struct CollectionView_Previews: PreviewProvider {
    struct ItemModel: Identifiable, Equatable {
        let id: Int
        let color: Color
    }
    
    @State static var items = [ItemModel(id: 0, color: Color.red),
                               ItemModel(id: 1, color: Color.blue),
                               ItemModel(id: 2, color: Color.green),
                               ItemModel(id: 3, color: Color.yellow),
                               ItemModel(id: 4, color: Color.orange),
                               ItemModel(id: 5, color: Color.purple)]
    
    @State static var selectedItems = [ItemModel]()
    @State static var selectionMode = false
    
    static var previews: some View {
        CollectionView(items: $items,
                       selectedItems: $selectedItems,
                       selectionMode: $selectionMode)
        { item, _, _ in
            Rectangle()
                .foregroundColor(item.color)
        }
    }
}

```
![Screenshot](https://github.com/pourhadi/collectionview/blob/master/screenshot.png?raw=true)

### CollectionView init parameters

 * `items: Binding<[Item]>`

    Required. 

    A binding to an array of values that conform to `Identifiable` and `Equatable`. This is the collection view's data source.

* `selectedItems: Binding<[Item]>`

    Required.

    A binding to an array of values that conform to `Identifiable` and `Equatable`.

    When `selectionMode` is true, this will populate with the items selected by the user. When `selectionMode` is false, this will either be an empty array or be populated with the most-recently-selected item.

* `selectionMode: Binding<Bool>`

    Required.

    A binding to a bool value. Set to true to set the collection view in to selection mode.

* `itemSpacing: CGFloat`

    Not required. Defaults to 2.0.

    The distance between successive items in a row and between rows.

* `numberOfColumns: Int`

    Not required. Defaults to 3.

    The number of columns in a row.

* `rowHeight: CollectionView.RowHeight`

    Not required. Defaults to CollectionView.RowHeight.sameAsItemWidth.

    An enum for setting the desired height for the collection view's rows.

     ```swift
     public typealias CollectionViewRowHeightBlock = (_ row: Int, _ rowMetrics: GeometryProxy, _ itemSpacing: CGFloat, _ numberOfColumns: Int) -> CGFloat
         
     public enum RowHeight {
         case constant(CGFloat)
         case sameAsItemWidth
         case dynamic(CollectionViewRowHeightBlock)
     }
      ```

* `tapAction: ((Item, GeometryProxy) -> Void)?`

    Not required. Defaults to nil.

    A block that will be called if an item is tapped on.

* `itemBuilder: @escaping (Item, _ collectionViewMetrics: GeometryProxy, _ itemMetrics: GeometryProxy) -> ItemContent)`

    Required.

    A block that produces the view (cell) associated with a particular item.

## Planned features:
* Sections
* Customizable selection style
* ??

## Installation

#### Swift Package Manager
You can use [The Swift Package Manager](https://swift.org/package-manager) to install this library.

```swift
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    targets: [],
    dependencies: [
        .package(url: "https://github.com/pourhadi/collectionview.git", .branch("master"))    
    ]
)
```

Note that the [Swift Package Manager](https://swift.org/package-manager) is still in early design and development, for more information checkout its [GitHub Page](https://github.com/apple/swift-package-manager).

## License (MIT)

Copyright (c) 2019 - present Daniel Pourhadi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
