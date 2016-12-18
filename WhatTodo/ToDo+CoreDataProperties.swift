//
//  ToDo+CoreDataProperties.swift
//  
//
//  Created by Ben Fowler on 19/12/2016.
//
//

import Foundation
import CoreData


extension ToDo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDo> {
        return NSFetchRequest<ToDo>(entityName: "ToDo");
    }

    @NSManaged public var dataTime: NSDate?
    @NSManaged public var detail: String?
    @NSManaged public var isFinished: Bool
    @NSManaged public var isSynchronized: Bool

}
