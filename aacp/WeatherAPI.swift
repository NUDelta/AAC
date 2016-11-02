//
//  WeatherAPI.swift
//  aacp
//
//  Created by Jennie Werner on 10/30/16.
//  Copyright © 2016 Jennie Werner. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation

class WeatherAPI{
    
    private let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5/weather"
    private let openWeatherMapAPIKey = "584a4f2cedd66fd2376b0a8f124e8fdb"
    
    func convertToType(weather:String)->String{
        if (weather.range(of:"cloud") != nil){
            return "cloudy"
        }else if (weather.range(of:"snow") != nil) || (weather.range(of:"sleet") != nil){
            return "snowy"
        }else if (weather.range(of:"rain") != nil) || (weather.range(of:"drizzle") != nil){
            return "rainy"
        }else if (weather.range(of:"clear") != nil){
            return "clear"
        }else if (weather.range(of:"breeze") != nil){
            return "windy"
        }else{
            return "other"
        }
        
    }
    
    // TODO: Add windy as a possible condition
    func getWeather(coord: CLLocation, completion: @escaping (_ description: String)->Void ){
        let lat = coord.coordinate.latitude
        let lon = coord.coordinate.longitude
        // This is a pretty simple networking task, so the shared session will do.
        let URLstring = "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&lat=\(lat)&lon=\(lon)"
        let weatherRequestURL = URLRequest(url: URL(string:URLstring)!)
        let session = URLSession.shared.dataTask(with: weatherRequestURL){
            (data, response, error) in
            
            if let error = error {
                // Case 1: Error
                // We got some kind of error while trying to get data from the server.
                print("Error:\n\(error)")
                completion("error")
            }
            else {
                // Case 2: Success
                // We got a response from the server!
                    
                let json = JSON(data: data!)
                    let weather = json["weather"][0]["description"]
                    let weather_string = "\(weather)"
                    let type = self.convertToType(weather: weather_string)
                    completion(type)


                    // If we made it to this point, we've successfully converted the
                    // JSON-formatted weather data into a Swift dictionary.
                    // Let's print its contents to the debug console.
            }
        }
        
        // The data task is set up...launch it!
        session.resume()

    }
    
}
