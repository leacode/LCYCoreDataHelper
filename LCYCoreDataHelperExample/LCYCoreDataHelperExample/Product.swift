//
//  Product.swift
//  LCYCoreDataHelperExample
//
//  Created by LiChunyu on 16/1/24.
//  Copyright © 2016年 leacode. All rights reserved.
//

import Foundation
import CoreData


class Product: NSManagedObject {
    
    static var i = 0

    class func insertCoreDataModel() {
        
        let product: Product? = NSEntityDescription.insertNewObject(forEntityName: "Product", into: globalContext!) as? Product
        
        product?.productId = i
        i += 1
        product?.productName = "Product\(i)"
        product?.productPrice = 99.0
        product?.productIntroduction = "This is a good thing"
                
        do {
            try coreDataHelper?.backgroundSaveContext()
        } catch {
            print("save User failed, error: \(error)")
        }
        
    }

}
