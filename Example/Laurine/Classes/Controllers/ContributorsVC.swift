//
//  ContributorsVC.swift
//  Laurine Example Project
//
//  Created by Jiří Třečák.
//  Copyright © 2015 Jiri Trecak. All rights reserved.
//

// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Import

import Foundation
import UIKit


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Definitions

private let CELL_IDENTIFIER_CONTRIBUTORS : String = "ContributorCell"
private let SEGUE_SHOW_DETAIL : String = "ShowDetailVC"


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Protocols


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Implementation

class ContributorsVC : UIViewController {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    @IBOutlet private weak var tableHeaderLb : UILabel!
    @IBOutlet private weak var footerLb : UILabel!
    @IBOutlet private weak var table : UITableView!
    
    private var fetchedContributors : [Contributor] = []
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setupUI()
        self.loadData()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let indexPath = self.table.indexPathForSelectedRow {
            self.table.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    
    private func setupUI() {
        
        // Setup navigation bar
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: self, action: nil)
        self.navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
        
        // Localize. Try playing with it, so you know how fast it is to traverse through tons of strings [mostly enter, enter, enter, enter..]
        self.tableHeaderLb.text = Localizations.Contributors.Header
        self.footerLb.text = Localizations.Contributors.Footer
    }
        
    
    
    private func loadData() {
        
        ContributorAPI.sharedInstance.getContributors { (contributors, error) -> () in
            
            if let contributors = contributors {
                self.fetchedContributors = contributors
                self.table.reloadData()
            } else if let error = error {
                NSLog("error %@", error.localizedDescription)
            }
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Public
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Forward contributor object if we are showing profile page
        if segue.identifier! == SEGUE_SHOW_DETAIL {
            let dvc = segue.destinationViewController as! DetailVC
            dvc.contributor = sender as! Contributor
        }
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extension UITableViewDataSource

extension ContributorsVC : UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedContributors.count
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extension UITableViewDelegate

extension ContributorsVC : UITableViewDelegate {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Get configured cell
        let cell = table.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER_CONTRIBUTORS) as! ContributorCell
        self.configureContributorCell(cell, forIndexPath: indexPath)
        return cell
    }
    
    
    func configureContributorCell(cell: ContributorCell, forIndexPath indexPath: NSIndexPath) {
        
        let contributor = self.fetchedContributors[indexPath.row]
        cell.configureWithContributor(contributor)
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let contributor = self.fetchedContributors[indexPath.row]
        self.performSegueWithIdentifier(SEGUE_SHOW_DETAIL, sender: contributor)
    }
}




