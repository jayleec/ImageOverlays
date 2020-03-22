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
    @IBOutlet weak var playButton: UIBarButtonItem!
    
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
    private var progressValue: Float = 0
    private var isPlaying = false
    private var videoEnded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideToolBar)))
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil, using: {[weak self] _ in
            self?.isPlaying = false
            self?.videoEnded = true
            if #available(iOS 13.0, *) {
                self?.playButton.image = UIImage(systemName: "play.fill")
            }
        })
        if asset.mediaType != .video {
            toolBar.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        updateImage()
    }
    
    private func updateImage() {
        if asset.mediaSubtypes.contains(.photoLive) {
            showLivePhoto()
        } else {
            showImage()
        }
    }
    
    @IBAction func showPreviewButtonTapped(_ sender: Any) {
        showOverlayPreview()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        if !isPlaying {
            isPlaying = true
            playVideo()
            if #available(iOS 13.0, *) {
                playButton.image = UIImage(systemName: "pause.fill")
            }
        } else {
            isPlaying = false
            pauseVideo()
            if #available(iOS 13.0, *) {
                playButton.image = UIImage(systemName: "play.fill")
            }
        }
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        if asset.mediaType == .video {
            // Video - Update progressView
            progressView.isHidden = false
            let progressHandler: (Float) -> Void = { p in
                DispatchQueue.main.async {
                    self.progressView.progress = p
                }
            }
            // When user did not playback Video - fetch video url first
            if videoAssetUrl == nil {
                self.convertPHAsset2AVAsset(asset: asset, options: nil) { avAsset in
                    guard let avAsset = avAsset else { self.cancleProgressViewAnimation(); return }
                    VideoOverlays.shared.exportCombinedVideo(from: avAsset.url, progress: progressHandler) { exportUrl in
                        guard let exportUrl = exportUrl else { self.cancleProgressViewAnimation(); return }
                        self.saveVideo(videoUrl: exportUrl)
                    }
                }
            } else {
                VideoOverlays.shared.exportCombinedVideo(from: videoAssetUrl!, progress: progressHandler) { exportUrl in
                    guard let exportUrl = exportUrl else { self.cancleProgressViewAnimation(); return }
                    self.saveVideo(videoUrl: exportUrl)
                }
            }
        } else {
            // Live photo - Fetch UIImage to save first.
            if asset.mediaSubtypes.contains(.photoLive) {
                PHImageManager.default().requestImage(for: self.asset, targetSize: self.targetSize, contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
                    let temp = UIImageView()
                    temp.image = image
                    temp.frame = self.imageView.bounds
                    _ = ImageOverlays.shared.addImageLayer(to: temp.layer, layerSize: temp.frame.size)
                    
                    ImageOverlays.shared.exportImage(imageView: temp) { combined in
                        guard let combined = combined else { return }
                        self.saveImage(image: combined)
                    }
                })
            } else {
                // Image - if overlay layer not adjusted add first.
                if !isPreviewOn {
                    showOverlayPreview()
                }
                ImageOverlays.shared.exportImage(imageView: imageView) { combined in
                    guard let combined = combined else { return }
                    self.saveImage(image: combined)
                }
            }
        }
    }
    
    // MARK: Overlays Preview
   
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
                overlayLayer = ImageOverlays.shared.addImageLayer(to: self.livePhotoView.layer, layerSize: self.livePhotoView.frame.size)
            } else {
                overlayLayer = ImageOverlays.shared.addImageLayer(to: self.imageView.layer, layerSize: self.imageView.frame.size)
            }
        }
    }
    
    // MARK: Image
    
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
    
    // MARK: Live Photo
    
    private func showLivePhoto() {
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            DispatchQueue.main.sync {
                self.progressView.progress = Float(progress)
            }
        }
        // Fetch LivePhoto to show
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
    
    // MARK: Video
    
    private func playVideo() {
        guard asset.mediaType == .video else { return }

        if playerLayer != nil {
            if videoEnded {
                playerLayer.player!.seek(to: .zero)
                videoEnded = false
            }
            playerLayer.player!.play()
        } else {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .automatic
            options.progressHandler = { progress, _, _, _ in
                DispatchQueue.main.sync {
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
    
    private func pauseVideo() {
        playerLayer.player!.pause()
    }
    
    // MARK: Save
    
   private func saveImage(image: UIImage) {
       PHPhotoLibrary.shared().performChanges({
           PHAssetChangeRequest.creationRequestForAsset(from: image)
       }) {[weak self] success, error in
           guard let self = self else { return }
           if success {
               DispatchQueue.main.async {
                   self.navigationController?.popViewController(animated: true)
               }
           } else {
               print("saving error \(error.debugDescription)")
           }
       }
   }
   
   private func saveVideo(videoUrl: URL) {
       PHPhotoLibrary.shared().performChanges({
           PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
       }) { [weak self] success, error in
           guard let self = self else { return }
           if success {
               DispatchQueue.main.async {
                   self.navigationController?.popViewController(animated: true)
               }
           } else {
               print("saving error \(error.debugDescription)")
           }
       }
   }
    
    // MARK: Convenience
    
    private func cancleProgressViewAnimation() {
        progressView.isHidden = true
    }
    
    @objc
    private func hideToolBar() {
        if asset.mediaType == .video {
            toolBar.isHidden = !toolBar.isHidden
        }
        navigationController?.navigationBar.isHidden = !(navigationController?.navigationBar.isHidden)!
    }
   
    private func convertPHAsset2AVAsset(asset: PHAsset, options: PHVideoRequestOptions?, completion: @escaping (AVURLAsset?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { asset, _, _ in
            completion(asset as? AVURLAsset)
        })
    }
}
