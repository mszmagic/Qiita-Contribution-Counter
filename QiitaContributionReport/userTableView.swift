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
import SafariServices

class userTableView: UITableViewController, articleRequestDelegate {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profileDetailLabel: UILabel!
    @IBOutlet weak var contributionViewContainer: UIView!
    
    @IBOutlet weak var totalLGTMCount: UILabel!
    var totalLGTM = 0
    
    @IBOutlet weak var totalReadsCount: UILabel!
    var totalReads = 0
    
    // UITableViewによってデータソースとして利用されます
    var allItems = [Article]()
    
    //userToken は呼び出し側からここに渡されます
    var userToken: String!
    
    //サーバーへの全てのリクエストを行うヘルパー
    let helper = requestHelper()
    
    /*
     現在の月の第1日から今日までをカウントする配列
     */
    var contributionBlock = [[Int]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //リクエストヘルパーをセットアップします
        helper.delegate = self
        helper.userID = userToken
        //ユーザーの基本情報を読み込みます
        loadUserDetails()
        //ユーザーの記事を読み込みます
        helper.getArticles()
        //配列をセットアップします
        let numberOfFullWeeks = Date().getWeekNumber() + 1
        for _ in 0..<numberOfFullWeeks {
            contributionBlock.append(.init(repeating: 0, count: 7))
        }
        //UI
        tableView.tableHeaderView = headerView
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 10
    }
    
    /*
     プロフィール画像、名前、および概要など、ユーザーの基本情報を取得します。
     */
    func loadUserDetails(){
        getUserDetails(userID: userToken, completionHandler: { (profileImagePath, userName, description, error) in
            if error == nil {
                DispatchQueue.main.async {
                    self.profileNameLabel.text = userName
                    self.profileDetailLabel.text = description
                }
                //画像をダウンロードして読み込みます
                if let imagePath = profileImagePath,
                    let convertedURL = URL(string: imagePath) {
                    DispatchQueue.main.async {
                        self.profileImageView.kf.setImage(with: convertedURL)
                    }
                }
            } else {
                //エラーメッセージを表示します
                self.navigationController?.popViewController(animated: true)
                (error ?? "Unknown error").showSimpleAlert(on: self.navigationController)
            }
        })
    }
    
    /*
     UI
     */
    func updateCounter(){
        totalLGTMCount.text = String(totalLGTM)
        totalReadsCount.text = String(totalReads)
        //コントリビューションブロック
        ///前回追加された LSHContributionView を削除します
        contributionViewContainer.subviews.forEach { (subview) in
            subview.removeFromSuperview()
        }
        ///新しい LSHContributionView をセットアップします
        let contributionView = LSHContributionView(frame: CGRect(origin: .zero, size: contributionViewContainer.frame.size))
        contributionView.data = contributionBlock.transposed()
        contributionViewContainer.addSubview(contributionView)
    }
    
    // MARK: Delegate functions 取得済みの記事の情報を取得する関数群
    
    func onReceivingNewArticleInformation(item: Article) {
        DispatchQueue.main.async {
            self.allItems.append(item)
            self.allItems.sort { (one, two) -> Bool in
                return one.likeCount > two.likeCount
            }
            //カウンターを更新します
            self.totalLGTM += item.likeCount
            self.totalReads += item.readCount
            //Contribution counter
            if let dateObject = item.articlePublicationDate.getDateFromJSON() {
                let weekNumber = dateObject.getWeekNumber()
                let dayNumber = dateObject.getDayNumberInWeek()
                self.contributionBlock[weekNumber][dayNumber] += 1
            }
            //TableView
            self.updateCounter()
            self.tableView.reloadData()
        }
    }
    
    func onTaskFailed(reason: String) {
        //エラーメッセージを表示します
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            reason.アラートを表示(on: self.navigationController)
        }
    }
    
    // MARK: UITableView data provider
    
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
    
    /*
     テーブルビューのセルをクリックすると記事が表示されます
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = allItems[indexPath.row]
        guard let url = URL(string: item.articleURL) else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
    }
    
}

extension Date {
    
    //週番号を取得します
    func getWeekNumber() -> Int {
        return self.取得(.day) / 7
    }
    
    //曜日番号を取得します
    func getDayNumberInWeek() -> Int {
        return self.取得(.day) % 7
    }
    
}

extension String {
    
    //JSON String -> Date?
    func getDateFromJSON() -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: self) {
            return date
        }
        return nil
    }
    
}

//https://stackoverflow.com/a/39891965
// [[1, 2], [3, 4]] -> [[1, 3], [2, 4]]
extension Collection where Self.Iterator.Element: RandomAccessCollection {
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}
