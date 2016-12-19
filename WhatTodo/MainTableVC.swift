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

class MainTableVC: UITableViewController, TableEventProtocol {
    
    var dataProvider: ToDoListDataProvider!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "To do"
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MainTableVC.addTodo))
        self.navigationItem.rightBarButtonItem = button
        
        self.dataProvider = ToDoListDataProvider(tableView: self.tableView, tableEventHandler: self)
        
        self.tableView.delegate = dataProvider
        self.tableView.dataSource = dataProvider
        

        _ = self.dataProvider.attemptFetch(withPredicate: nil, delegate: self.dataProvider)
    }
    
    func addTodo()
    {
        self.presentAlert()
    }
    
    func presentAlert(forTodo todo: ToDo = ToDo(context: coreDataStack.persistentContainer.viewContext)) {
        let alertController = UIAlertController(title: "Add To Do", message: "Please input your task to do:", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                
                todo.detail = field.text!
                
                coreDataStack.saveContext()
                
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
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: TableEventProtocol
    
    func editRow(forRowAction action: UITableViewRowAction, todo: ToDo, indexPath: IndexPath) {
        self.presentAlert(forTodo: todo)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


