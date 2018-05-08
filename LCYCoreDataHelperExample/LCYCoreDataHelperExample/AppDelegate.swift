//
//  AppDelegate.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 2016/9/11.
//  Copyright © 2016年 LiChunyu. All rights reserved.
//

import UIKit
import LCYCoreDataHelper
import CoreData

var appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
var coreDataHelper = appDelegate.coreDataHelper
var globalContext = coreDataHelper?.context

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var coreDataHelper: LCYCoreDataHelper? = {
        var coreDataHelper: LCYCoreDataHelper?
        do {
            self.loadLocalAddressData()
            coreDataHelper = try LCYCoreDataHelper(storeFileName: "buyMall")
        } catch {
            print("load store failed, error: \(error)")
        }
        return coreDataHelper
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        do {
            try coreDataHelper?.setupCoreData()
        } catch {
            
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        do {
            try coreDataHelper?.backgroundSaveContext()
        } catch {
            
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        do {
            try coreDataHelper?.backgroundSaveContext()
        } catch {
            
        }
    }
    
    func loadLocalAddressData() {
        let home = NSHomeDirectory() as NSString
        /// 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.appendingPathComponent("Documents") as NSString
        let filePath = docPath.appendingPathComponent("DefaultData.sqlite")
        let fm : FileManager = FileManager.default
        if !fm.fileExists(atPath: filePath){
            let dbPath = Bundle.main.path(forResource: "DefaultData", ofType: ".sqlite")
            
            do {
                try fm.copyItem(atPath: dbPath!, toPath: filePath)
            } catch {
                
            }
            
        }
    }


}

