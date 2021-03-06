//
//  ViewController.swift
//  WhatTodo
//
//  Created by Ben Fowler on 15/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import UIKit
import ParSON
import CoreData

let todoEndPointURL = URL(string: "https://sheetsu.com/apis/v1.0/6e59b7bf3d94")!

class MainTableVC: UITableViewController, TableEventProtocol
{
    lazy var fetchedResultsController: NSFetchedResultsController<ToDo> = {
        let fetchRequest: NSFetchRequest<ToDo> = ToDo.fetchRequest()
        let dateSort = NSSortDescriptor(key: "dateTime", ascending: false)
        fetchRequest.sortDescriptors = [dateSort]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return frc
    }()

    
    var dataProvider: ToDoListDataProvider!
    var searchController: UISearchController!
    
    var todoRequestManager = ToDoRequestManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "To do"
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MainTableVC.addTodo))
        self.navigationItem.rightBarButtonItem = button
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        
        self.tableView.tableHeaderView = searchController.searchBar
        self.tableView.contentOffset = .init(x: 0, y: searchController.searchBar.frame.height)
        
        self.dataProvider = ToDoListDataProvider(tableView: self.tableView,
                                                 searchController: self.searchController,
                                                 tableEventHandler: self,
                                                 fetchedResultsController: self.fetchedResultsController,
                                                 todoRequestManager: self.todoRequestManager)
        
        searchController.searchResultsUpdater = self.dataProvider
        searchController.searchBar.delegate = self.dataProvider
        
        self.tableView.delegate = dataProvider
        self.tableView.dataSource = dataProvider
        
        self.dataProvider.attemptFetch(withPredicate: nil)
        
        self.todoRequestManager.getTodos(fetchedResultsController: self.fetchedResultsController) {}
        self.todoRequestManager.postUnsynchronizedTodos(fetchedResultsController: self.fetchedResultsController)
    }
    
    func addTodo()
    {
        self.presentAlert(forTodo: nil)
    }
    
    func presentAlert(forTodo todo: ToDo?) {
        let alertController = UIAlertController(title: "Add To Do", message: "Please input your task to do:", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                
                var newTodo = todo
                if newTodo == nil {
                    newTodo = ToDo(context: coreDataStack.persistentContainer.viewContext)
                }
                
                newTodo!.detail = field.text!
                
                coreDataStack.saveContext()
                
                if newTodo!.isSynchronized {
                    self.todoRequestManager.patchToDo(todo: newTodo!, fieldToPatch: "taskDetail", newValue: newTodo!.detail!)
                }
                
                self.tableView?.setEditing(false, animated: true)
        
            } else {
                // user did not fill field
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "What to do..."
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        if searchController.isActive {
           searchController.present(alertController, animated: true, completion: nil)
        }
        else {
           self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    //MARK: TableEventProtocol
    
    func editRow(forRowAction action: UITableViewRowAction, todo: ToDo, indexPath: IndexPath) {
        self.presentAlert(forTodo: todo)
    }
    
    func deleteRow(forRowAction action: UITableViewRowAction, todo: ToDo, indexPath: IndexPath) {
        self.tableView?.setEditing(false, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


