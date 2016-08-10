//
//  OrganizationContentViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 04/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class OrganizationContentViewController: UIViewController, MainPageViewControllerDelegate {

  @IBOutlet weak var segmentedControl: SizungSegmentedControl!

  var mainPageViewController: MainPageViewController!

  override func viewDidLoad() {
    super.viewDidLoad()

    segmentedControl.items = ["AGENDA", "DISCUSSION", "ACTION"]
    segmentedControl.thumbColors = [Color.AGENDAITEM, Color.DISCUSSION, Color.ACTION]
    segmentedControl.addTarget(
      self, action:
      #selector(self.segmentedControlDidChange),
      forControlEvents: .ValueChanged
    )
  }

  // segmentedControl Delegate

  func segmentedControlDidChange(sender: SizungSegmentedControl) {

    let selectedIndex = sender.selectedIndex

    self.mainPageViewController.setSelectedIndex(selectedIndex)
  }

  // MainPageViewControllerDelegate
  func mainpageViewController(
    mainPageViewController: MainPageViewController,
    didSwitchToIndex index: Int) {
    segmentedControl.selectedIndex = index
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    if R.segue.organizationContentViewController.embedMainPage(segue: segue) != nil {
      if let mainPageViewController = segue.destinationViewController as? MainPageViewController {
        self.mainPageViewController = mainPageViewController
        self.mainPageViewController.mainPageViewControllerDelegate = self

        self.mainPageViewController.orderedViewControllers
          .append(R.storyboard.organization.agendaItemsTableViewController()!)
        self.mainPageViewController.orderedViewControllers
          .append(R.storyboard.organization.streamTableViewController()!)

        let deliverablesTableViewController =
          R.storyboard.organization.userDeliverablesTableViewController()!

        let token = AuthToken(data: Configuration.getAuthToken())
        let userId = token.getUserId()

        deliverablesTableViewController.userId = userId

        self.mainPageViewController.orderedViewControllers.append(deliverablesTableViewController)

      } else {
        fatalError("unexpected segue destinationViewcontroller " +
          "\(segue.destinationViewController.dynamicType)")
      }
    } else {
      fatalError("unexpected segue \(segue.identifier)")
    }
  }
}
