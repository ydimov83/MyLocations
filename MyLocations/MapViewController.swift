//
//  MapViewController.swift
//  MyLocations
//
//  Created by Yavor Dimov on 3/5/19.
//  Copyright © 2019 Yavor Dimov. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            //As soon as managedObjectContext gets a value, which happens at app launch through AppDelegate implementation, this bloc will execute and thus actively listen to changes in data store
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                object: managedObjectContext,
                queue: OperationQueue.main) { notification in
                if self.isViewLoaded {
                    //We only want to update locations once the map view is already loaded
                    self.updateLocations()
                }
            }
        }
    }
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
        if !locations.isEmpty {
            showLocations()
        }
    }
    
    //MARK: - Actions
    @IBAction func showUser() {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate,
                                        latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func showLocations() {
        let theRegion = region(for: locations)
        mapView.setRegion(theRegion, animated: true)
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
    
    //MARK: - Helper Methods
    func updateLocations() {
        mapView.removeAnnotations(locations)
        let entity = Location.entity()
        
        let fetchRequest = NSFetchRequest<Location>()
        fetchRequest.entity = entity
        
        locations = try! managedObjectContext.fetch(fetchRequest)
        mapView.addAnnotations(locations)
    }
    
    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
        let region: MKCoordinateRegion
        
        switch  annotations.count {
        case 0:
            region = MKCoordinateRegion(center: mapView.userLocation.coordinate,
                                        latitudinalMeters: 1000, longitudinalMeters: 1000)
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegion(center: annotation.coordinate,
                                        latitudinalMeters: 1000, longitudinalMeters: 1000)
        default:
            //Default case will try to create a region that can encompass all the users saved locations
            var topLeft = CLLocationCoordinate2DMake(-90, 180)
            var bottomRight = CLLocationCoordinate2DMake(90, -180)
            
            for annotation in annotations {
                topLeft.latitude = max(topLeft.latitude, annotation.coordinate.latitude)
                topLeft.longitude = min(topLeft.longitude, annotation.coordinate.longitude)
                bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
                bottomRight.longitude = max(bottomRight.longitude, annotation.coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(
                latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude),
                longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude))
            
            let extraSpace = 1.1
            let span = MKCoordinateSpan(
                latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
            
            region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
    }
    
    @objc func showLocationDetails(_ sender: UIButton) {
        performSegue(withIdentifier: "EditLocation", sender: sender)
    }
    
}
//MARK: - MKMapView Delegate extension
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard annotation is Location else {
            //Guard check here ensures that we only perform the following operations if the annotation is of type Location. For example, blue dot representing user will not be of type Location so we want to quit out of this function if that's the case
            return nil
        }
        
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            pinView.isEnabled = true
            pinView.canShowCallout = true
            pinView.animatesDrop = false
            pinView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            pinView.tintColor = UIColor(white: 0.0, alpha: 0.5)
            
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self, action: #selector(showLocationDetails(_:)), for: .touchUpInside)
            
            pinView.rightCalloutAccessoryView = rightButton
            
            annotationView = pinView
        }
        
        if let annotationView = annotationView {
            annotationView.annotation = annotation
            
            let button = annotationView.rightCalloutAccessoryView as! UIButton
            if let index = locations.index(of: annotation as! Location) {
                button.tag = index
            }
        }
        
        return annotationView
    }
}
