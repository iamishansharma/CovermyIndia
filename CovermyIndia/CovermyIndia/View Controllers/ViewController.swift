//
//  ViewController.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 09/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{


    @IBOutlet weak var checkMaps: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        checkMaps.layer.cornerRadius = 15
    }

    @IBAction func GoToMaps(_ sender: UIButton)
    {
        self.performSegue(withIdentifier: "ToMaps", sender: self);
    }
}

