//
//  LocationController.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 9/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit
import MapKit


class LocationController: UIViewController {
    
    var locationIdentifier: String?
    var locationName: String?
    var locationCoordinates: CLLocationCoordinate2D?
    var photosSource:[String] = []
    
    @IBOutlet weak var detailedMapView: MKMapView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = locationName
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 8, right: 0)
        layout.itemSize = CGSize(width: (view.bounds.width / 3) - 8, height: (view.bounds.width / 3) - 8)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        photoCollectionView.collectionViewLayout = layout
        loadPinImages(page: 1) // Initial load
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let referralPin = MKPointAnnotation()
        referralPin.coordinate = locationCoordinates!
        detailedMapView.addAnnotation(referralPin)
        detailedMapView.setRegion(MKCoordinateRegion(center: locationCoordinates!, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)), animated: true)
    }
    
    private func loadPinImages(page: Int) {
        
        loadingView.alpha = 0.6
        view.bringSubview(toFront: loadingView)
        
        let getPhotosParameters:[String:AnyObject] = [
            Constants.ParameterKey.method: Constants.ParameterValue.method as AnyObject,
            Constants.ParameterKey.APIKey: Constants.ParameterValue.APIKey as AnyObject,
            Constants.ParameterKey.latitud: locationCoordinates!.latitude as AnyObject,
            Constants.ParameterKey.longitude: locationCoordinates!.longitude as AnyObject,
            Constants.ParameterKey.format: Constants.ParameterValue.format as AnyObject,
            Constants.ParameterKey.results: Constants.ParameterValue.results as AnyObject,
            Constants.ParameterKey.extra: Constants.ParameterValue.extra as AnyObject,
            Constants.ParameterKey.callback: Constants.ParameterValue.callback as AnyObject,
            Constants.ParameterKey.currentPage: page as AnyObject
        ]
        
        DispatchQueue.global(qos: .userInteractive).async {
            Networking.sharedInstance().taskForGETMethod(parameters: getPhotosParameters, isJSON: true, completionHandlerForGET: { (JSON, data, error) in
                if let error = error {
                    print(error)
                    DispatchQueue.main.async {
                        self.refreshCollectionList(extraLoad: false)
                    }
                } else {
                    print(JSON ?? "Something wrong with JSON response")
                    guard let jsonResponse = JSON![Constants.JSONResponseKey.photos] as? [String: Any] else { return }
                    let moreImages = self.setImages(results: jsonResponse)
                    DispatchQueue.main.async {
                        self.refreshCollectionList(extraLoad: moreImages)
                    }
                }
            })
        }
    }
    
    func refreshCollectionList(extraLoad: Bool) {
        photoCollectionView.reloadData()
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0
        }, completion: { _ in
            self.view.sendSubview(toBack: self.loadingView)
            self.newCollectionButton.isEnabled = extraLoad
        })
    }
    
    private func setImages(results: [String: Any]) -> Bool {
        guard let photos = results[Constants.JSONResponseKey.image] as? [[String: Any]] else { return false }
        if photos.count > 0 {
            let _ = photos.map {
                photosSource.append($0[Constants.JSONResponseKey.sourceURL] as! String)
            }
        }
        if let pages = results[Constants.JSONResponseKey.pages] as? Int {
            return pages > 1
        }
        return false
    }
}

extension LocationController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.photoCell, for: indexPath) as! PhotoCollectionViewCell
        cell.thumbNailImage.image = #imageLiteral(resourceName: "placeholderPhoto")
//        cell.thumbNailImage.setImageFromURl(sourceURL: photosSource[indexPath.row])
        cell.downloadActivityIndicator.stopAnimating()
        return cell
    }
}

extension UIImageView{
    func setImageFromURl(sourceURL: String) {
        
        if let url = URL(string: sourceURL) {
            if let data = NSData(contentsOf: url as URL) {
                self.image = UIImage(data: data as Data)
            }
        }
    }
}
