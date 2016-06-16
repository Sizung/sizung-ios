//
//  SizungSegmentedControl.swift
//  Sizung
//
//  Created by Markus Klepp on 03/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

@IBDesignable class SizungSegmentedControl: UIControl {
  
  private var labels = [UILabel]()
  var thumbView = UIView()
  
  var items: [String] = ["Item 1", "Item 2", "Item 3"] {
    didSet {
      setupLabels()
    }
  }
  
  var selectedIndex : Int = 1 {
    didSet {
      displayNewSelectedIndex()
    }
  }
  
  let horizontalPadding : CGFloat = 5
  
  @IBInspectable var selectedLabelColor : UIColor = UIColor.whiteColor() {
    didSet {
      setSelectedColors()
    }
  }
  
  @IBInspectable var unselectedLabelColor : UIColor = UIColor.whiteColor() {
    didSet {
      setSelectedColors()
    }
  }
  
  var thumbColors : [UIColor] = [UIColor.redColor(), UIColor.blueColor(), UIColor.greenColor()] {
    didSet {
      setSelectedColors()
    }
  }
  
  @IBInspectable var borderColor : UIColor = UIColor.clearColor() {
    didSet {
      layer.borderColor = borderColor.CGColor
    }
  }

  @IBInspectable var font : UIFont! = R.font.brandonGrotesqueMedium(size: 12) {
    didSet {
      setFont()
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setupView()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupView()
  }
  
  func setupView(){
    
    layer.cornerRadius = frame.height / 2
    layer.borderColor = self.borderColor.CGColor
    layer.borderWidth = 2
    
    backgroundColor = UIColor.clearColor()
    
    setupLabels()
    
    addIndividualItemConstraints(labels, mainView: self, padding: horizontalPadding)
    
    insertSubview(thumbView, atIndex: 0)
  }
  
  func setupLabels(){
    
    for label in labels {
      label.removeFromSuperview()
    }
    
    labels.removeAll(keepCapacity: true)
    
    for index in 1...items.count {
      
      let label = UILabel(frame: CGRectMake(0, 0, 70, 40))
      label.text = items[index - 1]
      label.backgroundColor = UIColor.clearColor()
      label.textAlignment = .Center
      label.font = self.font
      label.textColor = index == 1 ? selectedLabelColor : unselectedLabelColor
      label.translatesAutoresizingMaskIntoConstraints = false
      self.addSubview(label)
      labels.append(label)
    }
    
    addIndividualItemConstraints(labels, mainView: self, padding: horizontalPadding)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    var selectFrame = self.bounds
    let newWidth = CGRectGetWidth(selectFrame) / CGFloat(items.count)
    selectFrame.size.width = newWidth
    thumbView.frame = selectFrame
    thumbView.layer.cornerRadius = thumbView.frame.height / 2
    
    displayNewSelectedIndex()
    
  }
  
  override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    
    let location = touch.locationInView(self)
    
    var calculatedIndex : Int?
    for (index, item) in labels.enumerate() {
      if item.frame.contains(location) {
        calculatedIndex = index
      }
    }
    
    
    if calculatedIndex != nil {
      selectedIndex = calculatedIndex!
      sendActionsForControlEvents(.ValueChanged)
    }
    
    return false
  }
  
  func displayNewSelectedIndex(){
    
    labels.forEach { label in
      label.textColor = self.unselectedLabelColor
    }
    
    let label = labels[selectedIndex]
    label.textColor = selectedLabelColor
    
    UIView.animateWithDuration(0.2, animations: {
      
      let thumbOrigin = CGPoint(x: label.frame.origin.x - self.horizontalPadding, y: label.frame.origin.y)
      let thumbSize = CGSize(width: label.frame.size.width + self.horizontalPadding*2, height: label.frame.size.height)
      let thumbFrame = CGRect(origin: thumbOrigin, size: thumbSize)
      
      self.thumbView.frame = thumbFrame
      self.thumbView.backgroundColor = self.thumbColors[self.selectedIndex]
      
      }, completion: nil)
  }
  
  func addIndividualItemConstraints(items: [UIView], mainView: UIView, padding: CGFloat) {
    
    for (index, button) in items.enumerate() {
      
      let topConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0)
      
      let bottomConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0)
      
      var rightConstraint : NSLayoutConstraint!
      
      if index == items.count - 1 {
        
        rightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: -padding)
        
      }else{
        
        let nextButton = items[index+1]
        rightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: nextButton, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: -padding)
      }
      
      
      var leftConstraint : NSLayoutConstraint!
      
      if index == 0 {
        
        leftConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: mainView, attribute: NSLayoutAttribute.Left, multiplier: 1.0, constant: padding)
        
      }else{
        
        let prevButton = items[index-1]
        leftConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: prevButton, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: padding)
        
        let firstItem = items[0]
        
        let widthConstraint = NSLayoutConstraint(item: button, attribute: .Width, relatedBy: NSLayoutRelation.Equal, toItem: firstItem, attribute: .Width, multiplier: 1.0  , constant: 0)
        
        mainView.addConstraint(widthConstraint)
      }
      
      mainView.addConstraints([topConstraint, bottomConstraint, rightConstraint, leftConstraint])
    }
  }
  
  func setSelectedColors(){
    for label in labels {
      label.textColor = unselectedLabelColor
    }
    
    if labels.count > 0 {
      labels[0].textColor = selectedLabelColor
    }
  }
  
  func setFont(){
    for item in labels {
      item.font = font
    }
  }
}