//
//  LivePhotoOverlays.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/21.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class LivePhotoOverlays {
    typealias LivePhotoResources = (photo: URL, pariedVideo: URL)
    
    static let shared = LivePhotoOverlays()
    
    private static let queue = DispatchQueue(label: "com.jk.live_photo", attributes: .concurrent)
    lazy private var cacheDirectory: URL? = {
        if var cachesDirectory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let fullDirectory = URL(fileURLWithPath: cachesDirectory.appendingPathComponent("com.jk.live_photo_directory").absoluteString, isDirectory: true)
            if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString) {
                try? FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            return fullDirectory
        }
        return nil
    }()
    
    public class func getResources(from livePhoto: PHLivePhoto, completion: @escaping (LivePhotoResources?) -> Void) {
        queue.async {
            shared.extractResources(from: livePhoto, completion: completion)
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, completion: @escaping (LivePhotoResources?) -> Void) {
        if let cacheDirectory = cacheDirectory {
            extractResources(from: livePhoto, to: cacheDirectory, completion: completion)
        }
    }
    
    private func extractResources(from livePhoto: PHLivePhoto, to directoryURL: URL, completion: @escaping (LivePhotoResources?) -> Void) {
        
        let assetResources = PHAssetResource.assetResources(for: livePhoto)
        let group = DispatchGroup()
        var photoURL: URL?
        var pairdVideURL: URL?
        
        for resource in assetResources {
            let buffer = NSMutableData()
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            group.enter()
            PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { data in
                buffer.append(data)
            }) { error in
                if error == nil {
                    if resource.type == PHAssetResourceType.pairedVideo {
                        print("retreving live photo paired video")
                        pairdVideURL = self.getAssetResourceUrl(resource, to: directoryURL, resourceData: buffer as Data)
                    } else if resource.type == PHAssetResourceType.photo {
                        print("retreving live photo data for photo")
                        photoURL = self.getAssetResourceUrl(resource, to: directoryURL, resourceData: buffer as Data)
                    }
                } else {
                    print("paried video error \(error.debugDescription)")
                }
                group.leave()
            }
            group.notify(queue: DispatchQueue.main, execute: {
                guard let photoURL = photoURL, let pairedVideoURL = pairdVideURL else {
                    completion(nil)
                    return
                }
                completion((photoURL, pairedVideoURL))
            })
        }
    }
    
    private func getAssetResourceUrl(_ resource: PHAssetResource, to directory: URL, resourceData: Data) -> URL? {
        let tags = UTTypeCopyPreferredTagWithClass(resource.uniformTypeIdentifier as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()
        guard let tagsStr = tags else { return nil }
            
        var fileURL = directory.appendingPathComponent(UUID().uuidString)
        fileURL = fileURL.appendingPathComponent(tagsStr as String)
        
        do {
            try resourceData.write(to: fileURL, options: [Data.WritingOptions.atomic])
        } catch let error as NSError {
            print(error.debugDescription)
            return nil
        }
        return fileURL
    }
    
    // MARK: Cache
    
    private func resetCache() {
        if let cacheDirectory = cacheDirectory {
            try? FileManager.default.removeItem(at: cacheDirectory)
        }
    }
    
}
