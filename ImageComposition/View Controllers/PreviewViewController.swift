//
//  PreviewViewController.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/19.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PreviewViewController: UIViewController {
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoView: PHLivePhotoView!
    
    var asset: PHAsset!
    private var playerLayer: AVPlayerLayer!
    lazy var targetSize: CGSize = {
        let scale = UIScreen.main.scale
        return CGSize(width: imageView.bounds.width * scale,
                      height: imageView.bounds.height * scale)
    }()
    private var isPlayingHint = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideToolBar)))
        if asset.mediaType != .video {
            toolBar.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        view.layoutIfNeeded()
        updateImage()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        playVideo()
    }
    
    @objc
    func hideToolBar() {
        if asset.mediaType == .video {
            toolBar.isHidden = !toolBar.isHidden
        }
        navigationController?.navigationBar.isHidden = !(navigationController?.navigationBar.isHidden)!
    }
    
    private func updateImage() {
        if asset.mediaSubtypes.contains(.photoLive) {
            showLivePhoto()
        } else {
            showImage()
        }
    }
    
    private func showImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            DispatchQueue.main.sync {
                print("progress\(progress)")
                self.progressView.progress = Float(progress)
            }
        }
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            self.progressView.isHidden = true
            
            guard let image = image else { return }
            self.livePhotoView.isHidden = true
            self.imageView.isHidden = false
            self.imageView.image = image
        })
    }
    
    private func showLivePhoto() {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            DispatchQueue.main.sync {
                print("progress\(progress)")
                self.progressView.progress = Float(progress)
            }
        }
        
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { livePhoto, info in
            self.progressView.isHidden = true
            
            guard let livePhoto = livePhoto else { return }
            self.imageView.isHidden = true
            self.livePhotoView.isHidden = false
            self.livePhotoView.livePhoto = livePhoto
            
            if !self.isPlayingHint {
                self.isPlayingHint = true
                self.livePhotoView.startPlayback(with: .hint)
            }
        })
        
    }
    
    private func playVideo() {
        guard asset.mediaType == .video else { return }

        if playerLayer != nil {
            playerLayer.player!.play()
        } else {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .automatic
            options.progressHandler = { progress, _, _, _ in
                DispatchQueue.main.sync {
                    print("progress\(progress)")
                    self.progressView.progress = Float(progress)
                }
            }
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { asset, audioMix, info in
                let asset = asset as! AVURLAsset
                print(asset.url)
                DispatchQueue.main.sync {
                    let player = AVPlayer(url: asset.url)
                    let layer = AVPlayerLayer(player: player)
                    layer.frame = self.view.layer.bounds
                    layer.videoGravity = AVLayerVideoGravity.resizeAspect
                    self.view.layer.addSublayer(layer)
                    player.play()
                    
                    self.playerLayer = layer
                }
            })
        }
    }

}
