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
    var locationManager = CLLocationManager()
    let addressDecoder = CLGeocoder()
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes
            func executeSearch() {
                if let fc = fetchedResultsController {
                    do {
                        try fc.performFetch()
                    } catch let e as NSError {
                        print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
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
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "creation", ascending: true)]
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            let pinsSaved = try stack.context.fetch(fr)
            let _ = pinsSaved.map {
                let singlePin = $0 as! PinMO
                let _ = setPinInfo(coordinate: CLLocationCoordinate2D(latitude: singlePin.latitude, longitude: singlePin.longitude), title: singlePin.title, subtitle: singlePin.subtitle, identifier: nil)
            }
            
        } catch {
            print("Error printing when returning")
        }
        
        // MARK: Testing purposes
        
//        let testPin = DropPinAnnotationView()
//        testPin.locationIdentifier = "12343567"
//        testPin.title = "Pirineos 2"
//        testPin.coordinate = CLLocationCoordinate2D(latitude: 7.773, longitude: -72.20238)
//        performSegue(withIdentifier: Constants.Storyboard.locationSegue, sender: testPin)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
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
                let title = address[0].locality ?? address[0].name ?? address[0].areasOfInterest!.first
                (matchedPin[0] as! DropPinAnnotationView).title = title
                let persistentPin = PinMO(title: title!, subtitle: pin.subtitle!, latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude, creation: pin.creationDate, context: self.fetchedResultsController!.managedObjectContext)
                print("Created: ", persistentPin)
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case CLAuthorizationStatus.restricted:
            break
        case CLAuthorizationStatus.denied:
            break
        case CLAuthorizationStatus.notDetermined:
            break
        default:
            break
        }
    }
    
}
