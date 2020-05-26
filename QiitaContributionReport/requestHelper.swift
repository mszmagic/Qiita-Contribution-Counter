//
//  requestHelper.swift
//  QiitaContributionReport
//
//  Created by Shunzhe Ma on 5/25/20.
//  Copyright © 2020 Shunzhe Ma. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Article {
    var articleTitle: String
    var articlePublicationDate: String
    var likeCount: Int
    var readCount: Int
    var articleURL: String
}

protocol articleRequestDelegate: AnyObject {
    func onReceivingNewArticleInformation(item: Article)
    func onTaskFailed(reason: String)
}

class requestHelper {
    
    var userID: String!
    
    weak var delegate: articleRequestDelegate?
    
    /*
     すべての記事IDを取得し、各記事IDに対して `fetchIndividualArticle` を呼び出します
     */
    func getArticles() {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard let URL = URL(string: "https://qiita.com/api/v2/authenticated_user/items") else {
            delegate?.onTaskFailed(reason: "URL convertion failed!")
            return
        }
        
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        // Headers

        request.addValue("Bearer \(userID ?? "")", forHTTPHeaderField: "Authorization")

        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if error == nil && statusCode >= 200 && statusCode < 400 {
                    //success
                    let allItems = try! JSON(data: data!).array
                    for item in allItems ?? [] {
                        if let id = (item.dictionary?["id"])?.stringValue {
                            self.fetchIndividualArticle(id: id)
                        }
                    }
                    return
                }
            }
            // Failure
            self.delegate?.onTaskFailed(reason: error?.localizedDescription ?? "Unknown error. Please check your token and try again.")
        })
        
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    /*
     `id` が与えられた単一の記事に関する情報を取得します。
     結果がサーバーから取り出されると、デリゲート関数 onReceivingNewArticleInformation を呼び出します
     */
    func fetchIndividualArticle(id: String) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        guard let URL = URL(string: "https://qiita.com/api/v2/items/\(id)") else {
            delegate?.onTaskFailed(reason: "URL convertion failed!")
            return
        }
        
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        // Headers

        request.addValue("Bearer \(userID ?? "")", forHTTPHeaderField: "Authorization")

        /* Start a new Task */
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                // Success
                if let fetchedData = data,
                    let parsedData = try? JSON(data: fetchedData).dictionary {
                    if let articleTitle = parsedData["title"]?.stringValue,
                        let articlePublicationDate = parsedData["created_at"]?.stringValue,
                        let likeCount = parsedData["likes_count"]?.int,
                        let readCount = parsedData["page_views_count"]?.int,
                        let url = parsedData["url"]?.stringValue {
                        //Generate a story object
                        let story = Article(articleTitle: articleTitle, articlePublicationDate: articlePublicationDate, likeCount: likeCount, readCount: readCount, articleURL: url)
                        self.delegate?.onReceivingNewArticleInformation(item: story)
                    }
                }
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
}

/*
 基本的なユーザー情報を取得します
 - completionHandler(profileImageURLPath, UserName, Description, error)
 -- profileImageURLPath : プロフィール画像のURLパス
 -- UserName : ユーザー名
 -- Description : 説明
 -- error : エラー
 */
func getUserDetails(userID: String, completionHandler: @escaping (String?, String?, String?, String?) -> Void) {
    let sessionConfig = URLSessionConfiguration.default
    let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

    guard let URL = URL(string: "https://qiita.com/api/v2/authenticated_user") else {
        completionHandler(nil, nil, nil, "URL Convertion failed")
        return
    }
    
    var request = URLRequest(url: URL)
    request.httpMethod = "GET"

    // Headers
    request.addValue("Bearer \(userID)", forHTTPHeaderField: "Authorization")

    //Define the web session task
    let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
        if (error == nil) {
            if let fetchedData = data {
                if let parsedData = try? JSON(data: fetchedData).dictionary {
                    //ユーザー名
                    let name = parsedData["name"]?.stringValue
                    //説明 description
                    let description = parsedData["description"]?.stringValue
                    //プロフィール画像のURLパス
                    let profileImage = parsedData["profile_image_url"]?.stringValue
                    //
                    completionHandler(profileImage, name, description, nil)
                }
            }
        }
        else {
            // エラー
            print("URL Session Task Failed: %@", error!.localizedDescription);
            completionHandler(nil, nil, nil, error?.localizedDescription)
        }
    })
    task.resume()
    session.finishTasksAndInvalidate()
}
