//
//  Constants.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 9/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit

struct Constants {
    
    struct APIConfiguration {
        static let ApiScheme = "https"
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
        static let currentPage = "page"
    }
    
    struct ParameterValue {
        static let method = "flickr.photos.search"
        static let APIKey = "565d9aa439a0e3b91a2be9ad89b2b9e6"
        static let extra = "url_m"
        static let results = 24
        static let format = "json"
        static let callback = 1
    }
    
    struct JSONResponseKey {
        static let total = "total"
        static let photos = "photos"
        static let image = "photo"
        static let pages = "pages"
        static let photoId = "id"
        static let sourceURL = "url_m"
        static let legend = "title"
    }
    
    struct photoPath {
        static let farm = "farm"
        static let host = "staticflickr.com"
        static let server = "server"
        static let id = "id"
        static let secret = "secret"
    }
    
    struct URL {
        static let FlickrServer = "api.flickr.com"
        static let APIpath = "/services/rest/"
    }
    
    struct Storyboard {
        static let locationSegue = "locationSegue"
        static let photoCell = "photoCell"
        static let fullScreenSegue = "fullImageSegue"
    }
    
    struct UIElements {
        static let mapPinId = "pin"
        static let customTitleFont = "MarkerFelt-Thin"
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
        static let mapTitle = "Tourism map"
        static let affirmative = "Yes"
        static let negative = "No"
        static let deletePictureTitle = "Delete picture"
        static let deletePictureMessage = "Are you sure you want to delete this picture from this album's location?"
    }
}

func getCustomTitle(viewTitle: String) -> UILabel {
    let titleLabel = UILabel()
    titleLabel.text = viewTitle
    titleLabel.font = UIFont(name: Constants.UIElements.customTitleFont, size: 21)
    titleLabel.sizeToFit()
    return titleLabel
}

func getPopupAlert(message: String, title: String = Constants.ErrorMessages.popupTitle, buttonText: String = Constants.ErrorMessages.popupButton) -> UIAlertController {
    let popupAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    popupAlert.addAction(UIAlertAction(title: buttonText, style: .default))
    return popupAlert
}

func questionPopup(title: String, message: String, style: UIAlertControllerStyle, afirmativeAction: ((UIAlertAction) -> Void)?) -> UIAlertController {
    let questionAlert = UIAlertController(title: title, message: message, preferredStyle: style)
    let logOutAction = UIAlertAction(title: Constants.UIMessages.affirmative, style: .destructive, handler: afirmativeAction)
    questionAlert.addAction(logOutAction)
    questionAlert.addAction(UIAlertAction(title: Constants.UIMessages.negative, style: .default))
    return questionAlert
}
