//
//  File.swift
//  WhatTodo
//
//  Created by Ben Fowler on 19/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import Foundation
import UIKit

class ToDoCell:  UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    
    private(set) var todoEntitiy: ToDo?
    
    public func configureCell(forToDo todo: ToDo) {
        
        self.todoEntitiy = todo
        
        self.dateLabel.adjustsFontSizeToFitWidth = true
        self.detailLabel.adjustsFontSizeToFitWidth = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, H:mm a"
        self.dateLabel.text = dateFormatter.string(from: todo.dateTime as! Date)
        self.detailLabel.text = todo.detail!
        
        self.updateToDoStatus()
    }
    
    @IBAction func statusButtonTouchUpInside(_ sender: UIButton) {
        
        self.todoEntitiy?.isFinished = !(self.todoEntitiy!.isFinished)
        
        self.updateToDoStatus()
        
        coreDataStack.saveContext()
    }
    
    func updateToDoStatus() {
        self.statusButton.setBackgroundImage(#imageLiteral(resourceName: "Unchecked Circle"), for: .normal)
        
        if self.todoEntitiy!.isFinished {
            self.statusButton.setBackgroundImage(#imageLiteral(resourceName: "Checkmark Filled"), for: .normal)
        }
    }
}
