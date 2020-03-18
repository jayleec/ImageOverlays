//
//  PickerViewViewModel.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/18.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import Foundation
import Photos

typealias AlbumIndex = Int

protocol PickerViewViewModelDelegate: class {
    func reloadView()
}

class PickerViewViewModel: NSObject {
    
    weak var delegate: PickerViewViewModelDelegate?
    
    private var albums: PHFetchResult<PHAssetCollection>?
    private var photos: PHFetchResult<PHAsset>? {
        didSet {
            delegate?.reloadView()
        }
    }
    private let albumsFetchQueue = DispatchQueue(label: "albums_fetch")
    
    var numberOfAlbums: Int {
        return (albums?.count ?? 0) + 1
    }
    var numberOfPhotos: Int {
        return photos?.count ?? 0
    }
    var selectedAlbumIndex: AlbumIndex? {
        didSet {
            guard let index = selectedAlbumIndex else { return }
            fetchPhotos(for: index)
        }
    }
    
    func fetchAlbums() {
        selectedAlbumIndex = 0
        albumsFetchQueue.async {
            self.albums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        }
    }
    
    private func fetchPhotos(for index: AlbumIndex) {
        if index == 0 {
            photos = PHAsset.fetchAssets(with: .none)
        } else if let album = albums?[index - 1] {
            photos = PHAsset.fetchAssets(in: album, options: nil)
        }
    }
}
