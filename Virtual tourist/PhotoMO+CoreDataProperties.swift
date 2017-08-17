//
//  PhotoMO+CoreDataProperties.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 15/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import Foundation
import CoreData


extension PhotoMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoMO> {
        return NSFetchRequest<PhotoMO>(entityName: "Photo")
    }
    
    @NSManaged public var sourceURL: String?
    @NSManaged public var image: NSData?
    @NSManaged public var legend: String?
    @NSManaged public var pinId: PinMO?

}
