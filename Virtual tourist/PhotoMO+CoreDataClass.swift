//
//  PhotoMO+CoreDataClass.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 15/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import Foundation
import CoreData

@objc(PhotoMO)
public class PhotoMO: NSManagedObject {
    convenience init(sourceURL: String, legend: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: Constants.CoreData.Photo.entity, in: context) {
            self.init(entity: entity, insertInto: context)
            self.sourceURL = sourceURL
            self.legend = legend
        } else {
            fatalError("\(Constants.ErrorMessages.noEntity) \(Constants.CoreData.Photo.entity)")
        }
    }
    
    func setImage(image: NSData) {
        self.image = image
    }
}
