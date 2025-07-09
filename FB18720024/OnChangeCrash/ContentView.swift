//
//  ContentView.swift
//  OnChangeCrash
//
//  Created by Mathijs Kadijk on 09/07/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .onChange(of: Equatables(CGSize.zero)) { oldValue, newValue in
                // No-op
            }
    }
}

struct Equatables<each T: Equatable>: Equatable {
    let values: (repeat each T)

    init(_ values: repeat each T) {
        self.values = (repeat each values)
    }

    static func == (lhs: Equatables, rhs: Equatables) -> Bool {
        for isEqual in repeat each lhs.values == each rhs.values {
            guard isEqual else { return false }
        }
        return true
    }
}
