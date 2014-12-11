//
//  ChooseLevelViewController.swift
//  TCGGame
//
//  Created by Wessel Stoop on 04-12-14
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit

class ChooseLevelViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource
{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        println("Loaded")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println("NoRows")
        
        return 10
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "MyTestCell")
        
        var level = indexPath.row + 1
        
        cell.textLabel?.text = "Level \(level)"
        cell.detailTextLabel?.text = "Wessel is de beste"
        
        println("Asking for table");
        
        return cell
    }
}