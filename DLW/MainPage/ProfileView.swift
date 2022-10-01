//
//  ProfileView.swift
//  DLW
//
//  Created by Que An Tran on 1/10/22.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            VStack (alignment: .center) {
                VStack{
                    Image("Avatar")
                        .frame(width: 200, height: 200, alignment: .center)
                        .cornerRadius(100)
                }
            }
            .padding(.vertical)
            VStack (alignment: .leading) {
                HStack{
                    Text("Name:")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("Benjamin Nguyen")
                        .font(.system(size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.black)

                }
                .padding(.bottom)
                HStack{
                    Text("Email:")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text(verbatim: "benjaminnguyen@gmail.com")
                        .font(.system(size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
                .padding(.bottom)
                HStack{
                    Text("Status:")
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("Good")
                        .font(.system(size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.bottom)
                HStack{
                    Text("You are doing very well. Keep going!!")
                        .font(.system(size: 18))
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.bottom)
            }
            .frame(width: UIScreen.main.bounds.width - 50, alignment: .leading)
            .padding(.vertical)
        }
        .padding(.vertical)
        .padding(.horizontal, 20)
    }
}
