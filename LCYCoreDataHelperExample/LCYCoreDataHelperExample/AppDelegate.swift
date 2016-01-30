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
            coreDataHelper = try LCYCoreDataHelper(storeFileName: "buyMall")
//            coreDataHelper = try LCYCoreDataHelper(storeFileName: "buyMall", sourceStoreFileName: "DefaultData.sqlite", selectedUniqueAttributes: [ "User": "username"])
            try coreDataHelper?.setupCoreData()
        } catch {
            print("load store failed, error: \(error)")
        }
        
        return coreDataHelper
    }()
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
//        loadLocalAddressData()
//        do {
//            try coreDataHelper?.deepCopyFromSourceStore()
//        } catch {
//            print("copyFromSourceStore error: \(error)")
//        }
        
               
//        print(objs?.count)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
       
    }

    func applicationWillEnterForeground(application: UIApplication) {
       
    }

    func applicationDidBecomeActive(application: UIApplication) {
        
    }

    func applicationWillTerminate(application: UIApplication) {
        
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

