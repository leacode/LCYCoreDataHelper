//
//  AppDelegate.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/22.
//  Copyright © 2016年 leacode. All rights reserved.
//

import UIKit
import LCYCoreDataHelper
import CoreData

var appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
var coreDataHelper = appDelegate.coreDataHelper
var globalContext = coreDataHelper?.context
//var globalContext = coreDataHelper?.importContext

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var coreDataHelper: LCYCoreDataHelper? = {
        var coreDataHelper: LCYCoreDataHelper?
        do {
            self.loadLocalAddressData()
            // create a core data file for storing data
            coreDataHelper = try LCYCoreDataHelper(storeFileName: "buyMall")
            
            // import DefaultData.sqlite to the main datasource
//            coreDataHelper = try LCYCoreDataHelper(storeFileName: "buyMall", sourceStoreFileName: "DefaultData.sqlite", selectedUniqueAttributes: [ "User": "username"])
        } catch {
            print("load store failed, error: \(error)")
        }
        return coreDataHelper
    }()
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        do {
            try coreDataHelper?.setupCoreData()
        } catch {
        
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        do {
            try coreDataHelper?.backgroundSaveContext()
        } catch {
        
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
       
    }

    func applicationDidBecomeActive(application: UIApplication) {
        
    }

    func applicationWillTerminate(application: UIApplication) {
        do {
            try coreDataHelper?.backgroundSaveContext()
        } catch {
            
        }
    }
    
    func loadLocalAddressData() {
        let home = NSHomeDirectory() as NSString
        /// 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.stringByAppendingPathComponent("Documents") as NSString
        let filePath = docPath.stringByAppendingPathComponent("DefaultData.sqlite")
        let fm : NSFileManager = NSFileManager.defaultManager()
        if !fm.fileExistsAtPath(filePath){
            let dbPath = NSBundle.mainBundle().pathForResource("DefaultData", ofType: ".sqlite")
            
            do {
                try fm.copyItemAtPath(dbPath!, toPath: filePath)
            } catch {
                
            }
            
        }
    }

    
    


}

