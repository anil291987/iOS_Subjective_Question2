//
//  SQLLiteHelper.swift
//  LocationLogging
//
//  Created by Anil Upadhyay on 15/08/17.
//  Copyright © 2017 Anil Upadhyay. All rights reserved.
//

import UIKit
class SQLLiteHelper {
    
    var database : OpaquePointer? //sqlite3 pointerer
    var writableDBPath: String?
    
    init(dbFileName fileName: String, deleteEditableCopy isDelete: Bool) {
//        super.init()
        //Create database path for saving database
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectoryPath = paths[0] as String
        writableDBPath = documentDirectoryPath + "/" + fileName
        
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: writableDBPath!) {
            //The DB file does not exist inside the Document Directory than copy from Bundle to the document directory
            let bundleDBPath =  Bundle.main.resourcePath! + "/" + fileName
            
            var error: NSError?
            
            do {
                try fileManager.copyItem(atPath: bundleDBPath, toPath: writableDBPath!)
            } catch let error1 as NSError {
                error = error1
                print("db can not be copied to document directory \(error!.description)")
            }
        }
        print ("DB path: \(String(describing: writableDBPath))")
    }
    
    func initializeStatement(sqlStatement statement:inout OpaquePointer?,query sqlQuery:String) -> Bool
    {
        
        if(statement == nil)
        {
            if sqlite3_prepare_v2(database, (sqlQuery as NSString).utf8String, -1, &statement , nil) != SQLITE_OK
            {
                print("Error while preparing statment \(sqlite3_prepare_v2(database,(sqlQuery as NSString).utf8String, -1,&statement , nil))")
                return false
            }
        }
        
        return true
    }
    // Convenience function to execute DELETE, UPDATE, and INSERT statements.
    func executeUpdate(sqlStatement statement:OpaquePointer) -> Bool
    {
        let resultCode = executeStatement(sqlStatement: statement, success:Int(SQLITE_DONE))
        sqlite3_reset(statement)
        return resultCode
    }
    // Convenience function to execute SELECT statements.You must call sqlite3_reset after you're done.
    func executeSelect(sqlStatement statement:OpaquePointer) -> Bool
    {
        return executeStatement(sqlStatement: statement, success: Int(SQLITE_ROW))
    }

    // Convenience function to execute COUNT statements.You must call sqlite3_reset after you're done.
    func executeCount(sqlStatement statement:OpaquePointer) -> Bool
    {
        return executeStatement(sqlStatement: statement, success: Int(SQLITE_ROW))
    }

    func executeStatement(sqlStatement statement:OpaquePointer,success successConstant:Int) -> Bool
    {
        let success = Int(sqlite3_step(statement))
        
        if success != successConstant
        {
            print("Statement \(successConstant) failed with error \(success)")
            return false
        }
        
        return true
    }
    
    
}
