//
//  main.swift
//  Untitled 2
//
//  Created by Nonstrict on 2025-04-10.
//

import Foundation

func bar() async throws -> Bool {
    true
}

func foo() async {
    let p = Date.now.timeIntervalSince1970 < 1

    do {
        let _ = try await [
            p ? bar() : nil,
        ] as [Any?]
    } catch {
    }

    print(Date(), "Did the [Any?]")
}

while true {
    Task {
        await foo()
    }

//    try await Task.sleep(for: .milliseconds(100)) // Comment this in for a slighly different crash
    print(Date(), "Looping")
}

