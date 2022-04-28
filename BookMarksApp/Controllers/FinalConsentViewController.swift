//
//  FinalConsentViewController.swift
//  BookMarksApp
//
//  Created by sunil on 25/03/22.
//

import UIKit
import CoreData

class FinalConsentViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tagsFRC: NSFetchedResultsController<NSFetchRequestResult>?
    let reuseId = "TagSelectionCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib.init(nibName: reuseId, bundle: nil), forCellReuseIdentifier: reuseId)
        self.tableView.estimatedRowHeight = 50
        self.tableView.dataSource = self
        self.tableView.delegate = self
        initializeFetchedResultsController()
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
    
    func initializeFetchedResultsController() {
        if let fetchedResultsController = DataBase.sharedInstance.tagsFetchResultsController() {
            self.tagsFRC = fetchedResultsController
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.removebackBtn()
        self.addCustomBackBtn()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier, segueId == "backToNewBookmark", let addLinkVC = segue.destination as? AddLinkVC, let tag = sender as? Tag {
            addLinkVC.tag = tag
        }
    }
}

extension FinalConsentViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tagsFRC?.fetchedObjects?.count ?? 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tagCell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! TagSelectionCell
        
        guard let tagsFRC = self.tagsFRC, let tag = tagsFRC.object(at: indexPath) as? Tag else {
            return TagSelectionCell()
        }
        
        tagCell.nameLabel.text = tag.name
        tagCell.nameLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 14)
        return tagCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension FinalConsentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tagsFRC = self.tagsFRC, let tag = tagsFRC.object(at: indexPath) as? Tag else {
            return
        }
        self.performSegue(withIdentifier: "backToNewBookmark", sender: tag)
    }
}


