//
//  Alert Extensions.swift
//  ImageComposition
//
//  Created by Jae Kyung Lee on 2020/03/19.
//  Copyright © 2020 Jae Kyung Lee. All rights reserved.
//

import UIKit.UIAlertController

extension UIAlertController {
    func deleteSubConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}
