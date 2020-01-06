//
//  File.swift
//  
//
//  Created by Daniel Pourhadi on 1/5/20.
//

import Foundation
import SwiftUI

/// https://zacwhite.com/2019/scrollview-content-offsets-swiftui/
struct Run: View {
    let block: () -> Void

    var body: some View {
        DispatchQueue.main.async(execute: block)
        return AnyView(EmptyView())
    }
}


/// tweaked from  https://zacwhite.com/2019/scrollview-content-offsets-swiftui/
public struct OffsetScrollView<Content>: View where Content : View {

    private class StateStore {
        var initialOffset: CGPoint?
    }
    
    private let store = StateStore()
    
    public var content: Content

    public var axes: Axis.Set

    public var showsIndicators: Bool
    
    @State private var initialOffset: CGPoint?

    public let contentOffsetChanged: (CGPoint) -> Void

    public init(_ axes: Axis.Set = .vertical,
                showsIndicators: Bool = true,
                contentOffsetChanged: @escaping (CGPoint) -> Void,
                @ViewBuilder content: () -> Content) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.contentOffsetChanged = contentOffsetChanged
        self.content = content()
    }
    
    public var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
                GeometryReader { geometry in
                    Run {
                        let globalOrigin = geometry.frame(in: .global).origin
//                        self.store.initialOffset = self.store.initialOffset ?? globalOrigin
                        let initialOffset = CGPoint.zero
                        let offset = CGPoint(x: globalOrigin.x - initialOffset.x, y: globalOrigin.y - initialOffset.y)
                        self.contentOffsetChanged(offset)
                    }
                }.frame(width: 0, height: 0)

                content
            }
    }

}
