//
//  ImgurUser.swift
//  ImgurStarter
//
//  Created by Stuart Levine on 5/25/18.
//  Copyright © 2018 Wildcat Productions. All rights reserved.
//

import Foundation
import SafariServices
import KeychainSwift

fileprivate struct Constants {
    static let kImgurUsernameKey = "com.wildcatproductions.imgurlUsernameKey"
    static let kImgurAuthTokenKey = "com.wildcatproductions.imgurAuthTokenKey"
    static let kImgurRefreshTokenKey = "com.wildcatproductions.imgurRefreshTokenKey"
    static let kImgurUserIdKey = "com.wildcatproductions.imgurUserIdKey"
    static let kImgurAuthTokenExpiryKey = "com.wildcatproductions.imgurAuthTokenExpiryKey"

}

//  This struct holds all the necessary information to make calls
//  to the Imgur API for a particular logged in user
//  The information is retrieved from and stored to the Apple Keychain
//

struct ImgurUser {

    // Keys used for mapping API properties to the struct properties
    struct ApiKeys {
        static let accountId = "account_id"
        static let accountUsername = "account_username"
        static let accessToken = "access_token"
        static let expires_in = "expires_in"
        static let refreshToken = "refresh_token"
    }
    // Boolean value to determine if we are loading the struct's data from
    // the keychain, which bypasses the didSet blocks for the properties.
    var isLoadingFromKeychain = false

    // the imgur username
    var username: String = "" {
        didSet {
            if !self.isLoadingFromKeychain {
                KeychainSwift().set(self.username, forKey: Constants.kImgurUsernameKey)
            }
        }
    }
    // the imgur account id
    var userId: String = "" {
        didSet {
            if !self.isLoadingFromKeychain {
                KeychainSwift().set(self.userId, forKey: Constants.kImgurUserIdKey)
            }
        }
    }
    // barer authtoken
    var authToken: String = "" {
        didSet {
            if !self.isLoadingFromKeychain {
                KeychainSwift().set(self.authToken, forKey: Constants.kImgurAuthTokenKey)
            }
        }
    }
    // the token's expiry in seconds
    var authTokenExpiry: String = "" {
        didSet {
            if !self.isLoadingFromKeychain {
                KeychainSwift().set(self.authTokenExpiry, forKey: Constants.kImgurAuthTokenExpiryKey)
            }
        }
    }
    // the refresh token used to reauthenticate
    var refreshToken: String = "" {
        didSet {
            if !self.isLoadingFromKeychain {
                KeychainSwift().set(self.refreshToken, forKey: Constants.kImgurRefreshTokenKey)
            }
        }
    }

    // The authorization header with the Bearer authToken for making api calls
    lazy var authHeader: [String: String] = {
        return ["Authorization" : "Bearer \(authToken)"]
    }()

    // This method will take the query items from the Outh2 callback response
    // and parse the items into the struct for use to make imgur API calls.
    //
    // @param url URL
    //
    // @example
    // ?access_token=XXXXXXXXXXXXXXXXXXXXXXXXXX&expires_in=315360000&token_type=bearer&refresh_token=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&account_username=someuser&account_id=0000000

    mutating func importValuesFrom(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems {
            for item in queryItems {
                if let value = item.value {
                    switch item.name {
                    case ApiKeys.accessToken:
                        self.authToken = value
                    case ApiKeys.accountId:
                        self.userId = value
                    case ApiKeys.accountUsername:
                        self.username = value
                    case ApiKeys.expires_in:
                        self.authTokenExpiry = value
                    case ApiKeys.refreshToken:
                        self.refreshToken = value
                    default: break
                    }
                }
            }
        }
    }

    // log the user out and clear all the struct properties and hence the keychain values
    //
    mutating func logout() {
        username = ""
        userId = ""
        authToken = ""
        authTokenExpiry = ""
        refreshToken = ""
    }

    // load all the properties from the keychain - called once on app launch
    mutating func loadFromKeychain() {
        isLoadingFromKeychain = true

        if let username = KeychainSwift().get(Constants.kImgurUsernameKey) {
            self.username = username
        }
        if let userId = KeychainSwift().get(Constants.kImgurUserIdKey) {
            self.userId = userId
        }
        if let authToken = KeychainSwift().get(Constants.kImgurAuthTokenKey) {
            self.authToken = authToken
        }
        if let authTokenExpiry = KeychainSwift().get(Constants.kImgurAuthTokenExpiryKey) {
            self.authTokenExpiry = authTokenExpiry
        }
        if let refreshToken = KeychainSwift().get(Constants.kImgurRefreshTokenKey) {
            self.refreshToken = refreshToken
        }

        isLoadingFromKeychain = false
    }

    // a getter that returns the user's login status
    var isAuthenticated: Bool {
        return  (
            !self.authToken.isEmpty ||
                !self.username.isEmpty ||
                !self.userId.isEmpty ||
                !self.authTokenExpiry.isEmpty ||
                !self.refreshToken.isEmpty
        )
    }
}
