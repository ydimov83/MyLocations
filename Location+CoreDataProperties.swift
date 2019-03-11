//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by Yavor Dimov on 2/22/19.
//  Copyright © 2019 Yavor Dimov. All rights reserved.
//
//

import Foundation
import CoreData
import CoreLocation


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var date: Date
    @NSManaged public var locationDescription: String
    @NSManaged public var category: String
    @NSManaged var placemark: CLPlacemark?
    @NSManaged public var photoID: NSNumber?

}
