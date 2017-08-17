//
//  PhotoCollectionViewCell.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 9/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit
import CoreData

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbNailImage: UIImageView!
    @IBOutlet weak var downloadActivityIndicator: UIActivityIndicatorView!
    weak var referencedNavigationController: UINavigationController?
    weak var referralPhoto:PhotoMO?
    
    var photoSourceURL:String?
    var photoLegend:String?
    var photoDownloadTask:URLSessionTask?
    
    func setPhoto(referralPhoto: PhotoMO) {
        self.referralPhoto = referralPhoto
        photoLegend = referralPhoto.legend
        photoSourceURL = referralPhoto.sourceURL
        if let data = referralPhoto.image {
            thumbNailImage.image = UIImage(data: data as Data)
            downloadActivityIndicator.stopAnimating()
        } else {
            photoDownloadTask = Networking.sharedInstance().taskForGETMethod(serverHost: referralPhoto.sourceURL!, serverPath: "", parameters: [:], isJSON: false, completionHandlerForGET: {
                [unowned self] (JSON, data, error) in
                if let error = error {
                    print(error)
                    DispatchQueue.main.async {
                        self.downloadActivityIndicator.stopAnimating()
                        referralPhoto.image = NSData()
                    }
                } else {
                    DispatchQueue.main.async {
                        let downloadedImage = UIImage(data: data!)
                        // 👉🏽 I tried this "hack" to prevent image flickering during scrolling in collection but it's not working on my end; i have a slower bandwidth than average so you might no notice it right away but when fast scrolling during image downloading they tend to replace wrong images in the cell until the proper one is downloaded and then replace it (user-perceivable) 
                        if self.photoSourceURL == referralPhoto.sourceURL {
                            self.thumbNailImage.image = downloadedImage
                        }
                        referralPhoto.image = data! as NSData
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
                NotificationCenter.default.post(name: updateGalleryNotification, object: self.referralPhoto!, userInfo: nil)
            }), animated: true)
        }
    }
}
