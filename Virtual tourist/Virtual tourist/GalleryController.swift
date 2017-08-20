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
        title = referralPin.title!
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
            refreshCollectionList(UIAvailability: (pinLocationImagesPage! > 1, referralPin.totalPhotos > 0))
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? FullScreenViewController else { return }
        guard let selectedCell = sender as? PhotoCollectionViewCell else { return }
        destination.fullImage = selectedCell.thumbNailImage.image
        destination.imageLegend = selectedCell.photoLegend
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil {
            // Saving in disk when going back to map
            stack.save()
        }
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
        // This is the number of pages this location returns
        let pagesForThisRequest = pinLocationImagesPage!
        // In here i choose the lesser of these couple of vales: 
        // 1. The number of pages the API tells me this location returns
        // 2. Flickr max return
        // I did a min between the two of them to prevent asking for a 
        // bigger value any given return may have (area with few pictures 
        // registered)
        // Finally i inserted + 1 in case 0 is returned by the random generator,
        // therefore the first page -1- should be provided for the request.
        let lowerPageAmount = min(pagesForThisRequest, maxPhotosRequest())
        loadPinImages(page: Int(arc4random_uniform(UInt32(lowerPageAmount))) + 1)
    }
    
    @IBAction func deleteCollectionAction(_ sender: Any) {
        print(fetchedResultsController?.fetchedObjects?.count as Any)
        photoRemoval()
        print(fetchedResultsController?.fetchedObjects?.count as Any)
    }
    
    private func loadPinImages(page: Int) {
        title = referralPin.title! + " - page: \(page)"
        photoRemoval()
        
        loadingView.alpha = 0.6
        view.bringSubview(toFront: loadingView)
        
        let getPhotosParameters:[String:AnyObject] = [
            Constants.ParameterKey.latitude: referralPin.latitude as AnyObject,
            Constants.ParameterKey.longitude: referralPin.longitude as AnyObject,
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
                guard let sourceURL = $0[Constants.JSONResponseKey.sourceURL] as? String else {
                    print("Problems with sourceURL in \($0)")
                    return
                }
                guard let legend = $0[Constants.JSONResponseKey.legend] as? String else {
                    print("Problems with legend in \($0)")
                    return
                }
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
            self.newCollectionButton.isEnabled = UIAvailability.0 && UIAvailability.1
        })
    }
    
    private func photoRemoval(referralPhoto: PhotoMO? = nil) {
        if let photoDeleted = referralPhoto {
            stack.context.delete(photoDeleted)
        } else {
            do {
                let savedPhotos = try stack.context.fetch(fetchRequest) as! [PhotoMO]
                var removalIndex = 0
                let _ = savedPhotos.map {
                    let indexPath = IndexPath(row: removalIndex, section: 0)
                    // deleting from DB
                    stack.context.delete($0)
                    removalIndex += 1
                    // cleaning network request
                    if let currentCell = photoCollectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
                        currentCell.cancelPhotoDownload()
                    }
                }
            } catch {
                print(Constants.ErrorMessages.photoDeletion)
            }
        }
        executeSearch()
    }
    
    // In here i return the calculation you asked me to do
    private func maxPhotosRequest() -> Int {
        let requestablePhotos = 4000 / Constants.ParameterValue.results
        return min(requestablePhotos, pinLocationImagesPage!)
    }
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
                photoCollectionView.reloadData()
            } catch let e as NSError {
                print(Constants.ErrorMessages.searchHandler, e)
                print(fetchedResultsController?.description as Any)
            }
        }
    }
}

extension GalleryController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController?.object(at: indexPath) as! PhotoMO
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.Storyboard.photoCell, for: indexPath) as! PhotoCollectionViewCell
        cell.thumbNailImage.image = nil
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
        return fetchedResultsController != nil ? fetchedResultsController!.sections![section].numberOfObjects : 0
    }
}
