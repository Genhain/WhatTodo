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
    var fetchedResultsController: NSFetchedResultsController<ToDo>?
    var todoRequestManager: ToDoRequestManager?
    
    var tableView: UITableView?
    var tableSearchController: UISearchController?
    fileprivate var searchTableSelectedIndexPath: IndexPath?
    var tableEventHandler: TableEventProtocol?
    
    init(tableView: UITableView, searchController: UISearchController?, tableEventHandler: TableEventProtocol, fetchedResultsController: NSFetchedResultsController<ToDo>, todoRequestManager: ToDoRequestManager) {
        
        super.init()
        
        
        self.tableView = tableView
        self.tableSearchController = searchController
        self.tableEventHandler = tableEventHandler
        self.fetchedResultsController = fetchedResultsController
        self.todoRequestManager = todoRequestManager
        
        self.fetchedResultsController?.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
        
        
        let refreshControl = UIRefreshControl()
        self.tableView?.addSubview(refreshControl)
        self.tableView?.refreshControl = refreshControl
        
        refreshControl.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationDidBecomeActive() {
        self.attemptFetch(withPredicate: nil)
        
        self.todoRequestManager!.getTodos(fetchedResultsController: self.fetchedResultsController!) {
            self.tableView?.refreshControl?.endRefreshing()
        }
        self.todoRequestManager!.postUnsynchronizedTodos(fetchedResultsController: self.fetchedResultsController!)
        self.tableView?.refreshControl?.endRefreshing()
    }
    
    func applicationDidEnterBackground() {
        self.attemptFetch(withPredicate: nil)
        self.todoRequestManager!.postUnsynchronizedTodos(fetchedResultsController: self.fetchedResultsController!)
    }
    
    //MARK: Functionality
    
    func refreshTable() {
        self.attemptFetch(withPredicate: nil)
        
        if currentReachabilityStatus != .notReachable {
            self.todoRequestManager!.getTodos(fetchedResultsController: self.fetchedResultsController!) {
                self.tableView?.refreshControl!.endRefreshing()
            }
        }
        else {
            self.tableView?.refreshControl?.endRefreshing()
        }
        
        self.todoRequestManager!.postUnsynchronizedTodos(fetchedResultsController: self.fetchedResultsController!)
    }
    
    func attemptFetch(withPredicate predicate: NSPredicate?) {
        
        let frc = self.fetchedResultsController!
        frc.fetchRequest.predicate = predicate
        
        do {
            try frc.performFetch()
        } catch {
            print(error)
        }
    }
}

//MARK: UISearchResultsUpdating, UISearchBarDelegate
extension ToDoListDataProvider: UISearchResultsUpdating, UISearchBarDelegate
{
    private struct AssociatedKeys {
        static var filteredTodos = [ToDo]()
    }
    
    var filteredTodos: [ToDo]? {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.filteredTodos) as? [ToDo])!
        }
        
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.filteredTodos, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            }
        }
    }
    
    @available(iOS 8.0, *)
    public func updateSearchResults(for searchController: UISearchController) {
        self.filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredTodos = self.fetchedResultsController!.fetchedObjects!.filter { todo in
            return todo.detail!.lowercased().contains(searchText.lowercased())
        }
        
        self.tableView!.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.tableView!.reloadData()
        self.attemptFetch(withPredicate: nil)
    }
}

//MARK: UITableViewDataSource
extension ToDoListDataProvider: UITableViewDataSource, ToDoCellEventHandler
{
    internal func isfinishedChanged(_ cell: ToDoCell, toDo: ToDo, newValue: Bool) {
        var newValueAsString = "no"
        if newValue {
            newValueAsString = "yes"
        }
        
        self.todoRequestManager!.patchToDo(todo: toDo, fieldToPatch: "isFinished", newValue: newValueAsString)
        
        self.searchTableSelectedIndexPath = self.tableView?.indexPath(for: cell)
    }

    
    //MARK: ToDoCellEventHandler
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",  for: indexPath) as! ToDoCell
        
        self.configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
    
    fileprivate func configureCell(cell: ToDoCell, indexPath: IndexPath) {
        var todo = self.fetchedResultsController!.object(at: indexPath)
        
        if tableSearchController!.isActive && tableSearchController!.searchBar.text != "" && self.filteredTodos!.count > 0 {
            
            todo = filteredTodos![indexPath.row]
        }
        
        cell.configureCell(forToDo: todo, eventHandler: self)
    }
    
    @available(iOS 2.0, *)
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableSearchController!.isActive,
            tableSearchController!.searchBar.text != "" {
            return filteredTodos!.count
        }
        
        let frc = self.fetchedResultsController!
        
        if let sections = frc.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        let frc = self.fetchedResultsController!
        
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
            var todo:ToDo!
            
            if self.tableSearchController!.isActive {
                todo = self.filteredTodos![indexPath.row]
            }
            else {
                todo = self.fetchedResultsController!.object(at: indexPath)
            }
            self.searchTableSelectedIndexPath = indexPath
            self.todoRequestManager!.deleteToDo(todo: todo)
            self.tableSearchController!.isActive = false
            coreDataStack.persistentContainer.viewContext.delete(todo)
            coreDataStack.saveContext()
        }
        
        let editRowAction = UITableViewRowAction(style: .default, title: "Edit") { (rowAction, indexPath) in
            var todo:ToDo!
            
            if self.tableSearchController!.isActive {
                todo = self.filteredTodos![indexPath.row]
            }
            else {
                todo = self.fetchedResultsController!.object(at: indexPath)
            }
            self.searchTableSelectedIndexPath = indexPath
            self.tableEventHandler?.editRow(forRowAction: rowAction, todo: todo, indexPath: indexPath)
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
                var validIndexPath = indexPath
                
                if tableSearchController!.isActive {
                    validIndexPath = searchTableSelectedIndexPath!
                }
                self.tableView?.deleteRows(at: [validIndexPath], with: .fade)
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
                var validIndexPath = indexPath
                
                if let searchedIndexPath = searchTableSelectedIndexPath,
                tableSearchController!.isActive {
                    validIndexPath = searchedIndexPath
                }
                
                let cell = tableView?.cellForRow(at: validIndexPath) as! ToDoCell
                self.configureCell(cell: cell, indexPath: validIndexPath)
            }
            break
        }
    }
}
