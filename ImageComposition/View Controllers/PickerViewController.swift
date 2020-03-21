//
//  PickerViewController.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/18.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import Photos.PHPhotoLibrary
import PhotosUI

class PickerViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let viewModel = PickerViewViewModel()
    private let imageManager = PHCachingImageManager()
    private var cellSize: CGSize {
        get {
            return (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
        }
    }
    private let requestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        return options
    }()
    private var previousPreheatRect = CGRect.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetCache()
        PHPhotoLibrary.shared().register(self)
        viewModel.delegate = self
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.fetchAlbums()
                default:
                    self.showNotAvailableAlert()
                }
            }
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    @IBAction func selectAlbumButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "Pick an album", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "All Photos", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.fetchPhtos(at: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancle", style: .cancel, handler: nil))
        viewModel.smartAlbums?.enumerateObjects { collectionView, index, _ in
            alert.addAction(UIAlertAction(title: collectionView.localizedTitle ?? "Untitled", style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.fetchPhtos(at: index)
            }))
        }
        alert.deleteSubConstraints()
        present(alert, animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? PreviewViewController else { return }
        let indexPath = collectionView.indexPath(for: sender as! UICollectionViewCell)!
        guard let asset = viewModel.asset(at: indexPath) else {
            print("asset not available")
            return
        }
        destination.asset = asset
    }
    
    // MARK: Convenience
    
    private func fetchAlbums() {
        viewModel.fetchAlbums()
    }
    
    private func fetchPhtos(at index: AlbumIndex?) {
        viewModel.fetchPhotos(at: index)
    }
    
    // TODO:
    private func showNotAvailableAlert() {
        
    }
    
    // MARK: Asset Caching
    
    private func resetCache() {
        self.imageManager.stopCachingImagesForAllAssets()
        self.previousPreheatRect = .zero
    }
    
    private func cacheAssets() {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > self.view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removeRects) = previousPreheatRect.diffrences(with: preheatRect)
        let addedAssets: [PHAsset] = addedRects
            .flatMap { rect in self.collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in self.viewModel.asset(at: indexPath)! }
        let removedAssets = removeRects
            .flatMap { rect in self.collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in self.viewModel.asset(at: indexPath)! }
        
        imageManager.startCachingImages(for: addedAssets, targetSize: self.cellSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets, targetSize: self.cellSize, contentMode: .aspectFill, options: nil)
        
        previousPreheatRect = preheatRect
    }
}

// MARK: UICollectionView Data Source

extension PickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfPhotos
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseId, for: indexPath) as! PhotoCell
        guard let asset = viewModel.asset(at: indexPath) else { return cell }
        if asset.mediaSubtypes.contains(.photoLive) {
            cell.liveImageBadge.image = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
        }
        cell.assetId = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: cellSize, contentMode: .aspectFill, options: requestOptions, resultHandler: { image, _ in
            if cell.assetId == asset.localIdentifier {
                cell.imageView.image = image
            }
        })
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cacheAssets()
    }
}

// MARK: UICollectionView Flow Layout

extension PickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // TODO: 가로모드 일때
        let width = (collectionView.bounds.width - 4) / 3
        return CGSize(width: width, height: width)
    }
}

// MARK: ViewModel Delegate

extension PickerViewController: PickerViewViewModelDelegate {
    func reloadView() {
        self.collectionView.reloadData()
        cacheAssets()
    }
}

// MARK: PHPhotoLibraryChangeObserver

extension PickerViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: viewModel.assets) else { return }
        DispatchQueue.main.sync {
            viewModel.update(assets: changes.fetchResultAfterChanges)
            if changes.hasIncrementalChanges {
                collectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map { IndexPath(item: $0, section: 0)})
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section: 0)})
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section: 0)})
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0), to: IndexPath(item: toIndex, section: 0))
                    }
                }, completion: nil)
            } else {
                collectionView.reloadData()
            }
            resetCache()
        }
    }
}
