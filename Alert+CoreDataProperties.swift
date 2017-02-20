//
//  Alert+CoreDataProperties.swift
//  BeaconAlerter
//
//  Created by iosdev on 13.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import Foundation
import CoreData


extension Alert {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Alert> {
        return NSFetchRequest<Alert>(entityName: "Alert");
    }

    @NSManaged public var time: NSDate?
    @NSManaged public var title: String?
    @NSManaged public var days: [Bool]?
    @NSManaged public var repeating: Bool
    @NSManaged public var isEnabled: Bool
    @NSManaged public var id: String?

}
