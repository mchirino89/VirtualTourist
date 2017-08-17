//
//  PinMO+CoreDataClass.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 15/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import Foundation
import CoreData

@objc(PinMO)
public class PinMO: NSManagedObject {
    convenience init(identifier: String, title: String, subtitle: String, latitude: Double, longitude: Double, creation: NSDate, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: Constants.CoreData.Pin.entity, in: context) {
            self.init(entity: entity, insertInto: context)
            self.identifier = identifier
            self.title = title
            self.subtitle = subtitle
            self.latitude = latitude
            self.longitude = longitude
            self.creation = creation
        } else {
            fatalError("\(Constants.ErrorMessages.noEntity) \(Constants.CoreData.Pin.entity)")
        }
    }
}
