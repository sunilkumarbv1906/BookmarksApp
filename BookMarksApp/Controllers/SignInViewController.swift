//
//  SignInViewController.swift
//  BookMarksApp
//
//  Created by sunil on 19/03/22.
//

import UIKit
import Firebase
import GoogleSignIn
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var signInBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        signInBtn.layer.cornerRadius = 35
        signInBtn.layer.masksToBounds = true
        signInBtn.clipsToBounds = true
    }
    
    @IBAction func signIn(_ sender: Any) {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            
            if let _ = error {
                return
            }
            
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
            else {
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    let authError = error as NSError
                    if authError.code == AuthErrorCode.secondFactorRequired.rawValue {
                        // The user is a multi-factor user. Second factor challenge is required.
                        let resolver = authError
                            .userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
                        var displayNameString = ""
                        for tmpFactorInfo in resolver.hints {
                            displayNameString += tmpFactorInfo.displayName ?? ""
                            displayNameString += " "
                        }
                        self.showTextInputPrompt(
                            withMessage: "Select factor to sign in\n\(displayNameString)",
                            completionBlock: { userPressedOK, displayName in
                                var selectedHint: PhoneMultiFactorInfo?
                                for tmpFactorInfo in resolver.hints {
                                    if displayName == tmpFactorInfo.displayName {
                                        selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                                    }
                                }
                                PhoneAuthProvider.provider()
                                    .verifyPhoneNumber(with: selectedHint!, uiDelegate: nil,
                                                       multiFactorSession: resolver
                                                        .session) { verificationID, error in
                                        if error != nil {
                                            print(
                                                "Multi factor start sign in failed. Error: \(error.debugDescription)"
                                            )
                                        } else {
                                            self.showTextInputPrompt(
                                                withMessage: "Verification code for \(selectedHint?.displayName ?? "")",
                                                completionBlock: { userPressedOK, verificationCode in
                                                    let credential: PhoneAuthCredential? = PhoneAuthProvider.provider()
                                                        .credential(withVerificationID: verificationID!,
                                                                    verificationCode: verificationCode!)
                                                    let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator
                                                        .assertion(with: credential!)
                                                    resolver.resolveSignIn(with: assertion!) { authResult, error in
                                                        if error != nil {
                                                            print(
                                                                "Multi factor finanlize sign in failed. Error: \(error.debugDescription)"
                                                            )
                                                        } else {
                                                            self.navigationController?.popViewController(animated: true)
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                    }
                            }
                        )
                    } else {
                        return
                    }
                    return
                }
                // User is signed in                
                
                DispatchQueue.main.async {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.isFirstTimeLogin = true
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: "tilesView") as! BookmarksFolderListVC
                    self.navigationController?.pushViewController(controller, animated: true)
                }
                
                
            }
        }
        
    }
    
    
    func showTextInputPrompt(withMessage message: String,
                             completionBlock: @escaping ((Bool, String?) -> Void)) {
        let prompt = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionBlock(false, nil)
        }
        weak var weakPrompt = prompt
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            guard let text = weakPrompt?.textFields?.first?.text else { return }
            completionBlock(true, text)
        }
        prompt.addTextField(configurationHandler: nil)
        prompt.addAction(cancelAction)
        prompt.addAction(okAction)
        present(prompt, animated: true, completion: nil)
    }
    

    

}

