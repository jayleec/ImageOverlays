//
//  ImageOverlays.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/20.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import CoreImage.CIFilterBuiltins

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
    
    
    func exportImage(image: UIImage, completion: @escaping (UIImage?) -> Void) {
        if #available(iOS 13.0, *) {
            let blendFilter = CIFilter.sourceOverCompositing()
            let ciImage = CIImage(image: image)
            blendFilter.backgroundImage = ciImage
            
            let overlay = UIImage(named: overlayImageName)!
            var inputImage = CIImage(image: overlay)
            let scale = image.size.width / overlay.size.width
            let overlayHeight = scale * overlay.size.height
            
            var transform = CGAffineTransform(translationX: 0, y: abs(image.size.height - overlayHeight) / 2)
            transform = transform.scaledBy(x: scale, y: scale)
            
            inputImage = inputImage?.transformed(by: transform)
            blendFilter.inputImage = inputImage

            guard let output = blendFilter.outputImage else {
                completion(nil)
                return
            }
            let context = CIContext()
            guard let cgImage = context.createCGImage(output, from: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)) else {
                completion(nil)
                return
            }
            completion(UIImage(cgImage: cgImage))
        } else {
            let blendFilter = CIFilter(name:"CISourceOverCompositing")
            let ciImage = CIImage(image: image)
            blendFilter?.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
            
            let overlay = UIImage(named: overlayImageName)!
            var inputImage = CIImage(image: overlay)
            let scale = image.size.width / overlay.size.width
            let overlayHeight = scale * overlay.size.height
            
            var transform = CGAffineTransform(translationX: 0, y: abs(image.size.height - overlayHeight) / 2)
            transform = transform.scaledBy(x: scale, y: scale)
            
            inputImage = inputImage?.transformed(by: transform)
            blendFilter?.setValue(inputImage, forKey: kCIInputImageKey)

            guard let output = blendFilter?.outputImage else {
                completion(nil)
                return
            }
            let context = CIContext()
            guard let cgImage = context.createCGImage(output, from: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)) else {
                completion(nil)
                return
            }
            completion(UIImage(cgImage: cgImage))
        }
    }
}
