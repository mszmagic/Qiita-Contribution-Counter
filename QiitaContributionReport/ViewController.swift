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
        // UIのセットアップ
        continueButtonView.setUpOutlinedRoundButton()
        // キーチェーンに前回の「トークン」値が保存されている場合にはそれを再度取得します。
        tokenTextField.text = keychain.get("qiitaToken") ?? ""
    }
    
    @IBAction func actionGoToQiitaAPIpage(){
        /*
         ユーザーの既存のブラウザーセッションのクッキーをここで利用できるよう、ASWebAuthenticationSession を用います。そうすればユーザーは再度ログインしなくてもよくなります。
         */
        guard let authURL = URL(string: "https://qiita.com/settings/tokens/new") else { return }
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "")
        { callbackURL, error in
            // Handle the callback.
        }
        session.presentationContextProvider = self
        session.start()
    }
    
    @IBAction func actionContinue(){
        //ユーザーから提供されるトークンがあることを確認します
        guard let enteredToken = tokenTextField.text else { return }
        //Main Storyboard から userTableView を取得します
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "userTableView") as! userTableView
        vc.userToken = enteredToken
        //トークンをユーザーのキーチェーンに保存します
        keychain.set(tokenTextField.text ?? "", forKey: "qiitaToken")
        //UINavigationController を用いて表示します
        navigationController?.show(vc, sender: nil)
    }


}

/*
 ASWebAuthenticationSession がどこにビューを表示すべきか判断するためです
 */
extension ViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}
