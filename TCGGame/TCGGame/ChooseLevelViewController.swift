//
//  ChooseLevelViewController.swift
//  TCGGame
//
//  Created by Wessel Stoop on 04-12-14
//  Copyright (c) 2014 gametogether. All rights reserved.
//

import UIKit



class ChooseLevelViewController: TableViewSubController, UITableViewDelegate, UITableViewDataSource
{
	// Model; this is what clients should be interested in:
	var levels: [Level] = []
	var selectedLevel: Level?
	
	
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
        
        cell.textLabel?.text = "Level \(indexPath.row + 1)"
        cell.detailTextLabel?.text = "\(level.name)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println(indexPath.row)
		
		self.selectedLevel = levels[indexPath.row]
		
		self.superController?.subControllerFinished(self)
    }
}