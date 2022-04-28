//
//  AddLinkVC.swift
//  BookMarksApp
//
//  Created by sunil on 25/03/22.
//

import UIKit
import SwiftSoup


class AddLinkVC: UIViewController {
    
    @IBOutlet weak var cancelBtn: UIBarButtonItem!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var selectTag: UILabel!
    
    @IBAction func parseInfoFromUrl() {
        
        if let url = URL.init(string: urlTextField.text ?? "") {
            self.performSegue(withIdentifier: "showFinalAccept", sender: urlTextField.text)
        }
    }
    
    var tag: Tag?
    
    var link: Link?

    override func viewDidLoad() {
        super.viewDidLoad()
        selectTag.text = "Select tag"
        let clipboardStr = UIPasteboard.general.string
        if ((clipboardStr?.localizedCaseInsensitiveContains("https://")) == true) {
            urlTextField.text = clipboardStr
            UIPasteboard.general.string = ""
        }
        self.setUpBarButtonItems()
    }
    
    func setUpBarButtonItems() {
        // Right bar Button Item
        let rightBarBtn = UIBarButtonItem(title: "Save", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.saveAction))
        let font =  UIFont(name: "MarkerFelt-Thin", size: 16)
        let attributes: [NSAttributedString.Key : Any] = [ .font: font ?? .systemFont(ofSize: 16)]
        rightBarBtn.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.rightBarButtonItem = rightBarBtn

        // Left bar Button Item
        let leftBarBtn = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.cancelAction))
        leftBarBtn.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.leftBarButtonItem = leftBarBtn
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier, segueIdentifier == "toBookmarkList" else {
            return
        }
        
        guard let listViewController = segue.destination as? BookmarksListVC else {
            return
        }
        
        guard let tag = sender as? Tag else {
            return
        }
        
        listViewController.tag = tag
    }
    
    @objc func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func saveAction() {
        if let url = URL.init(string: urlTextField.text ?? "") {
            DispatchQueue.main.async {
                do {
                    let html = try String(contentsOf: url)
                    //print(html)
                    let doc: Document = try SwiftSoup.parse(html)
                    let title = try doc.title()
                    let description = try doc.body()?.text()
                    let links = try doc.select("link")
                    let iconlinks = try links.filter ({ link in
                        let attribute1 = try link.attr("rel")
                        return (attribute1 == "shortcut icon") || (attribute1 == "icon")
                    })
                    
                    var imageLink: String?
                    if let icon = iconlinks.first {
                        let imageUrl = try icon.attr("href")
                        if let url = URL.init(string: imageUrl) {
                            imageLink = imageUrl
                        }
                    }
                
                    let bookmark = Bookmark.init(title: title, description: description ?? "", tag: "", website: url.absoluteString,iconUrl: imageLink ?? "")
                    
                    if let tag = self.tag {
                        NotionHelper.sharedInstance.addNotionLink(url: url.absoluteString, tag: tag)
                        self.performSegue(withIdentifier: "toBookmarkList", sender: tag)
                    } else {
                        self.showMessage("Please choose a tag")
                    }
                    
                    
                } catch {
                    self.showMessage("Couldnt get the expected meta data")
                }
            }
        } else {
            self.showMessage("Please enter a valid url")
        }
    }
    
    func showMessage(_ message: String) {
        let alertController = UIAlertController.init(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        
        
        let cancelAction = UIAlertAction.init(title: "Okay", style: UIAlertAction.Style.default) { action in
            alertController.dismiss(animated: true) {
                
            }
        }
        
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)

    }
    
    @IBAction func selectTagAction() {
        self.performSegue(withIdentifier: "showSelectTag", sender: nil)
    }
    
    
    
    @IBAction func unwind(_ segue:UIStoryboardSegue) {
        print("Unwind")
        self.selectTag.text = tag?.name
    }
}
