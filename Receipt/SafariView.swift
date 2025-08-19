//
//  SafariView.swift
//  Scontrino
//
//  Created by Zelda on 21/07/25.
//
import SwiftUI
import SafariServices
import UIKit

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let dismissButtonStyle: SFSafariViewController.DismissButtonStyle? = nil
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let view = SFSafariViewController(url: url)
        if (dismissButtonStyle != nil) {
            view.dismissButtonStyle = dismissButtonStyle!
        }
        return view
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed in this simple example
    }
}
