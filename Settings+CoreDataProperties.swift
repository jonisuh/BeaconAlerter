//
//  Settings+CoreDataProperties.swift
//  BeaconAlerter
//
//  Created by iosdev on 28.2.2017.
//  Copyright © 2017 asd. All rights reserved.
//

import Foundation
import CoreData


extension Settings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings");
    }

    @NSManaged public var alertSound: String?
    @NSManaged public var automaticSync: Bool
    @NSManaged public var dateFormat: String?
    @NSManaged public var hourMode: String?
    @NSManaged public var snoozeAmount: Int32
    @NSManaged public var snoozeLength: Int32
    @NSManaged public var snoozeOn: Bool
    @NSManaged public var soundVolume: Double
    @NSManaged public var beaconID: String?

}
