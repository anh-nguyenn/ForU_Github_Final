//
//  UserViewController.swift
//  DLW
//
//  Created by Que An Tran on 30/9/22.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private var userModel = UserModel.shared

class UserController {
    
    static let shared: UserController = UserController()
    
    enum UserControllerError: Error {
        case error
    }
    func login(credentials: Credentials, completion: @escaping (Result<Bool,UserControllerError>) -> Void) async {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task {
                let signInDataDict: [String: Any] = [
                    "email": credentials.email,
                    "password": credentials.password,
                ]
                do{
                    let signInDataJSON = try JSONSerialization.data(withJSONObject: signInDataDict)
                    
                    var request = URLRequest(url: URL(string: "http:ec2-35-78-81-138.ap-northeast-1.compute.amazonaws.com:3000/user/signin")!)
                    request.httpMethod = "POST"
                    request.httpBody = signInDataJSON
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let session = URLSession.shared
                    let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                        guard let data = data, error == nil else {
                            print(error.debugDescription)
                            userModel.showProgressView = false
                            completion(.failure(UserControllerError.error))
                            return
                        }
                        if String(data: data, encoding: .utf8)! == "Account do not exists" || String(data: data, encoding: .utf8)! == "Email or password is invalid!" {
                            completion(.failure(UserControllerError.error))
                        } else {
                            let defaults = UserDefaults.standard
                            defaults.set("true", forKey: DefaultsKeys.isSignedIn)
                            completion(.success(true))
                        }
                        print(String(data: data, encoding: .utf8)!)
                    })
                    task.resume()
                    
                } catch {
                    userModel.showProgressView = false
                    completion(.failure(UserControllerError.error))
                }
            }
        }
    }
    

    func signup(signupCredentials: SignUpCredentials, completion: @escaping (Result<Bool,UserControllerError>) -> Void) async {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            Task {
                let signUpDataDict: [String: Any] = [
                    "email": signupCredentials.email,
                    "password": signupCredentials.password,
                ]
                do{
                    let signUpDataJSON = try JSONSerialization.data(withJSONObject: signUpDataDict)
                    
                    var request = URLRequest(url: URL(string: "http:ec2-35-78-81-138.ap-northeast-1.compute.amazonaws.com:3000/user/createuser")!)
                    request.httpMethod = "POST"
                    request.httpBody = signUpDataJSON
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let session = URLSession.shared
                    let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                        guard let data = data, error == nil else {
                            print(error.debugDescription)
                            userModel.showProgressView = false
                            completion(.failure(UserControllerError.error))
                            return
                        }
                        completion(.success(true))
                        print(String(data: data, encoding: .utf8)!)
                        userModel.errorMessage = ""
                    })
                    task.resume()
                    
                } catch {
                    userModel.errorMessage = "Something went wrong"
                    userModel.showProgressView = false
                    completion(.failure(UserControllerError.error))
                }
            }
        }
    }
    
}
