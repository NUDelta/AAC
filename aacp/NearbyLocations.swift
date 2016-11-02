//
//  NearbyLocations.swift
//  aacp
//
//  Created by Jennie Werner on 10/30/16.
//  Copyright © 2016 Jennie Werner. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase
import GooglePlaces

class NearbyLocations{
    
    let ACCURACY = 0.02
    var ref: FIRDatabaseReference! = FIRDatabase.database().reference()
    var GooglePlacesClient: GMSPlacesClient? = GMSPlacesClient.shared()
    
    
    func getGoogleLocations(curr_location:CLLocation, completion: @escaping (_ locations: [(String, [String])])-> Void){
        GooglePlacesClient!.currentPlace(callback: { (placeLikelihoods, error) -> Void in
            guard error == nil else {
                print("Current Place error: \(error!.localizedDescription)")
                return
            }
            
            var all_places : [(String, [String])] = []
            if let placeLikelihoods = placeLikelihoods {
                for likelihood in placeLikelihoods.likelihoods {
                    let place = likelihood.place
                    
                    if likelihood.likelihood > 0.095 {
                        all_places.append((place.name, place.types))
                    }
                }
                completion(all_places)
            }
        })
    }
    
    var local_affordances : [String] = []
    
    func getLocalLocations(curr_location:CLLocation, completion: @escaping (_ local_affordances : [String])-> Void){
        let variance = ACCURACY
        let latitude = curr_location.coordinate.latitude
        
        self.ref.child("campus_location").queryOrdered(byChild:"lat").queryStarting(atValue: (latitude-variance), childKey: "lat").queryEnding(atValue:(latitude+variance), childKey:"lat").observeSingleEvent(of: .value, with: {
            Snapshot in
            
            var queried_locations : [String] = []
            if let snapDict = Snapshot.value as? [String:AnyObject]{
                
                for child in snapDict{
                    let obj_location = CLLocation(latitude: child.value["lat"] as! Double, longitude: child.value["long"] as! Double)
                    
                    let diff = curr_location.distance(from: obj_location)
                    
                    print(diff, child.value["name"] as! String)
                    
                    if(diff < 2 ){
                        //we have found a location we are near!
                        queried_locations.append(child.value["name"] as! String)
                    }
                }
            }
            print("LOCATIONS", queried_locations)
            completion(queried_locations)
        })
    }
    

    
    func makeIterable(tuple: Any) -> AnyIterator<Any> {
        return AnyIterator(Mirror(reflecting: tuple).children.lazy.map { $0.value }.makeIterator())
    }
    
    func getAffordances(location_name: String, completion: @escaping (_ affordances : [String])-> Void){
        var curr_affordances : [String] = []
        self.ref.child("obj_affordances").queryOrderedByKey().queryEqual(toValue: location_name).observeSingleEvent(of: .value, with: {
            Snapshot in
            if let snapDict = Snapshot.value as? [String:AnyObject]{
                print(snapDict)
                for child in snapDict{
                    for v in self.makeIterable(tuple: child.value){
                        curr_affordances.append(v as! String)
                    }
                }
            }
            print("OUR AFFORDANCES", curr_affordances)
            completion(curr_affordances)
        })
    }


    
}
