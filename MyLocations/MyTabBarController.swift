//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Yavor Dimov on 3/14/19.
//  Copyright © 2019 Yavor Dimov. All rights reserved.
//

import UIKit


class MyTabBarController: UITabBarController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override var childForStatusBarStyle: UIViewController? {
        return nil
    }
}
