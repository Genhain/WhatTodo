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

private let todoEndPointURL = URL(string: "https://sheetsu.com/apis/v1.0/6e59b7bf3d94")!

class MainTableVC: UITableViewController {
    
    var dataProvider: ToDoListDataProvider!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "To do"
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MainTableVC.addTodo))
        self.navigationItem.rightBarButtonItem = button
        
        self.dataProvider = ToDoListDataProvider(tableView: self.tableView)
        
        self.tableView.delegate = dataProvider
        self.tableView.dataSource = dataProvider
        
        self.dataProvider.attemptFetch()
    }
    
    func addTodo()
    {
        self.presentAlert()
    }
    
    func presentAlert() {
        let alertController = UIAlertController(title: "Add To Do", message: "Please input your task to do:", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                let todo = ToDo(context: coreDataStack.persistentContainer.viewContext)
                
                todo.detail = field.text!
                
                coreDataStack.saveContext()
        
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
        
        self.present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class ToDoListDataProvider: NSObject, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<ToDo>!
    var tableView: UITableView?
    
    init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    //MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let object = self.fetchedResultsController.object(at: indexPath)
            coreDataStack.persistentContainer.viewContext.delete(object)
            coreDataStack.saveContext()
        }
        
        if editingStyle == .insert {
            
        }
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
    
    func attemptFetch() {
        
        let fetchRequest: NSFetchRequest<ToDo> = ToDo.fetchRequest()
        let dateSort = NSSortDescriptor(key: "dateTime", ascending: false)
        fetchRequest.sortDescriptors = [dateSort]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
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


