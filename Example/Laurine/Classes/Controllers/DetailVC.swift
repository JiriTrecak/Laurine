//
//  DetailVC.swift
//  Laurine Example Project
//
//  Created by Jiří Třečák
//  Copyright © 2015 Jiri Trecak. All rights reserved.
//

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Import

import Foundation
import UIKit
import Haneke
import SafariServices


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Definitions


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Protocols


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Implementation

class DetailVC : UIViewController {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    @IBOutlet private weak var contributorProfilePictureIV : UIImageView!
    
    @IBOutlet private weak var contributorFollowersTitleLb : UILabel!
    @IBOutlet private weak var contributorFollowingTitleLb : UILabel!
    @IBOutlet private weak var contributorReposTitleLb : UILabel!
    @IBOutlet private weak var contributorNameLb : UILabel!
    @IBOutlet private weak var contributorFollowersLb : UILabel!
    @IBOutlet private weak var contributorFollowingLb : UILabel!
    @IBOutlet private weak var contributorReposLb : UILabel!
    @IBOutlet private weak var contributorLoveNoteLb : UILabel!
    @IBOutlet private weak var contributorPageBtn : UIButton!
    
    var contributor : Contributor!
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setupUI()
        self.updateWithContributor(self.contributor)
        self.loadData()
    }
    
    
    func setupUI() {
        
        // Localize. Try playing with it, so you know how fast it is to traverse through tons of strings [mostly enter, enter, enter, enter..]
        self.contributorFollowersTitleLb.text = Localizations.DetailScreen.Stats.Followers
        self.contributorFollowingTitleLb.text = Localizations.DetailScreen.Stats.Following
        self.contributorReposLb.text = Localizations.DetailScreen.Stats.Repositories
        self.contributorReposLb.text = Localizations.DetailScreen.Misc.LoveNote
        self.contributorPageBtn.setTitle(Localizations.DetailScreen.Buttons.GITHubProfile, forState: .Normal)
    }
    
    
    func updateWithContributor(contributor : Contributor) {
        
        // Update texts
        self.contributorNameLb.text = self.contributor.username
        self.contributorFollowersLb.text = String(format: "%d", self.contributor.followers)
        self.contributorFollowingLb.text = String(format: "%d", self.contributor.following)
        self.contributorReposLb.text = String(format: "%d", self.contributor.repositories)
        self.contributorPageBtn.enabled = self.contributor.detailURL != nil
        
        // Set profile pictures
        if let profilePictureURL = NSURL(string: self.contributor.avatarURL) {
            self.contributorProfilePictureIV.hnk_setImageFromURL(profilePictureURL)
        }
    }
    
    
    func loadData() {
        
        ContributorAPI.sharedInstance.updateContributor(self.contributor) { (contributor, error) -> () in
            
            if let contributor = contributor {
                self.contributor = contributor
                self.updateWithContributor(contributor)
                
            } else if let error = error {
                NSLog("error %@", error.localizedDescription)
            }
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - IBActions
    
    @IBAction func githubBtnTouchUpInside(button : UIButton) {
    
        if let githubURLString = self.contributor.githubURL, githubURL = NSURL(string: githubURLString) {
            let svc = SFSafariViewController(URL: githubURL)
            self.presentViewController(svc, animated: true, completion: nil)
        }
    }
}





