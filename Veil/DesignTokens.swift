//
//  DesignTokens.swift
//  Veil
//
//  Created by Salman Qureshi on 2/5/26.
//
import Foundation
import SwiftUI

enum DS {
    enum Spacing {
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 12
    }

    enum Text {
        static let title = Font.system(size: 22, weight: .semibold)
        static let body = Font.system(size: 15)
        static let caption = Font.system(size: 13)
    }
}

