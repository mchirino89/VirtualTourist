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
    @IBOutlet weak var detailedMapView: MKMapView!
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
        
        Networking.sharedInstance().taskForGETMethod(parameters: ["method": "flickr.photos.search" as Any as AnyObject, "api_key": "f78755583fac5d9ece56b77eb3dd331e" as Any as AnyObject, "lat": locationCoordinates!.latitude as Any as AnyObject, "lon": locationCoordinates!.longitude as Any as AnyObject, "extras": "url_m" as Any as AnyObject, "per_page": 25 as Any as AnyObject, "format": "json" as Any as AnyObject, "nojsoncallback": 1 as Any as AnyObject], jsonBody: "", completionHandlerForGET: { (results, error) in
                if let error = error {
                    print(error)
                    DispatchQueue.main.async {
                    }
                } else {
                    guard let jsonResponse = results else { return }
                    print(jsonResponse)
                    DispatchQueue.main.async {
                        
                    }
                }
        })
        
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
    
}

extension LocationController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.photoCell, for: indexPath) as! PhotoCollectionViewCell
        cell.thumbNailImage.image = #imageLiteral(resourceName: "placeholderPhoto")
        cell.downloadActivityIndicator.stopAnimating()
        return cell
    }
}

extension LocationController: MKMapViewDelegate {
    
}
