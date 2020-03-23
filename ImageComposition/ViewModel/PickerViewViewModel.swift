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

    private let defaultOptions: PHFetchOptions = {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return options
    }()
    
    var assets: PHFetchResult<PHAsset>!
    var smartAlbums: PHFetchResult<PHAssetCollection>? {
        didSet {
            assets = PHAsset.fetchAssets(with: defaultOptions)
            delegate?.reloadView()
        }
    }
    var numberOfPhotos: Int {
        return assets.count
    }
    var selectedAlbumIndex: AlbumIndex = 0 {
        didSet {
            fetchPhotos(at: selectedAlbumIndex)
        }
    }
    
    override init() {
        super.init()
        if assets == nil {
            assets = PHAsset.fetchAssets(with: defaultOptions)
        }
    }
     
    func fetchAlbums() {
        self.smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: .none)
    }
    
    func fetchPhotos(at index: AlbumIndex?) {
        if index == nil {
            assets = PHAsset.fetchAssets(with: defaultOptions)
        } else if let album = smartAlbums?[index!] {
            assets = PHAsset.fetchAssets(in: album, options: defaultOptions)
        }
        delegate?.reloadView()
    }
    
    func asset(at indexPath: IndexPath) -> PHAsset? {
        return indexPath.row < numberOfPhotos ? assets[indexPath.row] : nil
    }
    
    func update(assets: PHFetchResult<PHAsset>) {
        self.assets = assets
    }

}
