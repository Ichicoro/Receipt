//
//  EnvVars.swift
//  Scontrino
//
//  Created by Zelda on 23/07/25.
//

import Foundation
import SwiftUI

// Define the theme options
enum ColorTheme: String, CaseIterable {
    case light
    case dark
    case auto
    
    var colorScheme: ColorScheme? {
        switch self {
        case .auto:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// Environment key for app name
private struct AppNameKey: EnvironmentKey {
    static let defaultValue = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
}

// Environment key for color theme
private struct ColorThemeKey: EnvironmentKey {
    static let defaultValue: ColorTheme = .auto
}

// Extension to access environment values
extension EnvironmentValues {
    var appName: String {
        get { AppNameKey.defaultValue ?? "Scontrino" }
    }
    
    var colorTheme: ColorTheme {
        get { self[ColorThemeKey.self] }
        set { self[ColorThemeKey.self] = newValue }
    }
}
