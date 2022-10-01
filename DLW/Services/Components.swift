//
//  Components.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import Foundation
import SwiftUI

/// Hide/show password field
struct SecureTextField: View {
    @State var isSecureField: Bool = true
    @Binding var text:String
    
    var body: some View {
        if isSecureField {
            SecureField("", text: $text)
                .overlay(alignment: .trailing) {
                    Image("CloseEye")
                        .onTapGesture {
                            isSecureField = false
                        }
                }
        } else {
            TextField("", text: $text)
                .overlay(alignment: .trailing) {
                    Image("OpenEye")
                        .onTapGesture {
                            isSecureField = true
                        }
                }
        }
    
    }
}
