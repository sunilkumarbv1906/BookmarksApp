//
//  BookmarksFolderListVC.swift
//  BookMarksApp
//
//  Created by sunil on 20/03/22.
//

import UIKit
import GoogleSignIn
import CoreData
import NotionSwift

class BookmarksFolderListVC: UIViewController {
    
    private let refreshControl = UIRefreshControl()
    
    var blockOperations: [BlockOperation] = []
    
    var tagsFRC: NSFetchedResultsController<NSFetchRequestResult>?
    
    var kWIDTH_CELL: CGFloat {
        let insettedWidth = Int((self.view.frame.size.width - 24))
        if (insettedWidth%2) == 0 {
            return CGFloat(insettedWidth / 2)
        }
        else {
           return CGFloat((insettedWidth - 1) / 2)
        }
    }
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 8.0, bottom: 50.0, right: 8.0)
    
    func initializeFetchedResultsController() {
        if let fetchedResultsController = DataBase.sharedInstance.tagsFetchResultsController() {
            self.tagsFRC = fetchedResultsController
            self.tagsFRC?.delegate = self
            self.bookmarkCollectionView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier, segueIdentifier == "showBookmarksList" else {
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
    
    @IBOutlet weak var bookmarkCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavTitleLabel()
        self.setRightBarBtn()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.isFirstTimeLogin == true{
            self.pullToRefresh()
            appDelegate.isFirstTimeLogin = false
        }
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        bookmarkCollectionView.refreshControl = refreshControl
        
        
        registerCell()
        self.bookmarkCollectionView.dataSource = self
        self.bookmarkCollectionView.delegate = self
        
        initializeFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.removebackBtn()
    }
    
    func removebackBtn() {
        self.navigationItem.setHidesBackButton(true, animated: true);
        self.navigationItem.leftBarButtonItem = nil;
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func setNavTitleLabel() {
        if let navigationBar = self.navigationController?.navigationBar {
            let navTitleLblFrame = CGRect(x: 0, y: 0, width: navigationBar.frame.width, height: navigationBar.frame.height)
            let navTitleLbl = UILabel(frame: navTitleLblFrame)
            navTitleLbl.textAlignment = .center
            navTitleLbl.font = UIFont(name: "MarkerFelt-Thin", size: 18)
            navTitleLbl.textColor = UIColor.black
            navTitleLbl.text = "Bookmarks"
            navigationBar.addSubview(navTitleLbl)
        }
    }
    
    func setRightBarBtn() {
        let rightBarBtn = UIBarButtonItem(title: "Sign Out", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.signOut))
        let font =  UIFont(name: "MarkerFelt-Thin", size: 16)
        let attributes: [NSAttributedString.Key : Any] = [ .font: font ?? .systemFont(ofSize: 16)]
        rightBarBtn.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.rightBarButtonItem = rightBarBtn
    }
    
    @objc func pullToRefresh() {
        NotionHelper.sharedInstance.getNotionPages()
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
        }
        
    }
    @objc func signOut(){
        
        let action = yourActionSheet()
        self.present(action, animated: true, completion: nil)
    }
    
    
    func yourActionSheet() -> UIAlertController {
        let alert = UIAlertController(title: "BookMarks App",
                                      message: nil,
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Sign Out",
                                      style: .default) { _ in
            GIDSignIn.sharedInstance.signOut()
            let story = UIStoryboard(name: "Main", bundle:nil)
            let vc = story.instantiateViewController(withIdentifier: "signIn") as! SignInViewController
            let navigationController = UINavigationController.init(rootViewController: vc)
            UIApplication.shared.windows.first?.rootViewController = navigationController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
            DataBase.sharedInstance.deleteAll()
        })
            alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel) { _ in
            
        })

        return alert
    }
    
    
    let FOLDER_CELL = "FolderCell"
    
    func registerCell() {
        self.bookmarkCollectionView.register(UINib.init(nibName: FOLDER_CELL, bundle: nil), forCellWithReuseIdentifier: FOLDER_CELL)
    }
    
    @objc func performPlusButtonAction(){
        
    }
    
    
    func showAddTagAlertController() {
        let alertController = UIAlertController.init(title: "Tag creation", message: "", preferredStyle: UIAlertController.Style.alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter a tag name"
        }
        
        let createTagAction = UIAlertAction.init(title: "Save", style: UIAlertAction.Style.default) { action in
            if let saveTextField = alertController.textFields?[0], let tagName = saveTextField.text {
                DispatchQueue.main.async {
                    if !tagName.isEmpty {
                        DataBase.sharedInstance.insertTagWith(name: tagName)
                        self.initializeFetchedResultsController()
                        alertController.dismiss(animated: true) {[weak self] in
                            
                        }
                        self.bookmarkCollectionView.reloadData()
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: UIAlertAction.Style.cancel) { action in
            DispatchQueue.main.async {
                alertController.dismiss(animated: true) {[weak self] in
                    self?.bookmarkCollectionView.reloadData()
                }
            }
        }
        
        alertController.addAction(createTagAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func openAddLink() {
        self.performSegue(withIdentifier: "showAddLinkFromFolder", sender: nil)
    }
}

extension BookmarksFolderListVC : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let folderCell = collectionView.dequeueReusableCell(withReuseIdentifier: FOLDER_CELL, for: indexPath) as! FolderCell
        
        guard let tagsFRC = self.tagsFRC, let fetchedObjects = tagsFRC.fetchedObjects else {
            return FolderCell()
        }
        
        folderCell.tag = indexPath.item
        let longTapGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(addTapGestureForCell(_:)))
        folderCell.addGestureRecognizer(longTapGesture)
        if indexPath.row < fetchedObjects.count {
            if let tag = tagsFRC.object(at: indexPath) as? Tag {
                folderCell.nameLabel.text = tag.name
                folderCell.nameLabel.font = UIFont(name: "MarkerFelt-Thin", size: 14)
                folderCell.iconImageView.image = UIImage(named: "")
                folderCell.iconImageView.image = UIImage.init(named: "bookmarks")
            }
        } else {
            folderCell.nameLabel.text = ""
            folderCell.iconImageView.image = UIImage.init(systemName: "plus")
        }
        return folderCell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (tagsFRC?.fetchedObjects?.count ?? 0) + 1
    }
    
    @objc func addTapGestureForCell(_ sender: UILongPressGestureRecognizer) {
        if let folderCell = sender.view as? FolderCell {
            let alertController = UIAlertController.init(title: "Delete", message: "Are you sure you want to delete the tag?", preferredStyle: UIAlertController.Style.alert)
            
            let deleteAction = UIAlertAction.init(title: "Delete", style: UIAlertAction.Style.destructive) { action in
                guard let fetchedObjects = self.tagsFRC?.fetchedObjects as? [Tag] else {
                    alertController.dismiss(animated: true) {
                        
                    }
                    return
                }
                let tag = fetchedObjects[folderCell.tag]
                
                DataBase.sharedInstance.deleteTag(tag)
                alertController.dismiss(animated: true) {
                    
                }
                
                self.initializeFetchedResultsController()
            }
            
            let cancelAction = UIAlertAction.init(title: "Cancel", style: UIAlertAction.Style.default) { action in
                alertController.dismiss(animated: true) {
                    
                }
            }
            
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
}

extension BookmarksFolderListVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: kWIDTH_CELL, height: kWIDTH_CELL)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tagsFRC = self.tagsFRC, let fetchedObjects = tagsFRC.fetchedObjects else {
            return
        }
        
        if indexPath.row < fetchedObjects.count {
            self.performSegue(withIdentifier: "showBookmarksList", sender: fetchedObjects[indexPath.row])
        } else {
            showAddTagAlertController()
        }
    }
}

extension BookmarksFolderListVC: UICollectionViewDelegateFlowLayout {
    
}

extension BookmarksFolderListVC: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        initializeFetchedResultsController()
        self.bookmarkCollectionView.reloadData()
        
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

    }
}
