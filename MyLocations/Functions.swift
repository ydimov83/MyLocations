//
//  Functions.swift
//  MyLocations
//
//  Created by Yavor Dimov on 2/21/19.
//  Copyright © 2019 Yavor Dimov. All rights reserved.
//

import Foundation

func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}
