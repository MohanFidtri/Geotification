//
//  ViewController.swift
//  Geotification
//
//  Created by prakash on 12/2/22.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate
{

    //MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var entryLblTxt: UILabel!
    @IBOutlet weak var exitLblTxt: UILabel!
    
    //MARK: - Var Declaration
    var locationManager : CLLocationManager = CLLocationManager()
    var filePath:String?
    var authorizationStatus: CLAuthorizationStatus?
    
    
    //MARK: - View Methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        loadInitalDataForFencing()
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkForLocationPermission()
    }
    
    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion)
    {
        entryLblTxt.text = "enter \(region.identifier)"
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {

        exitLblTxt.text = "exit \(region.identifier)"
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location = locations[0] as CLLocation
        
        self.getAddressFromLocation(loc: location)
        
        let reg = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)

        self.mapView.setRegion(reg, animated: true)

        self.mapView.showsUserLocation = true
    }
    
    // MARK: - Helpers
    
    func showAlert(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)

    }
    
    //MARK: Other Methods
    
    fileprivate func checkForLocationPermission()
    {
        if #available(iOS 14, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        
        switch authorizationStatus
        {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted, .authorizedWhenInUse, .none:
            showAlert("Location services were previously denied. Please enable location services for this app in Settings.")
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            showAlert("Location services were previously denied. Please enable location services for this app in Settings.")
        }
    }
    
    fileprivate func loadInitalDataForFencing() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        filePath = getFilePath(fileName: "LocationsForSimulation")
        
        DispatchQueue.global(qos: .background).async
        {
            self.setupLocationGPXData()
        }
    }
    
    
    fileprivate func getAddressFromLocation(loc : CLLocation)
    {
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(loc, completionHandler:
                                            {(placemarks, error) in
            if (error != nil)
            {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            else
            {
                let locationPlaceMark = placemarks! as [CLPlacemark]
                
                if locationPlaceMark.count > 0 {
                    let pm = placemarks![0]
                    var addressString : String = ""
                    if pm.subLocality != nil {
                        addressString = addressString + pm.subLocality! + ", "
                    }
                    if pm.thoroughfare != nil {
                        addressString = addressString + pm.thoroughfare! + ", "
                    }
                    if pm.locality != nil {
                        addressString = addressString + pm.locality! + ", "
                    }
                    if pm.country != nil {
                        addressString = addressString + pm.country! + ", "
                    }
                    if pm.postalCode != nil {
                        addressString = addressString + pm.postalCode! + " "
                    }
                    
                    
                    self.addressLbl.text = addressString
                }
            }
            
        })
        
    }
    
    fileprivate func getFilePath(fileName: String) -> String? {
           //Generate a computer readable path
        return Bundle.main.path(forResource: fileName, ofType: "gpx")
       }
    
    fileprivate func setupLocationGPXData() {
        // check if can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {


            if let Coordinates2dMakeArr = Parser().parseCoordinates(fromGpxFile: filePath!)
            {
              //  debugPrint(Coordinates2dMakeArr)

                for coordinates in Coordinates2dMakeArr
                {
                    // region data
                    let title = "Location #\(coordinates.latitude)"
                    let coordinate = coordinates
                    let regionRadius = 500.0

                    // setup region
                    let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                        longitude: coordinate.longitude), radius: regionRadius, identifier: title)
                    locationManager.startMonitoring(for: region)


                    // setup annotation
                    let restaurantAnnotation = MKPointAnnotation()
                    restaurantAnnotation.coordinate = coordinate;
                    restaurantAnnotation.title = "\(title)";

                    // setup circle
                    let circle = MKCircle(center: coordinate, radius: regionRadius)

                    DispatchQueue.main.async {

                        self.mapView.addAnnotation(restaurantAnnotation)

                        self.mapView.addOverlay(circle)

                    }

                }
            }
        }
        else {
            print("System can't track regions")
        }
    }
 
}
