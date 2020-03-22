//
//  PhotoCell.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/18.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    static let reuseId = "photoCell"
    
    var assetId: String!
    let imageView = UIImageView()
    let liveImageBadge = UIImageView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.addSubview(imageView)
        _ = imageView.anchor(contentView.topAnchor, left: contentView.leftAnchor, bottom: contentView.bottomAnchor, right: contentView.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        imageView.addSubview(liveImageBadge)
        _ = liveImageBadge.anchor(imageView.topAnchor, left: imageView.leftAnchor, bottom: nil, right: nil, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 30, heightConstant: 30)
        
        imageView.contentMode = .scaleAspectFill
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        liveImageBadge.image = nil
    }
    
}
