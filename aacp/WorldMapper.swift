//
//  ViewController.swift
//  aacp
//
//  Created by Jennie Werner on 10/7/16.
//  Copyright © 2016 Jennie Werner. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import GooglePlaces

class WorldMapper: UIViewController, CLLocationManagerDelegate {
    
    var ref: FIRDatabaseReference!
    var locationManager: CLLocationManager!
    var placesClient: GMSPlacesClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient.shared()
        ref = FIRDatabase.database().reference()
        locationManager = CLLocationManager();
    }
        
    
    @IBAction func recordLocations(_ sender: UIButton) {
        let long = (locationManager.location?.coordinate.longitude)! as Double
        let lat = (locationManager.location?.coordinate.latitude)! as Double
        let obj_name = sender.titleLabel!.text! as String
        print(long, lat, obj_name)
        
        self.ref.child("campus_location").child(UUID().uuidString).setValue(
            ["long": long, "lat": lat, "name": obj_name])
    }
    
    
    @IBOutlet weak var placesText: UILabel!
    
    @IBAction func googlePlacesAPI(_ sender: UIButton) {
        placesClient!.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            guard error == nil else {
                print("Current Place error: \(error!.localizedDescription)")
                return
            }
            var output = ""
            if let placeLikelihoods = placeLikelihoods {
                for likelihood in placeLikelihoods.likelihoods {
                    let place = likelihood.place
                    output = output + "\n\(place.name) at \(likelihood.likelihood)"
                    self.placesText.text! = output
                    
                }
            }
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

