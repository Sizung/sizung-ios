//
//  OrganizationsTableViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 21/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import Spine

class BasicTableViewController: UITableViewController {
  
  // MARK: Properties
  
  var modelList = [TableViewCellDisplayable]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //    init refresh control
    let refreshControl = UIRefreshControl()
//    refreshControl.attributedTitle = NSAttributedString(string: "Refreshing")
    self.tableView?.addSubview(refreshControl)
    refreshControl.addTarget(self, action: #selector(self.updateData(_:)), forControlEvents: UIControlEvents.ValueChanged)
    refreshControl.beginRefreshing()
    
    self.refreshControl = refreshControl
    
    //  initial fetch
    self.updateData(self)
  }
  
  
  func updateData(sender:AnyObject){
    fatalError("Using abstract BasicTableViewController")
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  // MARK: - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    // Return the number of sections.
    if modelList.count > 0 || self.refreshControl!.refreshing {
      
      self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine;
      UIView.animateWithDuration(UIView.inheritedAnimationDuration(), animations: {
        self.tableView.backgroundView?.alpha = 0
      })
      return 1;
      
    } else {
      
      let messageLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
      
      messageLabel.text = "No data is currently available.\nPlease pull down to refresh.";
      messageLabel.textColor = UIColor.blackColor()
      messageLabel.numberOfLines = 0;
      messageLabel.textAlignment = NSTextAlignment.Center;
      messageLabel.sizeToFit()
      
      self.tableView.backgroundView = messageLabel;
      self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None;
      
    }
    
    return 0;
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return modelList.count
  }
  
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cellIdentifier = "SizungTableViewCell"
    let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SizungTableViewCell
    
    
    let model = modelList[indexPath.row]
//    var labelText:String
//    switch (model){
//    case let organization as Organization:
//      labelText = organization.name!
//    case let conversation as Conversation:
//      labelText = conversation.title!
//    case let agendaItem as AgendaItem:
//      labelText = "AgendaItem: \(agendaItem.title!)"
//    case let deliverable as Deliverable:
//      labelText = "Deliverable: \(deliverable.title!)"
//    case let comment as Comment:
//      labelText = comment.body!
//    default:
//      labelText = model.dynamicType.description()
//    }
    cell.textLabel!.text = model.getTableViewCellTitle()

    
    return cell
  }
  
}
