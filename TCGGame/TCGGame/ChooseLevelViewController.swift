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
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return levels.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "MyTestCell")
        
        var level = levels[indexPath.row]
        
        cell.textLabel?.text = "Level \(level.nr)"
        cell.detailTextLabel?.text = "\(level.name)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(indexPath.row)
        self.dismissViewControllerAnimated(false,completion:nil)
    }
}