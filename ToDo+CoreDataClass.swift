//
//  ToDo+CoreDataClass.swift
//  WhatTodo
//
//  Created by Ben Fowler on 19/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import CoreData
import  ParSON

public class ToDo: NSManagedObject, ParSONDeserializable
{
    
    public static func create(inContext context: NSManagedObjectContext) -> Self {
        return .init(context: context)
    }
    
    public func deserialize(_ parSONObject: ParSON, context: NSManagedObjectContext, keyPath: String) throws {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss ZZZ"
        let dateString: String = try parSONObject.value(forKeyPath: "\(keyPath).datetime")
        self.dateTime = dateFormatter.date(from: dateString) as NSDate?
        self.detail = try parSONObject.value(forKeyPath: "\(keyPath).taskDetail")
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.dateTime = Date() as NSDate?
        self.isFinished = false
        self.isSynchronized = false
    }
    
    
}
