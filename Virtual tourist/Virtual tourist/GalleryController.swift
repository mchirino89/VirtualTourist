//
//  GalleryController.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 9/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class GalleryController: UIViewController {
    
    var pinLocationImagesPage:Int?
    var referralPin:PinMO!
    
    @IBOutlet weak var detailedMapView: MKMapView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.Photo.entity)
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the collection
            fetchedResultsController?.delegate = photoCollectionView.delegate as? NSFetchedResultsControllerDelegate
            executeSearch()
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = referralPin.title
        let referralPinInMap = MKPointAnnotation()
        referralPinInMap.coordinate = CLLocationCoordinate2D(latitude: referralPin.latitude, longitude: referralPin.longitude)
        detailedMapView.addAnnotation(referralPinInMap)
        detailedMapView.setRegion(MKCoordinateRegion(center: referralPinInMap.coordinate, span: MKCoordinateSpan(latitudeDelta: 1.25, longitudeDelta: 1.25)), animated: true)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 5, left: 0, bottom: 8, right: 0)
        layout.itemSize = CGSize(width: (view.bounds.width / 3) - 8, height: (view.bounds.width / 3) - 8)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        photoCollectionView.collectionViewLayout = layout
        
        NotificationCenter.default.addObserver(forName: updateGalleryNotification, object: nil, queue: nil, using: galleryUpdate)
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Constants.CoreData.Photo.legend, ascending: true)]
        // Filtering only pictures for this album
        fetchRequest.predicate = NSPredicate(format: "pinId = %@", argumentArray: [referralPin])
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        if referralPin.photoId!.allObjects.isEmpty {
            loadPinImages(page: 1) // Initial load
        } else {
            pinLocationImagesPage = Int(referralPin.photoPages)
            refreshCollectionList(UIAvailability: (pinLocationImagesPage! > 0, referralPin.totalPhotos > 0))
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? FullScreenViewController else { return }
        guard let selectedCell = sender as? PhotoCollectionViewCell else { return }
        destination.fullImage = selectedCell.thumbNailImage.image
        destination.imageLegend = selectedCell.photoLegend
    }
    
    func galleryUpdate(notification: Notification) {
        guard let deletedId = notification.object as? PhotoMO else {
            print(Constants.ErrorMessages.noCellFound)
            return
        }
        photoRemoval(referralPhoto: deletedId)
    }
    
    @IBAction func newCollectionAction() {
        Singleton.sharedInstance.appCache.removeAllObjects()
        loadPinImages(page: Int(arc4random_uniform(UInt32(pinLocationImagesPage!))))
    }
    
    private func loadPinImages(page: Int) {
        
        photoRemoval()
        
        loadingView.alpha = 0.6
        view.bringSubview(toFront: loadingView)
        
        let getPhotosParameters:[String:AnyObject] = [
            Constants.ParameterKey.method: Constants.ParameterValue.method as AnyObject,
            Constants.ParameterKey.APIKey: Constants.ParameterValue.APIKey as AnyObject,
            Constants.ParameterKey.latitude: referralPin.latitude as AnyObject,
            Constants.ParameterKey.longitude: referralPin.longitude as AnyObject,
            Constants.ParameterKey.format: Constants.ParameterValue.format as AnyObject,
            Constants.ParameterKey.results: Constants.ParameterValue.results as AnyObject,
            Constants.ParameterKey.extra: Constants.ParameterValue.extra as AnyObject,
            Constants.ParameterKey.callback: Constants.ParameterValue.callback as AnyObject,
            Constants.ParameterKey.currentPage: page as AnyObject
        ]
        
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
                    self.executeSearch()
                }
            }
        })
    }
    
    private func setImagesSource(results: [String: Any]) -> (Bool, Bool) {
        guard let photos = results[Constants.JSONResponseKey.image] as? [[String: Any]] else { return (false, false) }
        if photos.count > 0 {
            let _ = photos.map {
                let sourceURL = $0[Constants.JSONResponseKey.sourceURL] as! String
                let legend = $0[Constants.JSONResponseKey.legend] as! String
                let addedPhoto = PhotoMO(sourceURL: sourceURL, legend: legend, context: fetchedResultsController!.managedObjectContext)
                addedPhoto.pinId = referralPin
            }
        }
        guard let pages = results[Constants.JSONResponseKey.pages] as? Int, let total = (results[Constants.JSONResponseKey.total] as? NSString)?.integerValue else { return (false, false) }
        pinLocationImagesPage = pages
        referralPin.setAlbumValues(photoPages: pages, totalPhotos: total)
        return (pages > 1, total > 0)
    }
    
    private func refreshCollectionList(UIAvailability: (Bool, Bool)) {
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0
            self.photoCollectionView.alpha = UIAvailability.1 ? 1 : 0
        }, completion: { _ in
            self.view.sendSubview(toBack: self.loadingView)
            self.newCollectionButton.isEnabled = UIAvailability.0
        })
    }
    
    private func photoRemoval(referralPhoto: PhotoMO? = nil) {
        if let photoDeleted = referralPhoto {
            stack.context.delete(photoDeleted)
        } else {
            do {
                let photosSaved = try stack.context.fetch(fetchRequest) as! [PhotoMO]
                let _ = photosSaved.map { stack.context.delete($0) }
            } catch {
                print(Constants.ErrorMessages.photoDeletion)
            }
        }
        stack.save() // commiting deletes
        executeSearch()
    }
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
                photoCollectionView.reloadData()
            } catch let e as NSError {
                print(Constants.ErrorMessages.searchHandler)
                print(e)
                print(fetchedResultsController?.description as Any)
            }
        }
    }
}

extension GalleryController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController?.object(at: indexPath) as! PhotoMO
        print(photo)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.photoCell, for: indexPath) as! PhotoCollectionViewCell
        cell.setPhoto(referralPhoto: photo)
        cell.setLongPressGesture(navigationController: navigationController!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: Constants.Storyboard.fullScreenSegue, sender: (collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell))
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController != nil ? fetchedResultsController!.sections!.count : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if let fetchedResults = fetchedResultsController, fetchedResults.sections![section].numberOfObjects > 0 {
//            return fetchedResults.sections![section].numberOfObjects
//        }
//        photoCollectionView.alpha = 0
//        return 0
        return fetchedResultsController != nil ? fetchedResultsController!.sections![section].numberOfObjects : 0
    }
}
