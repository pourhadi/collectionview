//
//  CollectionView.swift
//
//  Created by Daniel Pourhadi on 12/26/19.
//  Copyright © 2019 dan pourhadi. All rights reserved.
//

import Combine
import SwiftUI

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

public struct CollectionView<Item, ItemContent>: View where ItemContent: View, Item: Identifiable & Equatable {
    private struct Row<Content>: View where Content: View {
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
        
        var body: some View {
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
        
        return Group {
            GeometryReader { metrics in
                ScrollView {
                    VStack(spacing: self.itemSpacing) {
                        ForEach(rows) { row in
                            self.getRow(for: row, metrics: metrics).padding(self.layout.rowPadding)
                        }
                    }.coordinateSpace(name: ScrollViewCoordinateSpaceKey)
                }
            }
        }
    }
    
    private func getRow(for row: ItemRow, metrics: GeometryProxy) -> some View {
        return Row(selectedItems: self.selectedItems, selectionMode: self.selectionMode) {
            HStack(spacing: self.itemSpacing) {
                ForEach(row.items) { item in
                    GeometryReader { itemMetrics in
                        ZStack {
                            Group {
                                self.itemBuilder(item, itemMetrics)
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
        let w = ((width - (self.layout.rowPadding.leading + self.layout.rowPadding.trailing + (self.layout.itemSpacing * CGFloat(self.layout.numberOfColumns - 1)))) / CGFloat(self.layout.numberOfColumns))
        
        return w
    }
    
    private func getRowHeight(for row: Int, metrics: GeometryProxy?) -> CGFloat {
        guard let metrics = metrics else { return 0 }
        
        switch self.rowHeight {
        case .constant(let constant): return constant
        case .sameAsItemWidth:
            return self.getColumnWidth(for: metrics.size.width)
        case .dynamic(let rowHeightBlock):
            return rowHeightBlock(row, metrics, self.itemSpacing, self.numberOfColumns)
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
        { item, _ in
            Rectangle()
                .foregroundColor(item.color)
        }
    }
}
