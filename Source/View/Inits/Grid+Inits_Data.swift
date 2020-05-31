//
//  Grid+Inits_Data.swift
//  ExyteGrid
//
//  Created by Denis Obukhov on 07.05.2020.
//  Copyright © 2020 Exyte. All rights reserved.
//

// swiftlint:disable line_length

import SwiftUI

extension Grid {
    public init<Data, ID>(_ data: Data, id: KeyPath<Data.Element, ID>, tracks: [GridTrack], contentMode: GridContentMode? = nil, flow: GridFlow? = nil, packing: GridPacking? = nil, spacing: GridSpacing = Constants.defaultSpacing, @AnyViewBuilder item: @escaping (Data.Element) -> ConstructionItem) where Data: RandomAccessCollection, ID: Hashable {
        
        var index = 0
        self.items = data.flatMap {
            item($0).contentViews.asGridItems(index: &index,
                            baseHash: AnyHashable([AnyHashable($0[keyPath: id]), AnyHashable(id)]))
            
        }
        self.trackSizes = tracks
        self.spacing = spacing
        self.internalContentMode = contentMode
        self.internalFlow = flow
        self.internalPacking = packing
    }
    
    public init(_ data: Range<Int>, tracks: [GridTrack], contentMode: GridContentMode? = nil, flow: GridFlow? = nil, packing: GridPacking? = nil, spacing: GridSpacing = Constants.defaultSpacing, @AnyViewBuilder item: @escaping (Int) -> ConstructionItem) {
        var index = 0
        self.items = data.flatMap {
            item($0).contentViews.asGridItems(index: &index)
        }
        self.trackSizes = tracks
        self.spacing = spacing
        self.internalContentMode = contentMode
        self.internalFlow = flow
        self.internalPacking = packing
    }
    
    public init<Data>(_ data: Data, tracks: [GridTrack], contentMode: GridContentMode? = nil, flow: GridFlow? = nil, packing: GridPacking? = nil, spacing: GridSpacing = Constants.defaultSpacing, @AnyViewBuilder item: @escaping (Data.Element) -> ConstructionItem) where Data: RandomAccessCollection, Data.Element: Identifiable {
        var index = 0
        self.items = data.flatMap {
            item($0).contentViews.asGridItems(index: &index,
                            baseHash: AnyHashable($0.id))
            
        }
        self.trackSizes = tracks
        self.spacing = spacing
        self.internalContentMode = contentMode
        self.internalFlow = flow
        self.internalPacking = packing
    }
}
