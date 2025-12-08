//
//  ErrorAlert.swift
//  Nonstrict
//
//  Created by Nonstrict on 2023-03-30.
//

import SwiftUI

struct ErrorAlert<Content: View>: View {
    @State var isPresented = false
    @Binding var error: Error?

    let title: LocalizedStringKey
    let content: Content

    var body: some View {
        content
            .onChange(of: error != nil) { _, present in
                isPresented = present
            }
            .alert(title, isPresented: $isPresented, presenting: error) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
//                Text(error.localizedDescription)
                Text((error as NSError).debugDescription)
            }
    }
}

struct ErrorAlertModifier: ViewModifier {
    let title: LocalizedStringKey
    @Binding var error: Error?

    func body(content: Content) -> some View {
        ErrorAlert(error: $error, title: title, content: content)
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, title: LocalizedStringKey = "Unexpected Error") -> some View {
        modifier(ErrorAlertModifier(title: title, error: error))
    }
}

#Preview {
    Text(verbatim: "Test")
        .errorAlert(error: .constant(nil))
}
