//
//  CollectionView + CGRect Extensions.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/19.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit

extension CGRect {
    func diffrences(with: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if self.intersects(with) {
            var added = [CGRect]()
            if with.maxY > self.maxY {
                added += [CGRect(x: with.origin.x, y: self.maxY, width: with.width, height: with.maxY - self.maxY)]
            }
            if self.minY > with.minY {
                added += [CGRect(x: with.origin.x, y: with.minY, width: with.width, height: self.minY - with.minY)]
            }
            var removed = [CGRect]()
            if with.maxY < self.maxY {
                removed += [CGRect(x: with.origin.x, y: with.maxY, width: with.width, height: self.maxY - with.maxY)]
            }
            if self.minY < with.minY {
                removed += [CGRect(x: with.origin.x, y: self.minY, width: with.width, height: with.minY - self.minY)]
            }
            return (added, removed)
        } else {
            return ([with], [self])
        }
    }
}

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
