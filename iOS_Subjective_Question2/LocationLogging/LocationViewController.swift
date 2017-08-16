//
//  ViewController.swift
//  iOS_Subjective_Question2
//
//  Created by Anil Upadhyay on 14/08/17.
//  Copyright © 2017 Anil Upadhyay. All rights reserved.
//

import UIKit

class LocationViewController: UIViewController {
    @IBOutlet weak var lblStartOrStopLocation: UILabel!
    @IBOutlet weak var locationStartorStopSwitch: UISwitch!
    let locationManager = LocationManagerHelper.sharedInstance
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func actionForLocationStartOrStop(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startUpdatingLocation()
        }else{
            locationManager.stopUpdatingLocation()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

