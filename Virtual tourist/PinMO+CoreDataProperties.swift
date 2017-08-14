//
//  PinMO+CoreDataProperties.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 13/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import Foundation
import CoreData


extension PinMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PinMO> {
        return NSFetchRequest<PinMO>(entityName: "Pin")
    }

    @NSManaged public var id: Int16
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var title: String?
    @NSManaged public var creation: NSDate?
    @NSManaged public var photoId: NSSet?

}

// MARK: Generated accessors for photoId
extension PinMO {

    @objc(addPhotoIdObject:)
    @NSManaged public func addToPhotoId(_ value: PhotoMO)

    @objc(removePhotoIdObject:)
    @NSManaged public func removeFromPhotoId(_ value: PhotoMO)

    @objc(addPhotoId:)
    @NSManaged public func addToPhotoId(_ values: NSSet)

    @objc(removePhotoId:)
    @NSManaged public func removeFromPhotoId(_ values: NSSet)

}
