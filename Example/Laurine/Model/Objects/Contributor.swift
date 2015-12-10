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


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Object definition

class Contributor : JTDataObject {
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Data object properties
    
    var username : String!
    var avatarURL : String!
    var detailURL : String!
    var githubURL : String? = nil
    var contributions : Int = 0
    var followers : Int = 0
    var following : Int = 0
    var repositories : Int = 0
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Data object mapping
    
    override func variableMappingTable() -> [PropertyElement] {
        
        return [
            PropertyElement(remoteName: "login", localName: "username", elementDataType: .String),
            PropertyElement(remoteName: "avatar_url", localName: "avatarURL", elementDataType: .String),
            PropertyElement(remoteName: "html_url", localName: "githubURL", elementDataType: .String),
            PropertyElement(remoteName: "url", localName: "detailURL", elementDataType: .String),
            PropertyElement(remoteName: "contributions", elementDataType: .Int),
            PropertyElement(remoteName: "followers", elementDataType: .Int),
            PropertyElement(remoteName: "following", elementDataType: .Int),
            PropertyElement(remoteName: "public_repos", localName: "repositories", elementDataType: .Int)
        ]
    }
}



