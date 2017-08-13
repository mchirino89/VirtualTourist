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
    var photosSource:[[String:String]] = []
    var pinLocationImagesPage:Int?
    
    @IBOutlet weak var detailedMapView: MKMapView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationItem.titleView = getCustomTitle(viewTitle: locationName!)
        let referralPin = MKPointAnnotation()
        referralPin.coordinate = locationCoordinates!
        detailedMapView.addAnnotation(referralPin)
        detailedMapView.setRegion(MKCoordinateRegion(center: locationCoordinates!, span: MKCoordinateSpan(latitudeDelta: 1.25, longitudeDelta: 1.25)), animated: true)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 8, right: 0)
        layout.itemSize = CGSize(width: (view.bounds.width / 3) - 8, height: (view.bounds.width / 3) - 8)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        photoCollectionView.collectionViewLayout = layout
        loadPinImages(page: 1) // Initial load
        NotificationCenter.default.addObserver(forName: updateGalleryNotification, object: nil, queue: nil, using: galleryUpdate)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? FullScreenViewController else { return }
        guard let selectedCell = sender as? PhotoCollectionViewCell else { return }
        destination.imageId = selectedCell.photoId
        destination.fullImage = selectedCell.thumbNailImage.image
        destination.imageLegend = selectedCell.photoLegend
    }
    
    func galleryUpdate(notification: Notification) {
        guard let deletedId = notification.object as? String else {
            print("No cell id found in notification")
            return
        }
        photosSource = photosSource.filter { $0[Constants.JSONResponseKey.photoId] != deletedId }
        photoCollectionView.reloadData()
    }
    
    @IBAction func newCollectionAction() {
        loadPinImages(page: Int(arc4random_uniform(UInt32(pinLocationImagesPage!))))
    }
    
    private func loadPinImages(page: Int) {
        
        photosSource.removeAll()
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
            let _ = Networking.sharedInstance().taskForGETMethod(serverHost: Constants.URL.FlickrServer, serverPath: Constants.URL.APIpath, parameters: getPhotosParameters, isJSON: true, completionHandlerForGET: { [unowned self] (JSON, data, error) in
                if let error = error {
                    print(error)
                    DispatchQueue.main.async {
                        self.refreshCollectionList(UIAvailability: (false, false))
                    }
                } else {
                    guard let jsonResponse = JSON![Constants.JSONResponseKey.photos] as? [String: Any] else { return }
                    DispatchQueue.main.async {
                        let UIStates = self.setImagesSource(results: jsonResponse)
                        self.refreshCollectionList(UIAvailability: UIStates)
                    }
                }
            })
        }
    }
    
    private func setImagesSource(results: [String: Any]) -> (Bool, Bool) {
        guard let photos = results[Constants.JSONResponseKey.image] as? [[String: Any]] else { return (false, false) }
        if photos.count > 0 {
            let _ = photos.map {
                let newPhoto = [Constants.JSONResponseKey.photoId: $0[Constants.JSONResponseKey.photoId] as! String,Constants.JSONResponseKey.legend: $0[Constants.JSONResponseKey.legend] as! String, Constants.JSONResponseKey.sourceURL: $0[Constants.JSONResponseKey.sourceURL] as! String]
                photosSource.append(newPhoto)
            }
        }
        guard let pages = results[Constants.JSONResponseKey.pages] as? Int, let total = (results[Constants.JSONResponseKey.total] as? NSString)?.integerValue else { return (false, false) }
        return (pages > 1, total > 0)
    }
    
    private func refreshCollectionList(UIAvailability: (Bool, Bool)) {
        photoCollectionView.reloadData()
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0
            self.photoCollectionView.alpha = UIAvailability.1 ? 1 : 0
        }, completion: { _ in
            self.view.sendSubview(toBack: self.loadingView)
            self.newCollectionButton.isEnabled = UIAvailability.0
        })
    }
}

extension LocationController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photosSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.photoCell, for: indexPath) as! PhotoCollectionViewCell
        cell.setId(photosSource[indexPath.row][Constants.JSONResponseKey.photoId]!)
        cell.setLegend(photosSource[indexPath.row][Constants.JSONResponseKey.legend]!)
        cell.setPhoto(photosSource[indexPath.row][Constants.JSONResponseKey.sourceURL]!)
        cell.setLongPressGesture(navigationController: navigationController!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: Constants.Storyboard.fullScreenSegue, sender: (collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell))
    }
}
