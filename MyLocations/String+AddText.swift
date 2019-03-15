//
//  String+AddText.swift
//  MyLocations
//
//  Created by Yavor Dimov on 3/12/19.
//  Copyright © 2019 Yavor Dimov. All rights reserved.
//

import Foundation

extension String {
    mutating func add(text: String?, separatedBy separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
