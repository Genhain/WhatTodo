//
//  ToDoListDataProvider.swift
//  WhatTodo
//
//  Created by Ben Fowler on 19/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import UIKit
import CoreData

let toDodateFormat = "MM-dd-yyyy HH:mm:ss zzzz"

protocol TableEventProtocol {
    func editRow(forRowAction action: UITableViewRowAction, todo: ToDo, indexPath: IndexPath)
}

class ToDoListDataProvider: NSObject
{
    lazy var fetchedResultsController: NSFetchedResultsController<ToDo> = {
        let fetchRequest: NSFetchRequest<ToDo> = ToDo.fetchRequest()
        let dateSort = NSSortDescriptor(key: "dateTime", ascending: false)
        fetchRequest.sortDescriptors = [dateSort]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()
    
    var tableView: UITableView?
    var tableEventHandler: TableEventProtocol?
    
    private(set) var restAPI: RestAPI = RestAPI()
    
    init(tableView: UITableView, tableEventHandler: TableEventProtocol) {
        
        super.init()
        
        self.tableView = tableView
        self.tableEventHandler = tableEventHandler
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationDidBecomeActive() {
        self.postUnsynchronizedTodos()
    }
    //MARK: Functionality
    
    func attemptFetch(withPredicate predicate: NSPredicate?) {
        
        let frc = self.fetchedResultsController
        frc.fetchRequest.predicate = predicate
        
        do {
            try frc.performFetch()
        } catch {
            print(error)
        }
    }
    
    public func getTodos() {
        restAPI.getRequest(todoEndPointURL) { (parSON, responseString, error) in
            parSON?.enumerateObjects(ofType: ToDo.self, forKeyPath: "", context: coreDataStack.persistentContainer.viewContext, enumerationsClosure: { (deserialisable) in
                
                guard let todo = deserialisable as? ToDo else { return }
                
                let existingTodosByFilter = self.fetchedResultsController.fetchedObjects!.filter({ (todoElement) -> Bool in
                    let retVal = (todoElement.dateTime!.description == todo.dateTime!.description &&
                        todoElement.detail! == todo.detail!)
                    return retVal
                })
                
                self.fetchedResultsController.managedObjectContext.perform {
            
                    if existingTodosByFilter.count == 0 {
                        todo.isSynchronized = true
                        self.fetchedResultsController.managedObjectContext.insert(todo)
                        coreDataStack.saveContext()
                    }
                }
            })
        }
    }
    
    public func postUnsynchronizedTodos() {
        
        let unsynchronisedTodos = self.fetchedResultsController.fetchedObjects?.filter({ (element) -> Bool in
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
}

//MARK: UITableViewDataSource
extension ToDoListDataProvider: UITableViewDataSource, ToDoCellEventHandler
{
    
    //MARK: ToDoCellEventHandler
    
    func isfinishedChanged(toDo: ToDo, newValue: Bool) {
         var newValueAsString = "no"
        if newValue {
            newValueAsString = "yes"
        }
        self.patchToDo(todo: toDo, fieldToPatch: "isFinished", newValue: newValueAsString)
    }
    
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",  for: indexPath) as! ToDoCell
        
        self.configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
    
    fileprivate func configureCell(cell: ToDoCell, indexPath: IndexPath) {
        let todoItem = self.fetchedResultsController.object(at: indexPath)
        cell.configureCell(forToDo: todoItem, eventHandler: self)
    }
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let frc = self.fetchedResultsController
        
        if let sections = frc.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        let frc = self.fetchedResultsController
        
        if let sections = frc.sections {
            return sections.count
        }
        
        return 0
    }
}

//MARK: UITableViewDelegate
extension ToDoListDataProvider: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteRowAction = UITableViewRowAction(style: .default, title: "Delete") { (rowAction, indexPath) in
            let object = self.fetchedResultsController.object(at: indexPath)
            coreDataStack.persistentContainer.viewContext.delete(object)
            coreDataStack.saveContext()
        }
        
        let editRowAction = UITableViewRowAction(style: .default, title: "Edit") { (rowAction, indexPath) in
            let object = self.fetchedResultsController.object(at: indexPath)
            self.tableEventHandler?.editRow(forRowAction: rowAction, todo: object, indexPath: indexPath)
        }
        editRowAction.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        return [deleteRowAction,editRowAction]
    }
}

//MARK: Fetch Delegate
extension ToDoListDataProvider: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        self.tableView?.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                self.tableView?.insertRows(at: [indexPath], with: .fade)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                self.tableView?.deleteRows(at: [indexPath], with: .fade)
            }
            break
        case .move:
            if let indexPath = indexPath,
                let newIndexPath = newIndexPath {
                tableView?.moveRow(at: indexPath, to: newIndexPath)
            }
            break
        case .update:
            if let indexPath = indexPath {
                let cell = tableView?.cellForRow(at: indexPath) as! ToDoCell
                self.configureCell(cell: cell, indexPath: indexPath)
            }
            break
        }
    }
}
