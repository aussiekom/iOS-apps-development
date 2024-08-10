//
//  ContentView.swift
//  FocusFlow
//
//  Created by Evgeniia Komarova on 07.08.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Home()
            .preferredColorScheme(.dark)
            .modelContainer(for: RecentModel.self)
        
    }
}

#Preview {
    ContentView()
}
