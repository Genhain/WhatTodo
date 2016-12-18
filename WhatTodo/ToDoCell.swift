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
        
        self.dateLabel.text = todo.dateTime?.description
        self.detailLabel.text = todo.detail!
    }
}
