//
//  ViewController.swift
//  QiitaContributionReport
//
//  Created by Shunzhe Ma on 5/25/20.
//  Copyright © 2020 Shunzhe Ma. All rights reserved.
//

import UIKit
import AuthenticationServices
import SwiftExtensions
import KeychainSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var tokenTextField: UITextField!
    
    @IBOutlet weak var continueButtonView: UIView!
    
    let keychain = KeychainSwift()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        continueButtonView.setUpOutlinedRoundButton()
        //Restore previous token value, if there is any stored
        tokenTextField.text = keychain.get("qiitaToken") ?? ""
    }
    
    @IBAction func actionGoToQiitaAPIpage(){
        guard let authURL = URL(string: "https://qiita.com/settings/tokens/new") else { return }
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "")
        { callbackURL, error in
            // Handle the callback.
        }
        session.presentationContextProvider = self
        session.start()
    }
    
    @IBAction func actionContinue(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "userTableView") as! userTableView
        vc.userToken = tokenTextField.text ?? ""
        //Save the token to user's Keychain
        keychain.set(tokenTextField.text ?? "", forKey: "qiitaToken")
        //
        navigationController?.show(vc, sender: nil)
    }


}

extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
