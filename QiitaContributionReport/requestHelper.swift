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
}

protocol articleRequestDelegate: AnyObject {
    func onReceivingNewArticleInformation(item: Article)
    func onTaskFailed(reason: String)
}

class requestHelper {
    
    var userID: String!
    
    weak var delegate: articleRequestDelegate?
    
    /*
     Get the basic user information
     - completionHandler(profileImageURLPath, UserName, Description, error)
     */
    func getUserDetails(completionHandler: @escaping (String?, String?, String?, String?) -> Void) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        guard let URL = URL(string: "https://qiita.com/api/v2/authenticated_user") else {
            completionHandler(nil, nil, nil, "URL Convertion failed")
            return
        }
        var request = URLRequest(url: URL)
        request.httpMethod = "GET"

        // Headers

        request.addValue("Bearer \(userID ?? "")", forHTTPHeaderField: "Authorization")

        //Define the web session task
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if (error == nil) {
                if let fetchedData = data {
                    if let parsedData = try? JSON(data: fetchedData).dictionary {
                        //Get the name
                        let name = parsedData["name"]?.stringValue
                        //Get the description
                        let description = parsedData["description"]?.stringValue
                        //Get the profile image
                        let profileImage = parsedData["profile_image_url"]?.stringValue
                        //Provide the result
                        completionHandler(profileImage, name, description, nil)
                    }
                }
            }
            else {
                // Failure
                print("URL Session Task Failed: %@", error!.localizedDescription);
                completionHandler(nil, nil, nil, error?.localizedDescription)
            }
        })
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    func getArticles() {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        guard let URL = URL(string: "https://qiita.com/api/v2/authenticated_user/items") else {return}
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
    
    func fetchIndividualArticle(id: String) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        guard let URL = URL(string: "https://qiita.com/api/v2/items/\(id)") else {return}
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
                        let readCount = parsedData["page_views_count"]?.int {
                        //Generate a story object
                        let story = Article(articleTitle: articleTitle, articlePublicationDate: articlePublicationDate, likeCount: likeCount, readCount: readCount)
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




