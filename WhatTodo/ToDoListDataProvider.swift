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

protocol TableEventProtocol {
    func editRow(forRowAction action: UITableViewRowAction, todo: ToDo, indexPath: IndexPath)
}

class ToDoListDataProvider: NSObject, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<ToDo>!
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
    
    public func postUnsynchronizedTodos() {
        let syncPredicate = NSPredicate(format: "isSynchronized == false")
        
        let frcUnsynced = self.attemptFetch(withPredicate: syncPredicate, delegate: nil)
        
        
        if frcUnsynced.fetchedObjects!.count > 0 {
            todoPostIterator = frcUnsynced.fetchedObjects!.makeIterator()
            self.postUnsync(todo:todoPostIterator!.next()!)
        }
    }
    
    public func getTodos() {
        restAPI.getRequest(todoEndPointURL) { (parSON, responseString, error) in
            parSON?.enumerateObjects(ofType: ToDo.self, forKeyPath: "", context: coreDataStack.persistentContainer.viewContext, enumerationsClosure: { (deserialisable) in
                self.fetchedResultsController = nil
            })
            
            
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
    
    //MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
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
    
    //MARK: UITableViewDataSource
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",  for: indexPath) as! ToDoCell
        
        self.configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let frc = self.fetchedResultsController else { return 0 }
        
        if let sections = frc.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        guard let frc = self.fetchedResultsController else { return 0 }
        
        if let sections = frc.sections {
            return sections.count
        }
        
        return 0
    }
    
    //MARK: Functionality
    
    func configureCell(cell: ToDoCell, indexPath: IndexPath) {
        let todoItem = self.fetchedResultsController.object(at: indexPath)
        cell.configureCell(forToDo: todoItem)
    }
    
    func attemptFetch(withPredicate predicate: NSPredicate?, delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController<ToDo> {
        
        let fetchRequest: NSFetchRequest<ToDo> = ToDo.fetchRequest()
        let dateSort = NSSortDescriptor(key: "dateTime", ascending: false)
        fetchRequest.sortDescriptors = [dateSort]
        
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        frc.delegate = delegate
        
        do {
            try frc.performFetch()
        } catch {
            print(error)
        }
        
        return frc
    }
    
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
