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
    
    
    struct Conditions {
        var hours = NSCalendar.current.component(.hour, from:  Date() as Date)
        var minutes = NSCalendar.current.component(.minute, from: Date() as Date)
        var weather = "unknown"
        var nearby_affordances : [String] = []
        var played_games : [String] = []
    }
    
    //global master struct
    var current_conditions = Conditions()
    
    var ref: FIRDatabaseReference!
    var locationManager: CLLocationManager!
    
    
    @IBOutlet weak var nearby_affordances_label: UILabel!
    
    @IBOutlet weak var weather_label: UILabel!
    
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
        //self.ref.child("obj_affordances").setValue(["Lakefill": ["hug", "observe", "smell", "feel"], "Technological Institute" : ["write", "sit"]])
        //self.ref.child("campus_locations").setValue(["Technological Institute": ["classroom"], "Lakefill" :["trees"]])
        
        WeatherAPI().getWeather(coord: locationManager.location!,completion:{(description:String) -> Void in
            DispatchQueue.main.async {
                self.weather_label.text = description
                self.current_conditions.weather = description
            }
        })
    }
    
    
    var all_locations : [String] = ["no"]
    var gameText : String = "no games yet"
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.nearby_affordances_label.text = String(describing: current_conditions)
        self.weather_label.text = gameText
        
        lookForGames()
        print("Current Conditions ---------")
        print(current_conditions)
        
        let location = manager.location
        
        self.ref.child("location").setValue(["curr_lat": location!.coordinate.latitude, "curr_long": location!.coordinate.longitude])
        
        NearbyLocations().getLocalLocations(curr_location: location!, completion:{(locations:[String]) -> Void in DispatchQueue.main.async {
            self.all_locations = locations
            }
        })
        
        for loc in all_locations{
            NearbyLocations().getAffordances(location_name: loc, completion:{(affordances:[String]) -> Void in DispatchQueue.main.async {
                for a in affordances{
                    self.addToArray(given_array: &self.current_conditions.nearby_affordances, toAdd: a)
                }
                }
            })
        }
        
        NearbyLocations().getGoogleLocations(curr_location: location!, completion: {(locations: [(String, [String])]) -> Void in
            for occurance in locations{
                for a in occurance.1{
                    self.addToArray(given_array: &self.current_conditions.nearby_affordances, toAdd: a)
                }
            }
        })
        
    }
    
    func lookForGames(){
        current_conditions.weather = "rainy"
        current_conditions.hours = 12
        
        self.ref.child("games").queryOrdered(byChild: "weather").queryEqual(toValue: "rainy").observeSingleEvent(of: .value, with: {
            Snapshot in
            if let snapDict = Snapshot.value as? [String: AnyObject]{
                for child in snapDict{
                    if(!(((child.value["start_time"] as! Int) <= self.current_conditions.hours) &&  ((child.value["end_time"] as! Int) >= self.current_conditions.hours))){
                        break
                    }else if !(self.current_conditions.nearby_affordances.contains(child.value["affordances"] as! String)){
                        break
                    }
                    
                    self.gameText = String(describing: child)
                    print("FOUND A GAME", child)
                    
                }
            }
            
        })
    }
    
    
    /*
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
     */
    
    func addToArray(given_array: inout [String], toAdd:String){
        if(!(given_array.contains(toAdd))){
            given_array.append(toAdd)
        }
        
    }
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
}

