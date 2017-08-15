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
    
    var locationManager = CLLocationManager()
    let addressDecoder = CLGeocoder()
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes
            func executeSearch() {
                if let fc = fetchedResultsController {
                    do {
                        try fc.performFetch()
                    } catch let e as NSError {
                        print(Constants.ErrorMessages.handlerError)
                        print(e)
                        print(fetchedResultsController?.description as Any)
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var mainMapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = 30
        locationManager.requestWhenInUseAuthorization()
        let pinDropLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.addPinToMap(gesture:)))
        pinDropLongPressGesture.minimumPressDuration = 0.35
        touristMapView.addGestureRecognizer(pinDropLongPressGesture)
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: Constants.CoreData.Pin.entity)
        fr.sortDescriptors = [NSSortDescriptor(key: Constants.CoreData.Pin.creation, ascending: true)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            let pinsSaved = try stack.context.fetch(fr) as! [PinMO]
            deletePinButton.isEnabled = !pinsSaved.isEmpty
            let _ = pinsSaved.map {
                let singlePin = $0
                let _ = setPinInfo(coordinate: CLLocationCoordinate2D(latitude: singlePin.latitude, longitude: singlePin.longitude), title: singlePin.title, subtitle: singlePin.subtitle, identifier: nil)
            }
        } catch {
            print(Constants.ErrorMessages.pinCoreDataReading)
        }
    }
    
    func addPinToMap(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            
            let pin = setPinInfo(coordinate: touristMapView.convert(gesture.location(in: touristMapView), toCoordinateFrom: touristMapView), title: nil, subtitle: Date().description, identifier: Date().timeIntervalSince1970.description)
            
            addressDecoder.reverseGeocodeLocation(CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude), completionHandler: {
                    [unowned self] (result, error) in
                guard let address = result else { return }
                let matchedPin = self.mainMapView.annotations.filter {
                    !$0.isKind(of: MKUserLocation.self) && ($0 as! DropPinAnnotationView).locationIdentifier == pin.locationIdentifier!
                }
                let title = address[0].locality ?? address[0].areasOfInterest!.first ?? address[0].name
                (matchedPin[0] as! DropPinAnnotationView).title = title
                let persistentPin = PinMO(title: title!, subtitle: pin.subtitle!, latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude, creation: pin.creationDate, context: self.fetchedResultsController!.managedObjectContext)
                self.deletePinButton.isEnabled = true
                print(persistentPin)
            })
            
        }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedPin = sender as! DropPinAnnotationView
        let detailedView = segue.destination as! GalleryController
        detailedView.locationIdentifier = selectedPin.locationIdentifier
        detailedView.locationName = selectedPin.title
        detailedView.locationCoordinates = selectedPin.coordinate
    }
    
    @IBAction func deletePinAction(_ sender: Any) {
        navigationController?.present(questionPopup(title: Constants.UIMessages.deletePinsTitle, message: Constants.UIMessages.deletePinsMessage, style: .alert, afirmativeAction: { [unowned self] _ in
            do {
                self.touristMapView.removeAnnotations(self.touristMapView.annotations)
                try self.stack.dropAllData()
            } catch {
                print(Constants.ErrorMessages.pinRemovalError)
            }
        }), animated: true)
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
                pinView!.pinTintColor = .red
                pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                pinView!.annotation = annotation
            }
            return pinView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegue(withIdentifier: Constants.Storyboard.locationSegue, sender: view.annotation as! DropPinAnnotationView)
    }
    
}

extension MapController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
    
}
