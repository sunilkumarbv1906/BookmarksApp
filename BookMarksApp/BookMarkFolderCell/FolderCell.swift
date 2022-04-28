//
//  FolderCell.swift
//  BookMarksApp
//
//  Created by sunil on 20/03/22.
//

import UIKit

class FolderCell: UICollectionViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.borderWidth = 0.5
        self.layer.masksToBounds = true
        let color = UIColor.init(red: 144.0/255.0, green: 144.0/255.0, blue: 144.0/255.0, alpha: 0.21)
        self.layer.applySketchShadow(color: color, alpha: 1, x: 0.0, y: 3.0, blur: 14.9, spread: 1.1)
    }
    
    override func prepareForReuse() {
        self.iconImageView.image = nil
        self.nameLabel.text = ""
    }

}
