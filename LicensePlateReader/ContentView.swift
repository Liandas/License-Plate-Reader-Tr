//
//  ContentView.swift
//  LicensePlateReader
//
//  Created by Arda Doğantemur on 5.08.2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HostedViewController()
           .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return CameraViewController()
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        }
}
