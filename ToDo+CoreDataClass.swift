//
//  ToDo+CoreDataClass.swift
//  WhatTodo
//
//  Created by Ben Fowler on 19/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import CoreData


public class ToDo: NSManagedObject {

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.dateTime = Date() as NSDate?
        self.isFinished = false
        self.isSynchronized = false
    }
}
