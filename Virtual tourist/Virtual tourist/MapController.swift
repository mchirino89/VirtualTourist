//
//  ViewController.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 8/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class MapController: UIViewController {
    
    @IBOutlet weak var touristMapView: MKMapView!
    @IBOutlet weak var deletePinButton: UIBarButtonItem!
    @IBOutlet weak var mainMapView: MKMapView!
    
    let addressDecoder = CLGeocoder()
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.Pin.entity)
    var locationManager = CLLocationManager()
    var pinIdentifier:String?
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes
            func executeSearch() {
                if let fc = fetchedResultsController {
                    do {
                        try fc.performFetch()
                    } catch let e as NSError {
                        print(Constants.ErrorMessages.searchHandler)
                        print(e)
                        print(fetchedResultsController?.description as Any)
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = 30
        locationManager.requestWhenInUseAuthorization()
        let pinDropLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.addPinToMap(gesture:)))
        pinDropLongPressGesture.minimumPressDuration = 0.35
        touristMapView.addGestureRecognizer(pinDropLongPressGesture)
        
        // Configure a FetchRequest
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Constants.CoreData.Pin.creation, ascending: true)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        navigationItem.titleView = getCustomTitle(viewTitle: Constants.UIElements.title)
    }
    
    func addPinToMap(gesture: UILongPressGestureRecognizer) {
        var pin:DropPinAnnotationView?
        switch gesture.state {
        case .began:
            pinIdentifier = Date().timeIntervalSince1970.description
            pin = setPinInfo(coordinate: touristMapView.convert(gesture.location(in: touristMapView), toCoordinateFrom: touristMapView), title: nil, subtitle: Date().description, identifier: pinIdentifier!)
            break
        case .changed:
            pin = getPinById(identifier: pinIdentifier!)
            pin!.coordinate = touristMapView.convert(gesture.location(in: touristMapView), toCoordinateFrom: touristMapView)
            break
        case .ended:
            pin = getPinById(identifier: pinIdentifier!)
            addressDecoder.reverseGeocodeLocation(CLLocation(latitude: pin!.coordinate.latitude, longitude: pin!.coordinate.longitude), completionHandler: {
                [unowned self] (result, error) in
                guard let address = result else { return }
                let matchedPin = self.getPinById(identifier: pin!.locationIdentifier!)
                let pinTitle = address[0].locality ?? address[0].name
                matchedPin!.title = pinTitle
                let _ = PinMO(identifier: pin!.locationIdentifier!, title: pinTitle!, subtitle: pin!.subtitle!, latitude: pin!.coordinate.latitude, longitude: pin!.coordinate.longitude, creation: pin!.creationDate, context: self.fetchedResultsController!.managedObjectContext)
            })
            deletePinButton.isEnabled = true
            break
        default:
            break
        }
    }
    
    private func getPinById(identifier: String) -> DropPinAnnotationView? {
        return touristMapView.annotations.first(where: { ($0 as? DropPinAnnotationView)?.locationIdentifier == identifier}) as? DropPinAnnotationView
    }
    
    private func setPinInfo(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, identifier: String?) -> DropPinAnnotationView {
        let pin = DropPinAnnotationView()
        pin.title = title
        pin.subtitle = subtitle ?? pin.creationDate.description
        pin.coordinate = coordinate
        // Used for filtering Pins in map and direction naming afterwards
        pin.locationIdentifier = identifier ?? pin.creationDate.timeIntervalSince1970.description
        touristMapView.addAnnotation(pin)
        return pin
    }
    
    func loadSavedPins() {
        do {
            let pinsSaved = try stack.context.fetch(fetchRequest) as! [PinMO]
            deletePinButton.isEnabled = !pinsSaved.isEmpty
            let _ = pinsSaved.map {
                let singlePin = $0
                let _ = setPinInfo(coordinate: CLLocationCoordinate2D(latitude: singlePin.latitude, longitude: singlePin.longitude), title: singlePin.title, subtitle: singlePin.subtitle, identifier: singlePin.identifier)
            }
        } catch {
            print(Constants.ErrorMessages.pinCoreDataReading)
        }
    }
    
    func getSelectedPin(referralPin: DropPinAnnotationView) -> PinMO? {
        do {
            let pinsSaved = try stack.context.fetch(fetchRequest) as! [PinMO]
            return pinsSaved.first(where: { $0.identifier! == referralPin.locationIdentifier! })
        } catch {
            print(Constants.ErrorMessages.pinCoreDataReading)
            return nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailedView = segue.destination as! GalleryController
        detailedView.referralPin = sender as? PinMO
    }
    
    @IBAction func deletePinAction(_ sender: Any) {
        navigationController?.present(questionPopup(
            title: Constants.UIMessages.deletePinsTitle,
            message: Constants.UIMessages.deletePinsMessage,
            style: .alert,
            afirmativeAction: {
                [unowned self] _ in
                do {
                    self.touristMapView.removeAnnotations(self.touristMapView.annotations)
                    try self.stack.dropAllData()
                } catch {
                    print(Constants.ErrorMessages.pinRemoval)
                }
            }
        ), animated: true)
    }
}

extension MapController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKUserLocation) {
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.UIElements.mapPinId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.UIElements.mapPinId)
                pinView!.animatesDrop = true
                pinView!.canShowCallout = true
                pinView!.pinTintColor = .blue
                pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                pinView!.annotation = annotation
            }
            return pinView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let selectedPinInMap = view.annotation as! DropPinAnnotationView
        performSegue(withIdentifier: Constants.Storyboard.locationSegue, sender: getSelectedPin(referralPin: selectedPinInMap))
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if mapView.annotations.isEmpty {
            loadSavedPins()
        }
    }
    
}

extension MapController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    
}
