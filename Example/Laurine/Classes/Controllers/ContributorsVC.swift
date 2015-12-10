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


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Protocols


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Implementation

class ContributorsVC : UIViewController {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    @IBOutlet private weak var table : UITableView!
    private var fetchedContributors : [Contributor] = []
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.loadData()
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
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    
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
}




