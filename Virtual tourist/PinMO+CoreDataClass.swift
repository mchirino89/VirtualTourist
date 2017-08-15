//
//  PinMO+CoreDataClass.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 14/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import Foundation
import CoreData

@objc(PinMO)
public class PinMO: NSManagedObject {
    convenience init(title: String, subtitle: String, latitude: Double, longitude: Double, creation: NSDate, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.title = title
            self.subtitle = subtitle
            self.latitude = latitude
            self.longitude = longitude
            self.creation = creation
        } else {
            fatalError("Unable to find entity name")
        }
    }
}
