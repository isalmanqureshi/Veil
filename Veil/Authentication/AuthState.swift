//
//  AuthState.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//
import Foundation

enum AuthState: Equatable {
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        return true
    }
    
    case signedOut
    case onboarding
    case signedIn(user: UserIdentity)
}

