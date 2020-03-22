//
//  VideoOverlays.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/20.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import AVFoundation

class VideoOverlays {
    static let shared = VideoOverlays()
    private var timer: DispatchSourceTimer?
    private let progressQueue = DispatchQueue(label: "com.jk.progress_queue")
    private var progressValue: Float = 0.1
    
    func exportCombinedVideo(from videoUrl: URL, progress: @escaping (Float) -> Void, completion: @escaping (URL?) -> Void) {
        print(videoUrl)
        // Set progress timer
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: progressQueue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(1))
        timer?.setEventHandler(handler: { [unowned self] in
            self.progressValue += 0.1
            progress(self.progressValue)
        })
        timer?.resume()
        
        let asset = AVURLAsset(url: videoUrl)
        let composition = AVMutableComposition()
        
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first else {
            completion(nil)
            return
        }
        // To combine audio
        do {
            let wholeTime = CMTimeRange(start: .zero, end: asset.duration)
            try compositionTrack.insertTimeRange(wholeTime, of: assetTrack, at: .zero)
            
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first, let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(wholeTime, of: audioAssetTrack, at: .zero)
            }
        } catch let error as NSError {
            print("audio error \(error.localizedDescription)")
            completion(nil)
            return
        }
        // Set output video size
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        let videoSize: CGSize
        if videoInfo.isPortrait {
            videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
        } else {
            videoSize = assetTrack.naturalSize
        }
        
        let videoLayer = createCALayer(size: videoSize)
        let overlayLayer = createCALayer(size: videoSize)
        // Add overlay image
        _ = ImageOverlays.shared.addImageLayer(to: overlayLayer, layerSize: videoSize)
        
        let ouputLayer = createCALayer(size: videoSize)
        ouputLayer.addSublayer(videoLayer)
        ouputLayer.addSublayer(overlayLayer)
        // Output video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: ouputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        // Export session
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            print("Fail to export session")
            completion(nil)
            return
        }
        
        let title = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(title).appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    print("completed")
                    self.timer?.cancel()
                    completion(exportURL)
                default:
                    print(export.error ?? "export error occurred")
                    completion(nil)
                }
            }
        }
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        instruction.setTransform(transform, at: .zero)
        return instruction
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
           var assetOrientation = UIImage.Orientation.up
           var isPortrait = false
           if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
               assetOrientation = .right
               isPortrait = true
           } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
               assetOrientation = .left
           } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
               assetOrientation = .up
           } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
               assetOrientation = .down
           }
           
           return (assetOrientation, isPortrait)
    }
    
    private func createCALayer(size: CGSize) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: size)
        return layer
    }
}
