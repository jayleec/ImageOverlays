//
//  ImageOverlays.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/20.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit

class ImageOverlays {
    
    static let shared = ImageOverlays()
    private let overlayImageName = "meadow.png"
    
    func exportImage(imageView: UIImageView, completion: @escaping (UIImage?) -> Void ) {
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        completion(image)
    }
    
    func addImageLayer(to layer: CALayer, layerSize: CGSize) -> CALayer {
        let image = UIImage(named: overlayImageName)!
        let imageLayer = CALayer()
        let aspect: CGFloat = image.size.width / image.size.height
        let width = layerSize.width
        let height = width / aspect
        imageLayer.frame = CGRect(x: 0, y: (layerSize.height - height) / 2, width: width, height: height)
        imageLayer.contents = image.cgImage
        layer.addSublayer(imageLayer)
        return imageLayer
    }
}
