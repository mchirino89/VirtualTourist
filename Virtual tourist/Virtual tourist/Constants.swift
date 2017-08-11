//
//  Constants.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 9/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

struct Constants {
    
    struct APIConfiguration {
        static let ApiScheme = "https"
        // MARK: API Key
        static let ApiKey = "565d9aa439a0e3b91a2be9ad89b2b9e6"
        static let ApiSecret = "765dc3b8f259d3ff"
    }
    
    struct ParameterKey {
        static let method = "method"
        static let APIKey = "api_key"
        static let latitud = "lat"
        static let longitude = "lon"
        static let extra = "extras"
        static let results = "per_page"
        static let format = "format"
        static let callback = "nojsoncallback"
    }
    
    struct ParameterValue {
        static let method = "flickr.photos.search"
        static let APIKey = "f78755583fac5d9ece56b77eb3dd331e"
        static let extra = "url_m"
        static let results = 25
        static let format = "json"
        static let callback = 1
    }
    
    struct URL {
        static let host = "api.flickr.com"
        static let path = "/services/rest/"
    }
    
    struct Storyboard {
        static let locationSegue = "locationSegue"
        static let photoCell = "photoCell"
    }
    
    struct UIElements {
        static let mapPinId = "pin"
    }
    
    struct ErrorMessages {
        static let credentials = "These credentials don't look right. Make sure you entered the corrects ones and try again please."
        static let internetConnection = "It seems you don't have an active internet connection right now. Make sure you do before you try again please"
        static let parsingJSON = "Could not parse the data as JSON: "
        static let noData = "No data was returned by the request!"
        static let noSuccess = "Your request returned a status code other than 2xx!"
        static let generic = "There was an error with your request: "
        static let popupTitle = "Oops!"
        static let popupButton = "Ok"
    }
    
    struct UIMessages {
        static let affirmative = "Yes"
        static let negative = "No"
        static let logout = "Log out"
        static let appTitle = "On the map"
        static let locationPermission = "Using your device's GPS, the app can get your current location for you. May it proceed?"
    }
}
