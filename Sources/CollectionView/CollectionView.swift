//
//  CollectionView.swift
//
//  Created by Daniel Pourhadi on 12/26/19.
//  Copyright © 2019 dan pourhadi. All rights reserved.
//

import SwiftUI

public struct CollectionView<Item, ItemContent>: View where Item : Identifiable & Equatable, ItemContent : View {
    
    public typealias CollectionViewRowHeightBlock = (_ row: Int, _ rowMetrics: GeometryProxy, _ itemSpacing: CGFloat, _ numberOfColumns: Int) -> CGFloat
    
    public enum RowHeight {
        case constant(CGFloat)
        case sameAsItemWidth
        case dynamic(CollectionViewRowHeightBlock)
    }
        
    @Binding var items: [Item]
    @Binding var selectedItems: [Item]
    @Binding var selectionMode: Bool
    
    let numberOfColumns: Int
    let itemSpacing: CGFloat
    let rowHeight: RowHeight
    let itemBuilder: (Item, _ collectionViewMetrics: GeometryProxy, _ itemMetrics: GeometryProxy) -> ItemContent
    
    let tapAction: ((Item, GeometryProxy) -> Void)?
    
    public init(items: Binding<[Item]>,
         selectedItems: Binding<[Item]>,
         selectionMode: Binding<Bool>,
         itemSpacing: CGFloat = 2,
         numberOfColumns: Int = 3,
         rowHeight: RowHeight = .sameAsItemWidth,
         tapAction: ((Item, GeometryProxy) -> Void)? = nil,
         @ViewBuilder itemBuilder: @escaping (Item, _ collectionViewMetrics: GeometryProxy, _ itemMetrics: GeometryProxy) -> ItemContent) {
        self._items = items
        self._selectedItems = selectedItems
        self._selectionMode = selectionMode
        self.itemSpacing = itemSpacing
        self.itemBuilder = itemBuilder
        self.tapAction = tapAction
        self.numberOfColumns = numberOfColumns
        self.rowHeight = rowHeight
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
                
        return GeometryReader { metrics in
            ScrollView {
                VStack(spacing: self.itemSpacing) {
                    ForEach(rows) { row in
                        self.getRow(for: row, metrics: metrics)
                    }
                }
            }
        }
    }
    
    private func getRow(for row: ItemRow, metrics: GeometryProxy) -> some View {
        return HStack(spacing: self.itemSpacing) {
            ForEach(row.items) { item in
                GeometryReader { itemMetrics in
                    Group {
                        self.itemBuilder(item, metrics, itemMetrics)
                        if self.selectionMode {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .background(self.selectedItems.contains(item) ? Color.blue : Color.clear)
                                .position(x: itemMetrics.size.width - 18, y: itemMetrics.size.height - 18)
                                
                                .shadow(radius: 2)
                        }
                    }.frame(width: itemMetrics.size.width, height: itemMetrics.size.height)
                    .onTapGesture {
                        if self.selectionMode {
                            if let index = self.selectedItems.firstIndex(of: item) {
                                self.selectedItems.remove(at: index)
                            } else {
                                self.selectedItems.append(item)
                            }
                        } else {
                            self.$selectedItems.wrappedValue = [item]
                        }
                        
                        self.tapAction?(item, itemMetrics)
                    }
                }
            }
            
        }.frame(height: self.getRowHeight(for: row.id, metrics: metrics))
        
    }
    
    private func getRowHeight(for row: Int, metrics: GeometryProxy) -> CGFloat {
        switch self.rowHeight {
        case .constant(let constant): return constant
        case .sameAsItemWidth:
            return (metrics.size.width / CGFloat(numberOfColumns)) - (itemSpacing * CGFloat(numberOfColumns - 1))
        case .dynamic(let rowHeightBlock):
            return rowHeightBlock(row, metrics, itemSpacing, numberOfColumns)
        }
    }
}
