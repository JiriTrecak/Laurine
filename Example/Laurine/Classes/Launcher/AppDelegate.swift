//
//  AppDelegate.swift
//  Laurine Example Project
//
//  Created by Jiří Třečák.
//  Copyright © 2015 Jiri Trecak. All rights reserved.
//

// This is main entrypoint to the application. Every call from this class is forwarded to different classes,
// As this file is always messy if not done this way.


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Imports

import UIKit
import Foundation


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Definitions


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extension


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Protocols


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Implementation

@UIApplicationMain

class CSAppDelegate: UIResponder, UIApplicationDelegate {
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    var window : UIWindow?
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Application initialization
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let directiony = NSMutableDictionary()
        directiony.setObject("x", forKey: "x")
        
        let set = CharacterSet(in: "x")
        let y = "".trimmingCharacters(in: CharacterSet)(in: <#T##CharacterSet#>)
        y.replacingOccurrences(of: <#T##String#>, with: <#T##String#>)(separatedBy: <#T##CharacterSet#>)
        return true
    }
    
 
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Location Manager
    
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Remote notifications
    
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Watchkit integration
}




