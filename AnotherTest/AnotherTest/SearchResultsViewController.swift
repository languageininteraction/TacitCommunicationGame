//
//  ViewController.swift
//  AnotherTest
//
//  Created by Wessel Stoop on 30/10/14.
//  Copyright (c) 2014 Wessel Stoop. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, APIControllerProtocol {

    @IBOutlet var appsTableView : UITableView?
    
    var tableData = []
       
    let kCellIdentifier = "SearchResultCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        var api = APIController()
        api.delegate = self
        api.searchItunesFor("Angry Birds")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section:Int) -> Int
    {
        return tableData.count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier) as UITableViewCell
        
        let rowData = self.tableData[indexPath.row] as NSDictionary
        let name = rowData["trackName"] as String
        cell.textLabel?.text = "Name: \(name)"

        // Grab the artworkUrl60 key to get an image URL for the app's thumbnail
        let urlString: NSString = rowData["artworkUrl60"] as NSString
        let imgURL: NSURL? = NSURL(string: urlString)
        
        // Download an NSData representation of the image at the URL
        let imgData = NSData(contentsOfURL: imgURL!)
        cell.imageView?.image = UIImage(data: imgData)
        
        var formattedPrice = (rowData["formattedPrice"] as NSString).lowercaseString
        if formattedPrice == "free"
        {
            formattedPrice = "free (awesome!)"
            cell.backgroundColor = UIColor(red: 250/255, green: 220/255, blue: 155/255, alpha: 1)
        }
        
        println(formattedPrice)
        
        cell.detailTextLabel?.text = "This app is \(formattedPrice)"
        
        return cell
    }

    func didReceiveAPIResults(results: NSDictionary)
    {
        var results = results["results"] as NSArray
        dispatch_async(dispatch_get_main_queue(),
            {
                self.tableData = results
                self.appsTableView?.reloadData()
            })
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        println(" tap \(indexPath)");
        
        var rowData = self.tableData[indexPath.row] as NSDictionary
        let name = rowData["trackName"] as String
        let formattedPrice = (rowData["formattedPrice"] as NSString).lowercaseString

        var alert = UIAlertView()
        alert.title = name
        alert.message = "\(formattedPrice) (Wessel is gek)"
        alert.addButtonWithTitle("OK")
        alert.show()

        let cell : UITableViewCell? = tableView.cellForRowAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor(red: 160/255, green: 1, blue: 180/255, alpha: 0.8)
        cell?.textLabel?.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.8)
       
    }
    
}

