//
//  ContributorAPI.swift
//  Laurine Example Project
//
//  Created by Jiří Třečák
//  Copyright © 2015 Jiri Trecak. All rights reserved.
//

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Import

import Foundation
import Alamofire


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Definitions

private let BASE_URL_CONTRIBUTORS : String = "https://api.github.com/repos/JiriTrecak/Laurine/contributors"


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Protocols


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Implementation

// Declare variable to store singleton into
private let _sharedObject = ContributorAPI()

class ContributorAPI {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    class var sharedInstance: ContributorAPI {
        return _sharedObject;
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    func getContributors(handler : (contributors : [Contributor]?, error : NSError?) -> ()) {
        
        Alamofire.request(.GET, BASE_URL_CONTRIBUTORS, parameters: nil, encoding: ParameterEncoding.JSON, headers: nil)
            .responseJSON { response in
                
                if let JSON = response.result.value as? [NSDictionary] {
                    
                    // Create contributors
                    var output : [Contributor] = []
                    JSON.forEach({ (data) -> () in
                        output.append(Contributor(fromDictionary: data))
                    })
                    
                    // Notify caller
                    handler(contributors: output, error: nil)
                } else {
                    handler(contributors: nil, error: response.result.error)
                }
        }
    }
}






