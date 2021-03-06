//
//  AppDelegate.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/18.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("set audioSession fail")
        }
        return true
    }
}

