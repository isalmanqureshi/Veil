//
//  AuthState.swift
//  Veil
//
//  Created by Salman Qureshi on 2/11/26.
//
import Foundation

enum AuthState: Equatable {
    case signedOut
    case onboarding
    case requiresPasswordReset(user: UserIdentity)
    case signedIn(user: UserIdentity)
}

