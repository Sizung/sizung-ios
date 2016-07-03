//
//  CalendarViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 01/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit
import RSDayFlow

class CalendarViewController: UIViewController, RSDFDatePickerViewDelegate, RSDFDatePickerViewDataSource {

  @IBOutlet weak var monthLabel: UILabel!
  @IBOutlet weak var calendarView: RSDFDatePickerView!


  var currentDate: NSDate?
  var calendarViewDelegate: CalendarViewDelegate?

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    calendarView.delegate = self
    calendarView.dataSource = self

    calendarView.selectDate(currentDate)
    if currentDate != nil {
      calendarView.scrollToDate(currentDate!, animated: false)
    }

  }

  func datePickerView(view: RSDFDatePickerView, didSelectDate date: NSDate) {
    calendarViewDelegate?.didSelectDate(date)
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func close(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

  @IBAction func showToday(sender: AnyObject) {
    calendarView.scrollToToday(true)
  }

  /*
   // MARK: - Navigation

   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
}

protocol CalendarViewDelegate {
  func didSelectDate(date: NSDate)
}
