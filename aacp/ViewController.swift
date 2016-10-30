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

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var ACCURACY = 0.00005
    var ref: FIRDatabaseReference!
    var locationManager: CLLocationManager!
    var GooglePlacesClient: GMSPlacesClient?

    
    var nearby_locations : [String] = []
    var nearby_affordances : [String] = []
    var nearby_games : [String] = []
    @IBOutlet weak var nearby_affordances_label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Initalize DB
        ref = FIRDatabase.database().reference()
        
        //Set Up Location Manager
        locationManager = CLLocationManager();
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
       // self.ref.child("games").setValue(["sit": ["Find a place to sit and people watch, who is the most interesting person you see?", "Get someone around you to plank (#tbt). and upload a pic of them doing it!"]])
        
        GooglePlacesClient = GMSPlacesClient.shared()

        
    }
    
    
 
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(nearby_locations)
        let location = manager.location
        self.ref.child("location").setValue(["curr_lat": location!.coordinate.latitude, "curr_long": location!.coordinate.longitude])
        getLocations(curr_location: location!)
        getAffordances()
        getGames()
        
        var affString : String = ""
        for a in nearby_affordances{
            affString = affString + a + "\n"
        }
        nearby_affordances_label.text = affString
        
        var gameString : String
        if(nearby_games.count > 0){
            gameString = nearby_games[0]
        }else{
            gameString = "No games nearby, keep exploring!"
        }
    }
    
    func getGames(){
        for aff in nearby_affordances{
            self.ref.child("games").queryOrderedByKey().queryEqual(toValue: aff).observeSingleEvent(of: .value, with: {
                Snapshot in
                if let snapDict = Snapshot.value as? [String:AnyObject]{
                    for child in snapDict{
                        for v in self.makeIterable(tuple: child.value){
                            self.addToArray(given_array: &self.nearby_games, toAdd: v as! String)
                        }
                    }
                }
            })
        }
        
    }

    func addToArray(given_array: inout [String], toAdd:String){
        if given_array.count > 3 {
            given_array.remove(at: 0)
        }
        if(!(given_array.contains(toAdd))){
            given_array.append(toAdd)
        }
        
    }
    
    func makeIterable(tuple: Any) -> AnyIterator<Any> {
        return AnyIterator(Mirror(reflecting: tuple).children.lazy.map { $0.value }.makeIterator())
    }
    
    
    @IBOutlet weak var google_places_label: UILabel!
    @IBAction func getPlaces() {
        GooglePlacesClient!.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            guard error == nil else {
                print("Current Place error: \(error!.localizedDescription)")
                return
            }
            var output = ""
            if let placeLikelihoods = placeLikelihoods {
                for likelihood in placeLikelihoods.likelihoods {
                    let place = likelihood.place
                    output = output + "\(place.name) at \(likelihood.likelihood) \n"
                    print(output)
                    self.google_places_label.text! = output
                    
                }
            }
        })    }
    
    func getLocations(curr_location:CLLocation){
        let variance = ACCURACY
        let latitude = curr_location.coordinate.latitude
        let longitude = curr_location.coordinate.longitude
        
        
        self.ref.child("campus_location").queryOrdered(byChild:"lat").queryStarting(atValue: (latitude-variance), childKey: "lat").queryEnding(atValue:(latitude+variance), childKey:"lat").observeSingleEvent(of: .value, with: {
                Snapshot in
            if let snapDict = Snapshot.value as? [String:AnyObject]{
                if(snapDict.count < 1){
                    self.nearby_locations = []
                }
                
                for child in snapDict{
                    let snap_long = child.value["long"] as! Double
                    let obj_location = CLLocation(latitude: child.value["lat"] as! Double, longitude: child.value["long"] as! Double)
                    print(obj_location)
                    print(curr_location)
                    let diff = curr_location.distance(from: obj_location)
                    print(diff, child.value["name"] as! String)
                    if(diff < 2 ){
                        //we have found a location we are near!
                        self.addToArray(given_array: &self.nearby_locations, toAdd: child.value["name"] as! String)
                    }
                }
            }
        })
    }
    
    
    func getAffordances(){
        for object in nearby_locations{
            self.ref.child("affordances").queryOrderedByKey().queryEqual(toValue: object).observeSingleEvent(of: .value, with: {
                Snapshot in
                if let snapDict = Snapshot.value as? [String:AnyObject]{
                    for child in snapDict{
                        for v in self.makeIterable(tuple: child.value){
                            self.addToArray(given_array: &self.nearby_affordances, toAdd: v as! String)
                        }
                    }
                }
            })
        }
    }
    
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    

}

