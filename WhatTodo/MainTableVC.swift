//
//  ViewController.swift
//  WhatTodo
//
//  Created by Ben Fowler on 15/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import UIKit
import ParSON

private let todoEndPointURL = URL(string: "https://sheetsu.com/apis/v1.0/6e59b7bf3d94")!

class MainTableVC: UITableViewController {

    var toDos: [TodoTask] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "To do"
        let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(MainTableVC.addTodo))
        self.navigationItem.rightBarButtonItem = button
        
        let todo = ToDo(context: coreDataStack.persistentContainer.viewContext)
        
        print(todo)
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
                let todo = TodoTask.init(taskDetail: field.text!)
                self.toDos.append(todo)
                UserDefaults.standard.set(self.toDos, forKey: "toDos")
                UserDefaults.standard.synchronize()
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

struct TodoTask {
    var dateTime: Date?
    var detail: String?
    var isFinished: Bool = false
    var isSynced: Bool = false
    
    init(taskDetail detail: String) {
        self.dateTime = Date()
        self.detail = detail
    }
}

