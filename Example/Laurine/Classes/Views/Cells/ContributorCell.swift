//
//  PersonCell.swift
//  Laurine Example Project
//
//  Created by Jiří Třečák.
//  Copyright © 2015 Jiri Trecak. All rights reserved.
//

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Imports

import Foundation
import UIKit
import Haneke


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Definitions


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extension


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Protocols


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Implementation

class ContributorCell: UITableViewCell {
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    @IBOutlet fileprivate weak var personNameLb : UILabel!
    @IBOutlet fileprivate weak var personContributions : UILabel!
    @IBOutlet fileprivate weak var personIconIV : UIImageView!
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Actions
    
    func configureWithContributor(_ contributor : Contributor) {
        
        // Set username
        self.personNameLb.text = contributor.username
        
        // Set number of contribution
        self.personContributions.text = contributor.contributions == 1 ?
                                        Localizations.Contributors.Contributor.Contributed.Singular :
                                         Localizations.Contributors.Contributor.Contributed.Plural(contributor.contributions)
        
        // Set profile picture, if available
        if let profilePictureURL = URL(string: contributor.avatarURL) {
            self.personIconIV.hnk_setImageFromURL(profilePictureURL)
        }
    }
}





