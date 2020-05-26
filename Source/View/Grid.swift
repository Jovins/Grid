//
//  Grid.swift
//  ExyteGrid
//
//  Created by Denis Obukhov on 17.04.2020.
//  Copyright © 2020 Exyte. All rights reserved.
//

import SwiftUI

public struct Grid: View, LayoutArranging, LayoutPositioning, Identifiable {
    public let id = 1
    @State var arrangement: LayoutArrangement?
    @State var spans: SpanPreference?
    @State var starts: StartPreference?
    @State var positions: PositionsPreference = .default
    @State var lastArrangingPreferences: ArrangingPreference?
    @State var isLoaded: Bool = false
    @Environment(\.gridContentMode) private var environmentContentMode
    @Environment(\.gridFlow) private var environmentFlow
    @Environment(\.gridPacking) private var environmentPacking
    
    let items: [GridItem]
    let spacing: GridSpacing
    let trackSizes: [GridTrack]
    
    var internalFlow: GridFlow?
    var internalPacking: GridPacking?
    var internalContentMode: GridContentMode?

    private var flow: GridFlow {
        self.internalFlow ?? self.environmentFlow ?? Constants.defaultFlow
    }
    
    private var packing: GridPacking {
        self.internalPacking ?? self.environmentPacking ?? Constants.defaultPacking
    }
    
    private var contentMode: GridContentMode {
        self.internalContentMode ?? self.environmentContentMode ?? Constants.defaultContentMode
    }
    
//    func dddd() {
//        ForEach(self.items, id: \.self) { _ in
//            Color.red
//        }
//    }

    public var body: some View {
        return GeometryReader { mainGeometry in
            ScrollView(self.scrollAxis) {
                ZStack(alignment: .topLeading) {
                    ForEach(self.items) { item in
                        item.view
                            .transformPreference(SpansPreferenceKey.self) { preference in
                                if var lastItem = preference?.items.last  {
                                    lastItem.gridItem = item
                                    preference?.items = [lastItem]
                                } else {
                                    preference = SpanPreference(items: [.init(gridItem: item)])
                                }
                            }
                            .transformPreference(StartPreferenceKey.self) { preference in
                                if var lastItem = preference?.items.last {
                                    lastItem.gridItem = item
                                    preference?.items = [lastItem]
                                } else {
                                    preference = StartPreference(items: [.init(gridItem: item)])
                                }
                            }
                            .padding(spacing: self.spacing)
                            .background(self.positionsPreferencesSetter(item: item))
                            .frame(flow: self.flow,
                                   size: self.positions[item]?.bounds.size,
                                   contentMode: self.contentMode)
                            .alignmentGuide(.leading, computeValue: { _ in  -(self.positions[item]?.bounds.origin.x ?? 0) })
                            .alignmentGuide(.top, computeValue: { _ in  -(self.positions[item]?.bounds.origin.y ?? 0) })
                            .backgroundPreferenceValue(GridBackgroundPreferenceKey.self) { preference in
                                self.cellPreferenceView(item: item, preference: preference)
                            }
                            .overlayPreferenceValue(GridOverlayPreferenceKey.self) { preference in
                                self.cellPreferenceView(item: item, preference: preference)
                            }
                    }
                }
                .frame(flow: self.flow,
                       size: mainGeometry.size,
                       contentMode: self.contentMode)
                .frame(minWidth: self.positions.size?.width,
                       maxWidth: .infinity,
                       minHeight: self.positions.size?.height,
                       maxHeight: .infinity,
                       alignment: .topLeading)
            }
            .transformPreference(ArrangingPreferenceKey.self) { preference in
                guard let starts = self.starts, let spans = self.spans else {
                    preference = nil
                    return
                }
                preference = ArrangingPreference(gridItems: self.items,
                                                 starts: starts,
                                                 spans: spans,
                                                 tracks: self.trackSizes,
                                                 flow: self.flow,
                                                 packing: self.packing)
            }
            .transformPreference(PositionsPreferenceKey.self) { preference in
                guard let arrangement = self.arrangement else { return }
                preference.environment = .init(arrangement: arrangement,
                                               boundingSize: self.corrected(size: mainGeometry.size),
                                               tracks: self.trackSizes,
                                               contentMode: self.contentMode,
                                               flow: self.flow)
            }

            .onPreferenceChange(SpansPreferenceKey.self) { spanPreferences in
                self.spans = spanPreferences
            }
            .onPreferenceChange(StartPreferenceKey.self) { startPreferences in
                self.starts = startPreferences
            }
            .onPreferenceChange(ArrangingPreferenceKey.self) { arrangingPreferences in
                guard
                    arrangingPreferences != nil,
                    let starts = self.starts,
                    let spans = self.spans
                else {
                    return
                }
                let preferences = ArrangingPreference(gridItems: self.items,
                                                      starts: starts,
                                                      spans: spans,
                                                      tracks: self.trackSizes,
                                                      flow: self.flow,
                                                      packing: self.packing)
                guard preferences != self.lastArrangingPreferences else { return }
                self.lastArrangingPreferences = preferences
                self.calculateArrangement(preferences: preferences)
            }
            .onPreferenceChange(PositionsPreferenceKey.self) { positionsPreference in
                guard let arrangement = self.arrangement else { return }
                self.positions = self.reposition(positionsPreference,
                                                   arrangement: arrangement,
                                                   boundingSize: self.corrected(size: mainGeometry.size),
                                                   tracks: self.trackSizes,
                                                   contentMode: self.contentMode,
                                                   flow: self.flow)
                self.isLoaded = true
            }
        }
        .opacity(self.isLoaded ? 1 : 0)
    }
    
    private func corrected(size: CGSize) -> CGSize {
        return CGSize(width: size.width - self.spacing.horizontal,
                      height: size.height - self.spacing.vertical)
    }
    
    private var scrollAxis: Axis.Set {
        if case .fill = self.contentMode {
            return []
        }
        return self.flow == .rows ? .vertical : .horizontal
    }

    private func calculateArrangement(preferences: ArrangingPreference) {
        let calculatedLayout = self.arrange(preferences: preferences)
        self.arrangement = calculatedLayout
        print(calculatedLayout)
    }
    
    private func cellPreferenceView<T: GridCellPreference>(item: GridItem, preference: T) -> some View {
        GeometryReader { geometry in
            preference.content(geometry.size)
        }
        .padding(spacing: self.spacing)
        .frame(width: self.positions[item]?.bounds.width,
               height: self.positions[item]?.bounds.height)
    }
    
    private func positionsPreferencesSetter(item: GridItem) -> some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: PositionsPreferenceKey.self,
                            value: PositionsPreference(items: [
                                PositionedItem(bounds: CGRect(origin: .zero, size: geometry.size),
                                               gridItem: item)],
                                                       size: nil)
            )
        }
    }
}

extension View {
    fileprivate func frame(flow: GridFlow, size: CGSize?,
                           contentMode: GridContentMode) -> some View {
        let width: CGFloat?
        let height: CGFloat?
        
        switch contentMode {
        case .fill:
            width = size?.width
            height = size?.height
        case .scroll:
            width = (flow == .rows ? size?.width : nil)
            height = (flow == .columns ? size?.height : nil)
        }
        return frame(width: width, height: height)
    }
    
    fileprivate func padding(spacing: GridSpacing) -> some View {
        var edgeInsets = EdgeInsets()
        edgeInsets.top = spacing.vertical / 2
        edgeInsets.bottom = spacing.vertical / 2
        edgeInsets.leading = spacing.horizontal / 2
        edgeInsets.trailing = spacing.horizontal / 2
        return self.padding(edgeInsets)
    }
}

struct GridView_Previews: PreviewProvider {
    static var previews: some View {
        
        VStack {
//            Grid(0..<15, tracks: 5, spacing: 5) { item in
//                if item % 2 == 0 {
//                    Color(.red)
//                        .overlay(Text("\(item)").foregroundColor(.white))
//                        .gridSpan(column: 2, row: 1)
//                } else {
//                    Color(.blue)
//                        .overlay(Text("\(item)").foregroundColor(.white))
//                }
//            }
//            
            Divider()
            
            Grid(tracks: 4, spacing: 5) {
                
                ForEach(0..<10) { _ in
                    Color.black
                }
                Color(.brown)
                    .gridSpan(column: 3, row: 1)
                
                Color(.blue)
                    .gridSpan(column: 2, row: 2)
                
                Color(.red)
                    .gridSpan(column: 1, row: 1)
                
                Color(.yellow)
                    .gridSpan(column: 1, row: 1)

                Color(.purple)
                    .gridSpan(column: 1, row: 2)

                Color(.green)
                    .gridSpan(column: 2, row: 3)

                Color(.orange)
                    .gridSpan(column: 1, row: 3)
                
                Color(.gray)
            }
        }
        .gridFlow(.rows)
        .gridPacking(.dense)
    }
}
