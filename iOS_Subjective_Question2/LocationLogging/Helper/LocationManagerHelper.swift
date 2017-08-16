//
//  LocationManagerHelper.swift
//  iOS_Subjective_Question2
//
//  Created by Anil Upadhyay on 14/08/17.
//  Copyright © 2017 Anil Upadhyay. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManagerHelper: NSObject {
    //Mark: Declare Variabels
    static let sharedInstance = LocationManagerHelper()
    
    let locationManager = CLLocationManager()
    var currentLatitude : Double? = nil
    var currentLongnitude: Double? = nil
    var currentLocation: CLLocation? = nil
    var currentTimeStamp: Date? = nil
    var speedInKmPerHour: Double = 0.0
    var previousSpeedInKmPerHour: Double = 0.0
    var isSpeedChanged: Bool = false
    var locationCaptureTimer: Timer? = nil
    var currentTimeInterval: TimeInterval = 0.0
    var nextTimeInterval: TimeInterval = 0.0
    var isTimerInitialized: Bool = false
    
    func startUpdatingLocation() {
        //Ask for permision for location service
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
    }
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
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
            DestroyTimer()
            previousSpeedInKmPerHour = speedInKmPerHour
            if currentTimeInterval > 0 {
                createTimerForLocationTracking(timeInterval: currentTimeInterval)
            }
        }
    }
    func createTimerForLocationTracking(timeInterval: TimeInterval) {
        isTimerInitialized = true
        locationCaptureTimer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(saveLocation), userInfo: nil, repeats: true)
        RunLoop.current.add(locationCaptureTimer!, forMode: RunLoopMode.commonModes)
    }
    func DestroyTimer() {
        locationCaptureTimer?.invalidate()
        isTimerInitialized = false
    }
    func saveLocation() {
        //Save location in file
        saveLocationInFile()
        //Save Location in DB
        saveLocationInDB()
    }
    
    func saveLocationInFile() {
        let fileManager = FileManager.default
        let docmentDirectory: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last!
        let fileUrl = docmentDirectory.appendingPathComponent("location.txt")
        let headerText = "\tTime\t\t\t Latitude\t Longitude\tCurrentTimeInterval\tNextTimeInterval"
        var seprator = ""
        for i in 0..<headerText.characters.count {
            if i % 2 == 0 {
                seprator += "***"
            }else{
                seprator += "*"
            }
        }
        var  textToLog = "\(headerText)\n\(seprator)\n\(currentTimeStamp!)\t\(currentLatitude!)\t\(currentLongnitude!)\t\t\(currentTimeInterval)\t\t\t\(nextTimeInterval)"
        var dataToWrite = textToLog.data(using: .utf8, allowLossyConversion: false)
        if fileManager.fileExists(atPath: fileUrl.path) {
            textToLog = textToLog.replacingOccurrences(of: "\(headerText)\n\(seprator)", with: "")
            dataToWrite = textToLog.data(using: .utf8, allowLossyConversion: false)
            do {
                let fileHandle = try FileHandle(forWritingTo: fileUrl)
                fileHandle.seekToEndOfFile()
                fileHandle.write(dataToWrite!)
                fileHandle.closeFile()
            }catch let error{
                print("file handle failed \(error.localizedDescription)")
            }
        }else{
            
            do {
                _ = try dataToWrite?.write(to: fileUrl, options: .atomic)
            } catch let error {
                print("cant write \(error.localizedDescription)")
            }
        }
        
    }
    func saveLocationInDB() {
        let databaseHelper = LocationDB.sharedInstance
        if databaseHelper.insertIntoLocation(time:currentTimeStamp!, latitude: currentLatitude!, longnitude: currentLongnitude!, currentTimeInterval: currentTimeInterval, nextTimeInterval: nextTimeInterval) {
            print("Location inserted to db successfully!")
        }
    }
}
extension LocationManagerHelper: CLLocationManagerDelegate {
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
            changeTimerIntervalAsPerCalculatedSpeed()
        }
        if let lat = currentLatitude , let long = currentLongnitude {
            currentLocation = CLLocation(latitude: lat, longitude: long)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get the current location \(error.localizedDescription)")
    }

}
