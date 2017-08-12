//
//  PhotoCollectionViewCell.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 9/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbNailImage: UIImageView!
    @IBOutlet weak var downloadActivityIndicator: UIActivityIndicatorView!
    var photoId:String?
    var photoSourceURL:String?
    var photoLegend:String?
    
    func setId(_ id: String) {
        photoId = id
    }
    
    func setLegend(_ legend: String) {
        photoLegend = legend
    }
    
    func setPhoto(_ sourceURL: String) {
        
        photoSourceURL = sourceURL
        if let image = Singleton.sharedInstance.appCache.object(forKey: sourceURL as AnyObject) as? UIImage {
            thumbNailImage.image = image
            downloadActivityIndicator.stopAnimating()
        } else {
            Networking.sharedInstance().taskForGETMethod(serverHost: sourceURL, serverPath: "", parameters: [:], isJSON: false, completionHandlerForGET: {
                [unowned self] (JSON, data, error) in
                if let error = error {
                    print(error)
                    DispatchQueue.main.async {
                        self.downloadActivityIndicator.stopAnimating()
                        Singleton.sharedInstance.appCache.setObject(UIImage(), forKey: sourceURL as AnyObject)
                    }
                } else {
                    DispatchQueue.main.async(execute: {
                        let downloadedImage = UIImage(data: data!)
                        if self.photoSourceURL == sourceURL {
                            self.thumbNailImage.image = downloadedImage
                        }
                        Singleton.sharedInstance.appCache.setObject(downloadedImage!, forKey: sourceURL as AnyObject)
                        self.downloadActivityIndicator.stopAnimating()
                    })
                }
            })
        }
    }
}
