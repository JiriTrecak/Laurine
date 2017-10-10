//
//  Contributor.swift
//  Laurine Example Project
//
//  Created by Jiří Třečák
//  Copyright © 2015 Jiri Trecak. All rights reserved.
//

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Imports

import Foundation
import Warp


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Object definition

class Contributor : WRPObject {
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Data object properties
    
    @objc dynamic var username : String!
    @objc dynamic var avatarURL : String!
    @objc dynamic var detailURL : String!
    @objc dynamic var githubURL : String? = nil
    @objc dynamic var contributions : Int = 0
    @objc dynamic var followers : Int = 0
    @objc dynamic var following : Int = 0
    @objc dynamic var repositories : Int = 0
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Data object mapping
    
    override func propertyMap() -> [WRPProperty] {
        
        return [
            WRPProperty(remote: "login", bindTo: "username", type: .string),
            WRPProperty(remote: "avatar_url", bindTo: "avatarURL", type: .string),
            WRPProperty(remote: "html_url", bindTo: "githubURL", type: .string),
            WRPProperty(remote: "url", bindTo: "detailURL", type: .string),
            WRPProperty(remote: "contributions", type: .int),
            WRPProperty(remote: "followers", type: .int),
            WRPProperty(remote: "following", type: .int),
            WRPProperty(remote: "public_repos", bindTo: "repositories", type: .int)
        ]
    }
}



