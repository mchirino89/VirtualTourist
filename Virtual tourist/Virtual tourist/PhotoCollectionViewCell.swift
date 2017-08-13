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
    weak var referencedNavigationController: UINavigationController?
    
    var photoId:String?
    var photoSourceURL:String?
    var photoLegend:String?
    var photoDownloadTask:URLSessionTask?
    
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
            photoDownloadTask = Networking.sharedInstance().taskForGETMethod(serverHost: sourceURL, serverPath: "", parameters: [:], isJSON: false, completionHandlerForGET: {
                [unowned self] (JSON, data, error) in
                if let error = error {
                    print(error)
                    DispatchQueue.main.async {
                        self.downloadActivityIndicator.stopAnimating()
                        Singleton.sharedInstance.appCache.setObject(UIImage(), forKey: sourceURL as AnyObject)
                    }
                } else {
                    DispatchQueue.main.async {
                        let downloadedImage = UIImage(data: data!)
                        if self.photoSourceURL == sourceURL {
                            self.thumbNailImage.image = downloadedImage
                        }
                        Singleton.sharedInstance.appCache.setObject(downloadedImage!, forKey: sourceURL as AnyObject)
                        self.downloadActivityIndicator.stopAnimating()
                    }
                }
            })
        }
    }
    
    func cancelPhotoDownload() {
        photoDownloadTask?.cancel()
    }
    
    func setLongPressGesture(navigationController: UINavigationController) {
        referencedNavigationController = navigationController
        let erasePhotoLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(erasePicture(sender:)))
        erasePhotoLongPressGesture.minimumPressDuration = 0.3
        addGestureRecognizer(erasePhotoLongPressGesture)
    }
    
    func erasePicture(sender: UIGestureRecognizer) {
        if sender.state == .began {
            referencedNavigationController?.present(questionPopup(title: Constants.UIMessages.deletePictureTitle, message: Constants.UIMessages.deletePictureMessage, style: .alert, afirmativeAction: { [unowned self] _ in
                self.cancelPhotoDownload()
                NotificationCenter.default.post(name: updateGalleryNotification, object: (sender.view as! PhotoCollectionViewCell).photoId!, userInfo: nil)
            }), animated: true)
        }
    }
}
