//
//  PinMO+CoreDataClass.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 13/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import Foundation
import CoreData

@objc(PinMO)
public class PinMO: NSManagedObject {
    convenience init(title: String, latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.title = title
            self.latitude = latitude
            self.longitude = longitude
            creation = NSDate()
        } else {
            fatalError("Unable to find entity name")
        }
    }
    
    // MARK: Computed Property
    
    var humanReadableAge: String {
        get {
            let fmt = DateFormatter()
            fmt.timeStyle = .none
            fmt.dateStyle = .short
            fmt.doesRelativeDateFormatting = true
            fmt.locale = Locale.current
            return fmt.string(from: creation! as Date)
        }
    }
}
