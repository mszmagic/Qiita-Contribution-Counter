//
//  userTableView.swift
//  QiitaContributionReport
//
//  Created by Shunzhe Ma on 5/25/20.
//  Copyright © 2020 Shunzhe Ma. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class userTableView: UITableViewController, articleRequestDelegate {
    
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profileDetailLabel: UILabel!
    
    @IBOutlet weak var totalLGTMCount: UILabel!
    var totalLGTM = 0
    
    @IBOutlet weak var totalReadsCount: UILabel!
    var totalReads = 0
    
    
    var allItems = [Article]()
    
    //userToken is passed to here by the caller
    var userToken: String!
    
    let helper = requestHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = headerView
        helper.delegate = self
        helper.userID = userToken
        helper.getUserDetails { (profileImagePath, userName, description, error) in
            if error == nil {
                DispatchQueue.main.async {
                    self.profileNameLabel.text = userName
                    self.profileDetailLabel.text = description
                }
                //Download and load the image
                if let imagePath = profileImagePath,
                    let convertedURL = URL(string: imagePath) {
                    DispatchQueue.main.async {
                        self.profileImageView.kf.setImage(with: convertedURL)
                    }
                }
            } else {
                //Show the error message
                self.navigationController?.popViewController(animated: true)
                (error ?? "Unknown error").showSimpleAlert(on: self.navigationController)
            }
        }
        helper.getArticles()
    }
    
    func updateCounter(){
        totalLGTMCount.text = String(totalLGTM)
        totalReadsCount.text = String(totalReads)
    }
    
    func onReceivingNewArticleInformation(item: Article) {
        DispatchQueue.main.async {
            self.allItems.append(item)
            self.allItems.sort { (one, two) -> Bool in
                return one.likeCount > two.likeCount
            }
            //Update the counter
            self.totalLGTM += item.likeCount
            self.totalReads += item.readCount
            //UI
            self.updateCounter()
            self.tableView.reloadData()
        }
    }
    
    func onTaskFailed(reason: String) {
        //Show the error message
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            reason.showSimpleAlert(on: self.navigationController)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let item = allItems[indexPath.row]
        cell.textLabel?.text = item.articleTitle
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = "\(String(item.likeCount)) likes and \(String(item.readCount)) reads"
        return cell
    }
    
}
