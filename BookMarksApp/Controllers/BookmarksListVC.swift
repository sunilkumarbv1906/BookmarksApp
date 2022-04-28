//
//  BookmarksListVC.swift
//  BookMarksApp
//
//  Created by sunil on 20/03/22.
//

import UIKit
import SDWebImage
import SwiftSoup

struct Bookmark {
    var title: String = String()
    var description: String = String()
    var tag: String = String()
    var website: String = String()
    var iconUrl: String = String()
    var uuid: String = String()
}

class BookmarksListVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var bookmarks = [Bookmark]()
    
    var tag: Tag? {
        didSet {
            if let linksSet = tag?.relationship {
                links = linksSet.allObjects as? [Link]
                
            }
        }
    }
    
    var links: [Link]?

    override func viewDidLoad() {
        super.viewDidLoad()

        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.font: UIFont(name: "MarkerFelt-Thin", size: 16)!]
        UINavigationBar.appearance().titleTextAttributes = attrs
        self.tableView.register(UINib.init(nibName: "BookmarkCell", bundle: nil), forCellReuseIdentifier: "BookmarkCell")
        self.navigationItem.backBarButtonItem?.setTitleTextAttributes(attrs, for: .normal)

        self.tableView.estimatedRowHeight = 300
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        if let linksSet = tag?.relationship {
            links = linksSet.allObjects as? [Link]
        }
    }
    
    func removebackBtn() {
        self.navigationItem.setHidesBackButton(true, animated: true);
        self.navigationItem.leftBarButtonItem = nil;
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func addCustomBackBtn() {
        let leftBarBtn = UIBarButtonItem(title: "back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.backClicked))
        let font =  UIFont(name: "MarkerFelt-Thin", size: 16)
        let attributes: [NSAttributedString.Key : Any] = [ .font: font ?? .systemFont(ofSize: 16)]
        leftBarBtn.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.leftBarButtonItem = leftBarBtn
    }
    
    @objc func backClicked() {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.removebackBtn()
        self.addCustomBackBtn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let tag = self.tag {
            self.tag = DataBase.sharedInstance.fetchTag(tag)
        }
        
        if let linksSet = tag?.relationship {
            links = linksSet.allObjects as? [Link]
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    func createLink(bookmark: Bookmark) {
        if let tag = self.tag {
            self.tag = DataBase.sharedInstance.addLinkForTag(bookmark: bookmark, tag: tag)
        }
        
        if let linksSet = tag?.relationship {
            links = linksSet.allObjects as? [Link]
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    @IBAction func openAddLink() {
        self.performSegue(withIdentifier: "showAddLink", sender: nil)
    }
    
    @IBAction func unwindFromAddLink(_ segue: UIStoryboardSegue) {
        self.tableView.reloadData()
    }
}

extension BookmarksListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (links?.count ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bookmarkCell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell") as! BookmarkCell
        if let link = links?[indexPath.row], let tag = self.tag {
            bookmarkCell.titleLabel.text = link.title
            bookmarkCell.titleLabel.font = UIFont(name: "Futura-Bold", size: 14)
            bookmarkCell.descriptionLabel.text = link.urlDescription
            bookmarkCell.descriptionLabel.font = UIFont(name: "GillSans-Light", size: 14)
            bookmarkCell.shortLinkLabel.text = link.url
            bookmarkCell.shortLinkLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
            bookmarkCell.tagLabel.text = tag.name
            bookmarkCell.tagLabel.font = UIFont(name: "MarkerFelt-Thin", size: 14)
            if let url = URL.init(string: link.iconUrl ?? "") {
                bookmarkCell.iconImageView.sd_setImage(with: url,
                                                       placeholderImage: UIImage.init(systemName: "doc.richtext.th"),
                                                       options: [SDWebImageOptions.retryFailed, .handleCookies, .scaleDownLargeImages, .transformAnimatedImage],
                                                       completed: nil)
            }
            
        }
        return bookmarkCell
    }
}

extension BookmarksListVC: UITableViewDelegate {
    
}
