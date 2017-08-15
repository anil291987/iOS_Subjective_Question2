//
//  LocationDB.swift
//  LocationLogging
//
//  Created by Anil Upadhyay on 15/08/17.
//  Copyright © 2017 Anil Upadhyay. All rights reserved.
//

import UIKit

class LocationDB: SQLLiteHelper {
    // Define sqlite_stmt
    var insertLocation: OpaquePointer?
    static let sharedInstance: LocationDB = LocationDB()
    
    private init() {
        super.init(dbFileName: "LocationLoggingDB.sqlite", deleteEditableCopy: false)
        if openDatabase() == SQLITE_OK {
            print("Databse open sucessfully")
            // Intialize insert statement
            assert(initializeStatement(sqlStatement: &insertLocation, query: "Insert into Locations(time, latitude, longnitude, currentTimeInterval, nextTimeInterval) Values (?, ?, ?, ?, ?)"), "failed to initilize insert statement")
           
        }
    }
    func openDatabase() -> Int32 {
        return sqlite3_open((writableDBPath! as NSString).utf8String, &database)
    }
    func insertIntoLocation(time: Date, latitude: Double, longnitude: Double,currentTimeInterval: TimeInterval, nextTimeInterval: TimeInterval) -> Bool {
        sqlite3_bind_double(insertLocation, 1, CDouble(time.timeIntervalSince1970))
        sqlite3_bind_double(insertLocation, 2, CDouble(latitude))
        sqlite3_bind_double(insertLocation, 3, CDouble(longnitude))
        sqlite3_bind_double(insertLocation, 4, CDouble(currentTimeInterval))
        sqlite3_bind_double(insertLocation, 5, CDouble(nextTimeInterval))
        
        return executeUpdate(sqlStatement: insertLocation!)
    }
    
}
