//
//  PickerViewController.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/18.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit
import Photos.PHPhotoLibrary

class PickerViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let viewModel = PickerViewViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction func selectAlbumButtonTapped(_ sender: Any) {
        UIAlertController(title: nil, message: "Pick an album", preferredStyle: .actionSheet)
        // TODO: if not done show indicator
        
    }
    
    private func fetchAlbums() {
        viewModel.fetchAlbums()
    }
    
    // TODO:
    private func showNotAvailableAlert() {
        
    }
    // TODO: Image Caching
}

// MARK: UICollectionView Data Source

extension PickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfPhotos
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseId, for: indexPath) as! PhotoCell
        return cell
    }
}

// MARK: UICollectionView Flow Layout

extension PickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 20) / 3
        return CGSize(width: width, height: width)
    }
}

// MARK: ViewModel Delegate

extension PickerViewController: PickerViewViewModelDelegate {
    func reloadView() {
        self.collectionView.reloadData()
    }
}
