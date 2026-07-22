//
//  DefaultsKey.swift
//  Veil
//
//  Central namespace for UserDefaults keys shared across auth/session code.
//  Previously these string literals were duplicated across AuthStore,
//  LocalAuthContext, LocalDataWiper, and MockAuthRepository — a rename or
//  typo in one place could silently desync sign-in state.
//

import Foundation

enum DefaultsKey {
    static let isSignedIn = "veil.session.isSignedIn"
    static let username = "veil.currentUser.username"
}
