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
    
    @IBOutlet fileprivate weak var tableHeaderLb : UILabel!
    @IBOutlet fileprivate weak var footerLb : UILabel!
    @IBOutlet fileprivate weak var table : UITableView!
    
    fileprivate var fetchedContributors : [Contributor] = []
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setupUI()
        self.loadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let indexPath = self.table.indexPathForSelectedRow {
            self.table.deselectRow(at: indexPath, animated: true)
        }
    }
    
    
    fileprivate func setupUI() {
        
        // Setup navigation bar
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.navigationController?.navigationBar.tintColor = UIColor.darkGray
        
        // Localize. Try playing with it, so you know how fast it is to traverse through tons of strings [mostly enter, enter, enter, enter..]
        self.tableHeaderLb.text = Localizations.Contributors.Header
        self.footerLb.text = Localizations.Contributors.Footer
    }
        
    
    
    fileprivate func loadData() {
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Forward contributor object if we are showing profile page
        if segue.identifier! == SEGUE_SHOW_DETAIL {
            let dvc = segue.destination as! DetailVC
            dvc.contributor = sender as! Contributor
        }
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extension UITableViewDataSource

extension ContributorsVC : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedContributors.count
    }
}


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extension UITableViewDelegate

extension ContributorsVC : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get configured cell
        let cell = table.dequeueReusableCell(withIdentifier: CELL_IDENTIFIER_CONTRIBUTORS) as! ContributorCell
        self.configureContributorCell(cell, forIndexPath: indexPath)
        return cell
    }
    
    
    func configureContributorCell(_ cell: ContributorCell, forIndexPath indexPath: IndexPath) {
        
        let contributor = self.fetchedContributors[(indexPath as NSIndexPath).row]
        cell.configureWithContributor(contributor)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let contributor = self.fetchedContributors[(indexPath as NSIndexPath).row]
        self.performSegue(withIdentifier: SEGUE_SHOW_DETAIL, sender: contributor)
    }
}




