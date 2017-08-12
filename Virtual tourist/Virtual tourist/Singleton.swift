//
//  AppCache.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 11/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit

class Singleton {
    let appCache = NSCache<AnyObject, AnyObject>()
    static let sharedInstance = Singleton()
    private init() {}
}
