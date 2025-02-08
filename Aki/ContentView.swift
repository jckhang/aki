//
//  ContentView.swift
//  Aki
//
//  Created by JYXC- DZ-0100219 on 2025/2/8.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationView {
            ImageGenerationView()
                .navigationTitle("Aki")
        }
    }
}

#Preview {
    ContentView()
}
