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
    private lazy var targetSize: CGSize = {
        let scale = UIScreen.main.scale
        return CGSize(width: imageView.bounds.width * scale,
                      height: imageView.bounds.height * scale)
    }()
    private var isPlayingHint = false
    private var videoAssetUrl: URL?
    private var currentImage: UIImage?
    private var isPreviewOn = false
    private var overlayLayer: CALayer?

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
    
    @IBAction func showPreviewButtonTapped(_ sender: Any) {
        showOverlayPreview()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        playVideo()
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        if asset.mediaType == .video {
            if videoAssetUrl == nil {
                self.convertPHAsset2AVAsset(asset: asset, options: nil) { avAsset in
                    guard let avAsset = avAsset else { return }
                    VideoOverlays.shared.exportCombinedVideo(from: avAsset.url) { exportUrl in
                        guard let exportUrl = exportUrl else {
                            print("no export url")
                            return
                        }
                        self.saveVideo(videoUrl: exportUrl)
                    }
                }
            } else {
                VideoOverlays.shared.exportCombinedVideo(from: videoAssetUrl!) { exportUrl in
                    guard let exportUrl = exportUrl else {
                        print("no export url")
                        return
                    }
                    self.saveVideo(videoUrl: exportUrl)
                }
            }
        } else if asset.mediaSubtypes.contains(.photoLive) {
            
            
            
        } else {
            if !isPreviewOn {
                showOverlayPreview()
            }
            ImageOverlays.shared.exportImage(imageView: imageView) { combined in
                guard let combined = combined else { return }
                self.saveImage(image: combined)
            }
        }
    }
    
    private func saveLivePhoto(imageData: Data, livePhotoMovieURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            // Add the captured photo's file data as the main resource for the Photos asset.
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: imageData, options: nil)
            
            // Add the movie file URL as the Live Photo's paired video resource.
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            creationRequest.addResource(with: .pairedVideo, fileURL: livePhotoMovieURL, options: options)
        }) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.navigationController?.popViewController(animated: true)
                }
            } else {
                print("live photo save fail \(error.debugDescription)")
//                showAlert()
            }
        }
    }
    
    private func saveImage(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) {[weak self] success, error in
            if success {
                print("Saved")
            } else {
                print("saving error \(error.debugDescription)")
            }
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func saveVideo(videoUrl: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
        }) { [weak self] success, error in
            if success {
                print("Saved")
            } else {
                print("saving error \(error.debugDescription)")
            }
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc
    private func hideToolBar() {
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
                self.progressView.progress = Float(progress)
            }
        }
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            self.progressView.isHidden = true
            
            guard let image = image else { return }
            self.livePhotoView.isHidden = true
            self.imageView.isHidden = false
            self.imageView.image = image
            self.currentImage = image
        })
    }
    
    @objc
    private func showOverlayPreview() {
        if isPreviewOn {
           isPreviewOn = false
            guard let overlayLayer = overlayLayer else { return }
            overlayLayer.removeFromSuperlayer()
        } else {
            isPreviewOn = true
            if asset.mediaType == .video {
                overlayLayer = ImageOverlays.shared.addImageLayer(to: self.view.layer, layerSize: self.view.layer.frame.size)
            } else if asset.mediaSubtypes.contains(.photoLive) {
                
            } else {
                overlayLayer = ImageOverlays.shared.addImageLayer(to: self.imageView.layer, layerSize: self.imageView.frame.size)
            }
        }
    }
    
    private func showLivePhoto() {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        // TODO: -> func
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
            // TODO: get all resources
            
            if !self.isPlayingHint {
                self.isPlayingHint = true
                self.livePhotoView.startPlayback(with: .hint)
            }
        })
        
    }
    
    private func playVideo() {
        // TODO: replay
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
            
            convertPHAsset2AVAsset(asset: asset, options: options) { avAsset in
                guard let avAsset = avAsset else { return }
                self.videoAssetUrl = avAsset.url
                
                DispatchQueue.main.sync {
                    let player = AVPlayer(url: avAsset.url)
                    let layer = AVPlayerLayer(player: player)
                    layer.frame = self.view.layer.bounds
                    layer.videoGravity = AVLayerVideoGravity.resizeAspect
                    self.view.layer.addSublayer(layer)
                    player.play()
                    
                    self.playerLayer = layer
                }
            }
        }
    }
    
    private func convertPHAsset2AVAsset(asset: PHAsset, options: PHVideoRequestOptions?, completion: @escaping (AVURLAsset?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { asset, _, _ in
            completion(asset as? AVURLAsset)
        })
    }
}
