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
        let entityDescription = NSEntityDescription.entity(forEntityName: "ToDo", in: context)
        
        return .init(entity: entityDescription!, insertInto: nil)
    }
    
    public func deserialize(_ parSONObject: ParSON, context: NSManagedObjectContext, keyPath: String) throws {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss ZZZ"
        let dateString: String = try parSONObject.value(forKeyPath: "\(keyPath).datetime")
        self.dateTime = dateFormatter.date(from: dateString) as NSDate?
        self.detail = try parSONObject.value(forKeyPath: "\(keyPath).taskDetail")
        
        let fetchRequest: NSFetchRequest<ToDo> = ToDo.fetchRequest()
        
        let datePredicate = NSPredicate(format: "dateTime == %@", self.dateTime!)
        let detailPredicate = NSPredicate(format: "detail == %@", self.detail!)
        
        fetchRequest.predicate = NSCompoundPredicate.init(andPredicateWithSubpredicates: [datePredicate, detailPredicate])
        fetchRequest.entity = self.entity
        
        context.perform {
            do {
                if try fetchRequest.execute().count == 0 {
                    context.insert(self)
                }
            }
            catch  {
                print(error)
            }
        }
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        self.dateTime = Date() as NSDate?
        self.isFinished = false
        self.isSynchronized = false
    }
    
    
}
