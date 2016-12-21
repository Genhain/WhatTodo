//
//  ToDoRequestManager.swift
//  WhatTodo
//
//  Created by Ben Fowler on 22/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import  CoreData

class ToDoRequestManager
{
    private(set) var restAPI: RestAPI = RestAPI()
    
    public func getTodos(fetchedResultsController: NSFetchedResultsController<ToDo>, onComplete: @escaping (Void) -> Void) {
        restAPI.getRequest(todoEndPointURL) { (parSON, responseString, error) in
            parSON?.enumerateObjects(ofType: ToDo.self, forKeyPath: "", context: coreDataStack.persistentContainer.viewContext, enumerationsClosure: { (deserialisable) in
                
                guard let todo = deserialisable as? ToDo else { return }
                guard self.isValidTodo(todo: todo) else { return }
                
                let existingTodosByFilter = fetchedResultsController.fetchedObjects!.filter({ (todoElement) -> Bool in
                    
                    let retVal = (todoElement.dateTime!.description == todo.dateTime!.description &&
                        todoElement.detail! == todo.detail!)
                    return retVal
                })
                
                fetchedResultsController.managedObjectContext.perform {
                    
                    if existingTodosByFilter.count == 0 {
                        todo.isSynchronized = true
                        fetchedResultsController.managedObjectContext.insert(todo)
                        coreDataStack.saveContext()
                    }
                }
            })
            
            onComplete()
        }
    }
    
    private func isValidTodo(todo: ToDo) -> Bool {
        
        guard todo.dateTime != nil else { return false }
        guard todo.detail != nil else { return false}
        
        return true
    }
    
    public func postUnsynchronizedTodos(fetchedResultsController: NSFetchedResultsController<ToDo>) {
        
        let unsynchronisedTodos = fetchedResultsController.fetchedObjects?.filter({ (element) -> Bool in
            element.isSynchronized == false
        })
        
        if unsynchronisedTodos!.count > 0 {
            todoPostIterator = unsynchronisedTodos!.makeIterator()
            self.postUnsync(todo:todoPostIterator!.next()!)
        }
    }
    
    private var todoPostIterator: IndexingIterator<[ToDo]>? = nil
    private func postUnsync( todo: ToDo ) {
        
        restAPI.postRequest(todoEndPointURL, title: todo.detail!, dateTime: todo.dateTime! as Date, onCompletion: { (parSON, responseString, error) in
            
            if error == nil {
                todo.isSynchronized = true
                
                if let nextTodo = self.todoPostIterator!.next() {
                    self.postUnsync(todo: nextTodo)
                }
                else {
                    coreDataStack.saveContext()
                }
            }
        })
    }
    
    public func patchToDo(todo: ToDo, fieldToPatch: String, newValue: String)
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = toDodateFormat
        restAPI.patchRequest(todoEndPointURL, field: "datetime", fieldByValue: dateFormatter.string(from: todo.dateTime! as Date), fieldToChange: fieldToPatch, newValue: newValue) { (parSON, responseString, error) in
            
            print(error)
        }
    }
    
    public func deleteToDo(todo: ToDo)
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = toDodateFormat
        restAPI.deleteRequest(todoEndPointURL, field: "datetime", fieldValue: dateFormatter.string(from: todo.dateTime! as Date)) { (parson, responseString, error) in
            
            print(error)
        }
    }
}
