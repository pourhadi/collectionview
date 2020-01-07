//
//  CollectionView.swift
//
//  Created by Daniel Pourhadi on 12/26/19.
//  Copyright © 2019 dan pourhadi. All rights reserved.
//

import SwiftUI
import Combine

private let AssociationManager = NSObject()

fileprivate struct AssociatedKeys {
    static var store: UInt8 = 0
}

public extension CollectionView {
    func rowPadding(_ padding: EdgeInsets) -> Self {
        self.layout.rowPadding = padding
        return self
    }
    
    func itemSpacing(_ itemSpacing: CGFloat) -> Self {
        self.layout.itemSpacing = itemSpacing
        return self
    }
    
    func numberOfColumns(_ numberOfColumns: Int) -> Self {
        self.layout.numberOfColumns = numberOfColumns
        return self
    }
    
    func rowHeight(_ rowHeight: RowHeight) -> Self {
        self.layout.rowHeight = rowHeight
        return self
    }
}

fileprivate let ScrollViewCoordinateSpaceKey = "ScrollViewCoordinateSpace"

private struct LazyRowContainer<Content> : View where Content : View {
    
    @State var visible = false
    
    let content: (Bool) -> Content
    let visibleRowsPublisher: AnyPublisher<[Int], Never>
    let rowId: Int
    
    init(rowId: Int,
         visibleRowsPublisher: AnyPublisher<[Int], Never>,
         currentVisibleRows: [Int],
         @ViewBuilder _ content: @escaping (Bool) -> Content) {
        self.rowId = rowId
        self.visibleRowsPublisher = visibleRowsPublisher
        self.content = content
        
        self.visible = currentVisibleRows.contains(rowId)
    }
    
    var body : some View {
        return self.content(self.visible)
            .onReceive(self.visibleRowsPublisher) { (visibleRows) in
                let vis = visibleRows.contains(self.rowId)
                
                if vis != self.visible {
                    self.visible = vis
                }
        }
    }
    
}


public struct AsynchronousView : View {
    
    @State var content: AnyView? = nil
    
    let contentFuture: AnyPublisher<AnyView?, Never>

    public var body : some View {
        Group {
            if content != nil {
                self.content!
            }
            
            EmptyView()
        }.onReceive(self.contentFuture) { (content) in
            self.content = content
        }
    }
}

public struct CollectionView<Item, ItemContent>: View where ItemContent : View, Item : Identifiable & Equatable {
    private struct Row<Content> : View where Content : View {
        
        @Binding var selectedItems: [Item]
        @Binding var selectionMode: Bool
        
        let content: () -> Content
        
        init(selectedItems: Binding<[Item]>,
             selectionMode: Binding<Bool>,
             @ViewBuilder content: @escaping () -> Content) {
            self._selectedItems = selectedItems
            self._selectionMode = selectionMode
            self.content = content
        }
        
        var body : some View {
            self.content()
        }
        
    }
    
    
    public struct Layout {
        public var rowPadding: EdgeInsets
        public var numberOfColumns: Int
        public var itemSpacing: CGFloat
        public var rowHeight: RowHeight
        
        public init(rowPadding: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    numberOfColumns: Int = 3,
                    itemSpacing: CGFloat = 2,
                    rowHeight: RowHeight = .sameAsItemWidth) {
            self.rowPadding = rowPadding
            self.numberOfColumns = numberOfColumns
            self.itemSpacing = itemSpacing
            self.rowHeight = rowHeight
        }
    }
    
    
    private class StateStore: ObservableObject {
        
        init() {
            print("init it")
        }
        
        var totalRows = 0
        var mainMetrics: GeometryProxy?
        
        var mainFrame = CGRect.zero
        
        var parent: CollectionView?
        var scrollViewFrame = CGRect.zero
        var contentOffset = CGPoint.zero {
            didSet {
                guard let mainMetrics = mainMetrics else { return }
                var visible = [Int]()
                
                let boundingFrame = CGRect(x: 0, y: -(mainMetrics.safeAreaInsets.top) - (mainMetrics.size.height / 2), width: mainMetrics.size.width, height: mainMetrics.size.height + (mainMetrics.size.height))
                
                
                var currentY: CGFloat = 0
                for x in 0..<self.totalRows {
                    let height = self.height(for: x)
                    let frame = CGRect(x: 0, y: currentY + contentOffset.y, width: mainMetrics.size.width, height: height)
                    
                    if frame.intersects(boundingFrame) {
                        visible.append(x)
                    }
                    
                    currentY += height
                }
                
                print(visible.count)
                self.visibleRows = visible
            }
        }
        
        var rowFrames = [Int: CGRect]()
        
        @Published var visibleRows = [Int]()
        
        var metrics = [GeometryProxy]()
        
        func height(for row: Int) -> CGFloat {
            guard let parent = parent, let metrics = mainMetrics else {
                return 0
            }
            
            return parent.getRowHeight(for: row, metrics: metrics) + parent.layout.rowPadding.top + parent.layout.rowPadding.bottom
        }
    }
    
    @ObservedObject private var _store: StateStore
    private var store:StateStore {
        if _store.parent == nil {
            _store.parent = self
        }
        
        return _store
    }
    
    public typealias CollectionViewRowHeightBlock = (_ row: Int, _ rowMetrics: GeometryProxy, _ itemSpacing: CGFloat, _ numberOfColumns: Int) -> CGFloat
    
    public enum RowHeight {
        case constant(CGFloat)
        case sameAsItemWidth
        case dynamic(CollectionViewRowHeightBlock)
    }
    
    @State private var layout: Layout = Layout()
    
    @Binding private var items: [Item]
    
    private var selectedItems: Binding<[Item]>
    private var selectionMode: Binding<Bool>
    
    private var numberOfColumns: Int {
        return self.layout.numberOfColumns
    }
    
    private var itemSpacing: CGFloat {
        return self.layout.itemSpacing
    }
    
    private var rowHeight: RowHeight {
        return self.layout.rowHeight
    }
    
    private let itemBuilder: (Item, GeometryProxy) -> ItemContent
    private let tapAction: ((Item, GeometryProxy) -> Void)?
    private let longPressAction: ((Item, GeometryProxy) -> Void)?
    private let pressAction: ((Item, Bool) -> Void)?
    

    public init(items: Binding<[Item]>,
                selectedItems: Binding<[Item]>,
                selectionMode: Binding<Bool>,
                layout: Layout = Layout(),
                tapAction: ((Item, GeometryProxy) -> Void)? = nil,
                longPressAction: ((Item, GeometryProxy) -> Void)? = nil,
                pressAction: ((Item, Bool) -> Void)? = nil,
                @ViewBuilder itemBuilder: @escaping (Item, GeometryProxy) -> ItemContent) {
        self._items = items
        self.selectedItems = selectedItems
        self.selectionMode = selectionMode
        self.itemBuilder = itemBuilder
        self.tapAction = tapAction
        self.longPressAction = longPressAction
        self.pressAction = pressAction
        self.layout = layout
    }
    
    private struct ItemRow: Identifiable {
        let id: Int
        let items: [Item]
    }
    
    public var body: some View {
        var currentRow = [Item]()
        var rows = [ItemRow]()
        
        for item in self.items {
            currentRow.append(item)
            
            if currentRow.count >= self.numberOfColumns {
                rows.append(ItemRow(id: rows.count, items: currentRow))
                currentRow = []
                
            }
        }
        
        if currentRow.count > 0 {
            rows.append(ItemRow(id: rows.count, items: currentRow))
        }
        
        self.store.totalRows = rows.count
        
        return Group {
            GeometryReader { metrics in
                ScrollView {
                    VStack(spacing: self.itemSpacing) {
                        ForEach(rows) { row in
                            
                            LazyRowContainer(rowId: row.id, visibleRowsPublisher: self.store.$visibleRows, currentVisibleRows: self.store.visibleRows) { (visible) -> _ in
                                self.getRow(for: row, metrics: metrics, visible: visible).padding(self.layout.rowPadding)

                            }
                        }
                    }.onAppear(perform: {
                        self.store.mainMetrics = metrics
                        self.store.scrollViewFrame = metrics.frame(in: .global)
                        print("appear")
                    }).coordinateSpace(name: ScrollViewCoordinateSpaceKey)
                }
            }
        }
    }
    
    private func getRow(for row: ItemRow, metrics: GeometryProxy, visible: Bool) -> some View {
        return Row(selectedItems: self.selectedItems, selectionMode: self.selectionMode) {
            HStack(spacing: self.itemSpacing) {
                ForEach(row.items) { item in
                    GeometryReader { itemMetrics in
                        ZStack {
                            Group {
                                if visible {
                                    self.itemBuilder(item, itemMetrics)
                                }
                                if self.selectionMode.wrappedValue {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                        .background(self.selectedItems.wrappedValue.contains(item) ? Color.blue : Color.clear)
                                        .position(x: itemMetrics.size.width - 18, y: itemMetrics.size.height - 18)
                                        .shadow(radius: 2)
                                }
                            }
                            .zIndex(2)
                                .allowsHitTesting(false)

                            Group {
                                Rectangle().foregroundColor(Color.clear)
                            }
                            .background(Color(UIColor.systemBackground))
                                .allowsHitTesting(true)
                                .zIndex(1)
                                .onTapGesture {
                                    if self.selectionMode.wrappedValue {
                                        if let index = self.selectedItems.wrappedValue.firstIndex(of: item) {
                                            self.selectedItems.wrappedValue.remove(at: index)
                                        } else {
                                            self.selectedItems.wrappedValue.append(item)
                                        }
                                    } else {
                                        self.selectedItems.wrappedValue = [item]
                                    }
                                    
                                    self.tapAction?(item, itemMetrics)
                            }
                            .onLongPressGesture(minimumDuration: 0.25, maximumDistance: 10, pressing: { pressing in
                                self.pressAction?(item, pressing)
                                
                            }) {
                                self.longPressAction?(item, itemMetrics)
                            }
                        }
                    }
                }
            }.frame(height: self.getRowHeight(for: row.id, metrics: metrics))

                
        }
        
    }
    
    private func getColumnWidth(for width: CGFloat) -> CGFloat {
        let w = (((width - (self.layout.rowPadding.leading + self.layout.rowPadding.trailing + (self.layout.itemSpacing * CGFloat(self.layout.numberOfColumns - 1)))) / CGFloat(self.layout.numberOfColumns)))
        
        return w
    }
    
    private func getRowHeight(for row: Int, metrics: GeometryProxy?) -> CGFloat {
        guard let metrics = metrics else { return 0 }
        
        switch self.rowHeight {
        case .constant(let constant): return constant
        case .sameAsItemWidth:
            return self.getColumnWidth(for: metrics.size.width)
        case .dynamic(let rowHeightBlock):
            return rowHeightBlock(row, metrics, itemSpacing, numberOfColumns)
        }
    }
}


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
        { item, metrics in
            Rectangle()
                .foregroundColor(item.color)
        }
    }
}
