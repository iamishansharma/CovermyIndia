//
//  AppDelegate.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 09/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

import UIKit
import MapmyIndiaAPIKit
import MapmyIndiaMaps
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        MapmyIndiaAccountManager.setMapSDKKey("dxt9f2evifm8nnkbdcuqsomtycbe4mgg")
        MapmyIndiaAccountManager.setRestAPIKey("mmlfw69s552qew2coqskegikpbe64fz2")
        MapmyIndiaAccountManager.setAtlasClientId("7qKHY0W0yHTenIX5aY7PyYsvn7b79UDsymHK9cxrux2P667-BhANctdPkwD_uEuGCLJE1E5eX0VMviOTJwegSg==")
        MapmyIndiaAccountManager.setAtlasClientSecret("9K_q_9Q2GHMk1AYFgJc7y4HSDeZjTFXL3-UM3u2QVHSdR6a8-Phv6pSQu91-yfWu9C8bEbeqewn0A7ekpxnQLhkNg0DbK1Av")
        MapmyIndiaAccountManager.setAtlasGrantType("client_credentials") //always put client_credentials
        //MapmyIndiaAccountManager.setAtlasAPIVersion("1.3.11") // Optional; deprecated
        FirebaseApp.configure();
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

