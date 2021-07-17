//
//  AzureTestApp.swift
//  AzureTest
//
//  Created by 상구 on 2021/07/07.
//

import SwiftUI
import AlamofireNetworkActivityLogger
import AlamofireNetworkActivityIndicator

@main
struct AzureCommuncationChat: App {
    var appSettings = AppSettings()
    private(set) var tokenService: TokenService!
    
    init() {
        NetworkActivityLogger.shared.level = .debug
        NetworkActivityLogger.shared.startLogging()
        
        NetworkActivityIndicatorManager.shared.isEnabled = true
        tokenService = TokenService(communicationTokenFetchUrl: appSettings.communicationTokenFetchUrl)
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tokenService)
                .environmentObject(appSettings)
        }
    }
}

