//
//  ViewController.swift
//  WhatTodo
//
//  Created by Ben Fowler on 15/12/2016.
//  Copyright © 2016 BF. All rights reserved.
//

import UIKit
import ParSON

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let restAPI = RestAPI()
        let url = URL(string: "https://sheetsu.com/apis/v1.0/6e59b7bf3d94")
        
//        restAPI.postRequest(URL(string: "https://sheetsu.com/apis/v1.0/6e59b7bf3d94")!, id: "123", title: "Testing post api", description: "testing my post api", onCompletion: { (parson, responseString, error) in
//            print(responseString)
//        })
        
        restAPI.postRequest(url!, title: "test") { (parSON, responseString, error) in
            print(parSON)
            print(responseString)
            print(error)
        }
//        restAPI.deleteRequest(url!, field: "id", fieldValue: "1") { (parSON, responseString, error) in
//            print(parSON)
//            print(responseString)
//            print(error)
//        }
        
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

