//
//  LocationLoggingTests.swift
//  LocationLoggingTests
//
//  Created by Anil Upadhyay on 16/08/17.
//  Copyright © 2017 Anil Upadhyay. All rights reserved.
//

import XCTest
import CoreLocation
@testable import LocationLogging
class LocationLoggingTests: XCTestCase {
    var locationController: LocationViewController!
    var locationManagerHelper: LocationManagerHelper!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let mainStoryBoard = UIStoryboard.init(name: "Main", bundle: nil)
        locationController = mainStoryBoard.instantiateViewController(withIdentifier: "LocationViewController") as! LocationViewController
        _ = locationController.view
        
        locationManagerHelper = locationController.locationManager
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLocationLabelAndSwitchShouldNotNil() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        //Validate start or stop label is nil or not
        XCTAssertNotNil(locationController.lblStartOrStopLocation)
        //Validate location Switch is nil or not
       XCTAssertNotNil(locationController.locationStartorStopSwitch)

    }
    func testVerifyLocationLabelTextAndSwitchState() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        //Validate location label text
        XCTAssertTrue(locationController.lblStartOrStopLocation.text == "Start/ Stop Location Tracking")
        //Validate location switch state
        XCTAssertFalse(locationController.locationStartorStopSwitch.isOn)
        
        //Validate location state according to Switch state
        locationController.locationStartorStopSwitch.setOn(true, animated: false)
        locationController.perform(#selector(LocationViewController.actionForLocationStartOrStop(_:)), with: locationController.locationStartorStopSwitch)
        XCTAssertNotNil(locationManagerHelper.locationManager.delegate)
        
        locationController.locationStartorStopSwitch.setOn(false, animated: false)
        locationController.perform(#selector(LocationViewController.actionForLocationStartOrStop(_:)), with: locationController.locationStartorStopSwitch)
        
        XCTAssertNil(locationManagerHelper.locationManager.delegate)
    }
    func testSetLocationManagerDelegateAndValidateLocationPermission() {
        //Location Manager delegate is set or not
        locationManagerHelper.startUpdatingLocation()
        XCTAssertNotNil(locationManagerHelper.locationManager.delegate)
        
        //Validate Location permission id define in info plist or not
        let infoData = Bundle.main.infoDictionary
        XCTAssertNotNil(infoData?["NSLocationAlwaysUsageDescription"])
        XCTAssertNotNil(infoData?["NSLocationWhenInUseUsageDescription"])
        XCTAssertTrue((infoData?["NSLocationAlwaysUsageDescription"] as! String).characters.count > 0)
            XCTAssertTrue((infoData?["NSLocationWhenInUseUsageDescription"] as! String).characters.count > 0)
        
    }
   
    func testCurrentLocation() {
        let locationDelegate = LocationDelegateTest()
        locationManagerHelper.locationManager.delegate = locationDelegate
        let filledExpectation = expectation(description: "fill Current Latitude, longnitude and TimeStamp")
        locationDelegate.filledExpectation = filledExpectation
        locationManagerHelper.locationManager.startUpdatingLocation()
        wait(for: [filledExpectation], timeout: 2.0)
        XCTAssertNotNil(locationDelegate.currentLatitude)
        XCTAssertNotNil(locationDelegate.currentLongnitude)
        XCTAssertNotNil(locationDelegate.currentTimeStamp)
    }
    func testCurrentTimerInterval() {
        let locationDelegate = LocationDelegateTest()
        locationManagerHelper.locationManager.delegate = locationDelegate
        let filledExpectation = expectation(description: "fill Current Latitude, longnitude and TimeStamp")
        locationDelegate.filledExpectation = filledExpectation
        locationManagerHelper.locationManager.startUpdatingLocation()
        wait(for: [filledExpectation], timeout: 2.0)

        if locationDelegate.currentTimeInterval > 0 {
            if locationDelegate.speedInKmPerHour > 80 {
                XCTAssertTrue(locationDelegate.currentTimeInterval == 30)
                XCTAssertTrue(locationDelegate.nextTimeInterval == 60)
            }else if locationDelegate.speedInKmPerHour >= 60 && locationDelegate.speedInKmPerHour < 80 {
                XCTAssertTrue(locationDelegate.currentTimeInterval == 60)
                XCTAssertTrue(locationDelegate.nextTimeInterval == 30)
            }else if locationDelegate.speedInKmPerHour >= 30 && locationDelegate.speedInKmPerHour < 60 {
                XCTAssertTrue(locationDelegate.currentTimeInterval == 120)
                XCTAssertTrue(locationDelegate.nextTimeInterval == 60)
            }else if locationDelegate.speedInKmPerHour >= 0 && locationDelegate.speedInKmPerHour < 30 {
                XCTAssertTrue(locationDelegate.currentTimeInterval == 300)
                XCTAssertTrue(locationDelegate.nextTimeInterval == 120)
            }
        }
    }
}
class LocationDelegateTest:NSObject, CLLocationManagerDelegate {
    var currentLatitude : Double? = nil
    var currentLongnitude: Double? = nil
    var currentLocation: CLLocation? = nil
    var currentTimeStamp: Date? = nil
    var speedInKmPerHour: Double = 0.0
    var previousSpeedInKmPerHour: Double = 0.0
    var isSpeedChanged: Bool = false
    var filledExpectation: XCTestExpectation? = nil
    var locationCaptureTimer: Timer? = nil
    var currentTimeInterval: TimeInterval = 0.0
    var nextTimeInterval: TimeInterval = 0.0
    var isTimerInitialized: Bool = false
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        if let currentLocation = manager.location {
            currentLatitude = currentLocation.coordinate.latitude
            currentLongnitude = currentLocation.coordinate.longitude
            currentTimeStamp = currentLocation.timestamp
            
            //location manager return speed in Meter per second
            let speedInMeterPerSecond = currentLocation.speed
            
            /* Need to convert into Kilometer per hour
             Formula:
             3.6 * Velocity(Meter per second) = Velocity(Kilometer per hour)
             3.6 * 10 m/s = 36 km/h
             */
            speedInKmPerHour = (3.6 * speedInMeterPerSecond)
            
            if speedInKmPerHour != previousSpeedInKmPerHour && previousSpeedInKmPerHour > 0.0 {
                isSpeedChanged = true
            }else{
                isSpeedChanged = false
            }
        }
        if let lat = currentLatitude , let long = currentLongnitude {
            currentLocation = CLLocation(latitude: lat, longitude: long)
        }
        changeTimerIntervalAsPerCalculatedSpeed()
        filledExpectation?.fulfill()
    }
    func changeTimerIntervalAsPerCalculatedSpeed() {
        //Update isTimeIntialized status
        if isSpeedChanged {
            if speedInKmPerHour > 80 && currentTimeInterval != 30{
                isTimerInitialized = false
            }else if(speedInKmPerHour >= 60 && speedInKmPerHour < 80) && currentTimeInterval != 60{
                isTimerInitialized = false
            }else if(speedInKmPerHour >= 30 && speedInKmPerHour < 60) && currentTimeInterval != 120 {
                isTimerInitialized = false
            }else if(speedInKmPerHour >= 0 && speedInKmPerHour < 30) && currentTimeInterval != 300 {
                isTimerInitialized = false
            }else{
                isTimerInitialized = true
            }
        }
        
        /*
         Write switch case to validating all conditions
         • Location should be captured after every 30 seconds interval, if speed >= 80
         • Location should be captured after every minute if speed < 80 and speed >= 60
         • Location should be captured after every 2 minutes if speed < 60 and speed >= 30
         • Location should be captured after every 5 minutes if speed < 30
         and vehicle speed suddenly goes down time interval change manner is (30 seconds, 1 minute, 2 minutes, 5 minutes)
         If speed decrease from 90km/h to 20kms so it should not goes to 30 seconds to 5 minute, it should become  1 minute only.
         */
        switch speedInKmPerHour {
        case 80..<Double.infinity:
            currentTimeInterval = 30
            nextTimeInterval = 60
        case 60..<80:
            currentTimeInterval = 60
            nextTimeInterval = 30
        case 30..<60:
            currentTimeInterval = 60 * 2
            nextTimeInterval = 60
        case 0..<30:
            currentTimeInterval = 60 * 5
            nextTimeInterval = 60 * 2
        default:
            print("Device is not moving")
        }
        if !isTimerInitialized {
            previousSpeedInKmPerHour = speedInKmPerHour
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get the current location \(error.localizedDescription)")
        filledExpectation?.fulfill()

    }
    
}
