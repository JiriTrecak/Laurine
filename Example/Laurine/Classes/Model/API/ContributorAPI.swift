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
    
    func getContributors(_ handler : @escaping (_ contributors : [Contributor]?, _ error : NSError?) -> ()) {
        
        Alamofire.request(BASE_URL_CONTRIBUTORS, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { (response:DataResponse<Any>) in
            if let JSON = response.result.value as? [NSDictionary] {
                
                // Create contributors
                var output : [Contributor] = []
                JSON.forEach({ (data) -> () in
                    output.append(Contributor(fromDictionary: data))
                })
                
                // Notify caller
                handler(output, nil)
            } else {
                handler(nil, response.result.error as NSError?)
            }
        }
    }
    
    
    func updateContributor(_ contributor : Contributor, handler : @escaping (_ contributor : Contributor?, _ error : NSError?) -> ()) {
        
        Alamofire.request(contributor.detailURL, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { (response:DataResponse<Any>) in
            
            if let JSON = response.result.value as? NSDictionary {
                
                // Update contributor
                if contributor.updateWithDictionary(JSON) {
                    
                    // Notify caller
                    handler(contributor, nil)
                }
            } else {
                handler(nil, response.result.error as? NSError)
            }
        }
    }
}






