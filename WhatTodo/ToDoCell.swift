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
    
    public func configureCell(forToDo todo: ToDo) {
        
        self.dateLabel.adjustsFontSizeToFitWidth = true
        self.detailLabel.adjustsFontSizeToFitWidth = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, H:mm a"
        self.dateLabel.text = dateFormatter.string(from: todo.dateTime as! Date)
        self.detailLabel.text = todo.detail!
    }
}
