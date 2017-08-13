//
//  FullScreenViewController.swift
//  Virtual tourist
//
//  Created by Mauricio Chirino on 11/8/17.
//  Copyright © 2017 3CodeGeeks. All rights reserved.
//

import UIKit

class FullScreenViewController: UIViewController {

    var imageId:String?
    var fullImage: UIImage?
    var imageLegend: String?
    
    @IBOutlet weak var largeImageView: UIImageView!
    @IBOutlet weak var legendTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        navigationController?.navigationItem.titleView = getCustomTitle(viewTitle: imageId!)
        title = imageId
        largeImageView.image = fullImage
        legendTextView.text = imageLegend
        
    }
}
