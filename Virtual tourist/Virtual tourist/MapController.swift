//
//  ViewController.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 8/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapController: UIViewController {
    
    @IBOutlet weak var touristMapView: MKMapView!
    var locationManager = CLLocationManager()
    let addressDecoder = CLGeocoder()
    
    @IBOutlet weak var mainMapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = 30
        locationManager.requestWhenInUseAuthorization()
        let pinDropLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.addPinToMap(gesture:)))
        pinDropLongPressGesture.minimumPressDuration = 0.35
        touristMapView.addGestureRecognizer(pinDropLongPressGesture)
        
        // MARK: Testing purposes
        
        let testPin = DropPinAnnotationView()
        testPin.locationIdentifier = "12343567"
        testPin.title = "Pirineos 2"
        testPin.coordinate = CLLocationCoordinate2D(latitude: 7.773, longitude: -72.20238)
        performSegue(withIdentifier: Constants.Storyboard.locationSegue, sender: testPin)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func addPinToMap(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let pin = DropPinAnnotationView()
            pin.coordinate = touristMapView.convert(gesture.location(in: touristMapView), toCoordinateFrom: touristMapView)
            pin.subtitle = Date().description
            pin.locationIdentifier = Date().timeIntervalSince1970.description
            addressDecoder.reverseGeocodeLocation(CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude), completionHandler: {
                    [unowned self] (result, error) in
                guard let address = result else { return }
                let matchedPin = self.mainMapView.annotations.filter({
                    !$0.isKind(of: MKUserLocation.self) && ($0 as! DropPinAnnotationView).locationIdentifier! == pin.locationIdentifier!
                })
                (matchedPin[0] as! DropPinAnnotationView).title = address[0].locality ?? address[0].name!
            })
            touristMapView.addAnnotation(pin)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedPin = sender as! DropPinAnnotationView
        let detailedView = segue.destination as! LocationController
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
