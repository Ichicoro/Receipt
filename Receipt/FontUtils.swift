//
//  FontUtils.swift
//  Scontrino
//
//  Created by Zelda on 23/07/25.
//

import SwiftUI

extension Font {
    static func system(size:CGFloat,type:FontSpaceMonoType = .Regular) -> Font{
        self.custom(type.rawValue, size: size)
    }
}

enum FontSpaceMonoType:String {
    case Regular = "SpaceMono-Regular"
    case Bold = "SpaceMono-Bold"
    case Italic = "SpaceMono-Italic"
    case BoldItalic = "SpaceMono-BoldItalic"
}

extension View {
    func spaceMonoFont(size: CGFloat) -> some View {
        self.font(.system(size: size))
    }
    
    func spaceMonoFontDefault() -> some View {
        spaceMonoFont(size: 16)
    }
}
