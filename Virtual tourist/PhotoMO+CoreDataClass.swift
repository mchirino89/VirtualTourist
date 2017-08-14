//
//  PhotoMO+CoreDataClass.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 13/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import Foundation
import CoreData

@objc(PhotoMO)
public class PhotoMO: NSManagedObject {
    convenience init(image: NSData, legend: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.image = image
            self.legend = legend
        } else {
            fatalError("Unable to find entity name")
        }
    }

}
