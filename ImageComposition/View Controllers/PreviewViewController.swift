//
//  PreviewViewController.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/19.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import Photos

class PreviewViewController: UIViewController {
    
    @IBOutlet weak var progressView: UIProgressView!
    
    var asset: PHAsset!
    private var playerLayer: AVPlayerLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        if asset.mediaType == .video {
            // TODO: show play button
            play()
        }
    }
    
    func play() {
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
                    layer.backgroundColor = UIColor.yellow.cgColor
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
