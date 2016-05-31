//
//  MainPageViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 27/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class MainPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.dataSource = self
    self.delegate = self
    
    if orderedViewControllers.count > 1 {
      setViewControllers([orderedViewControllers[1]],
                         direction: .Forward,
                         animated: true,
                         completion: nil)
    }
  }
  
  private(set) lazy var orderedViewControllers: [UIViewController] = {
    return [self.loadControllerNamed("AgendaItemsTableViewController"),
            self.loadControllerNamed("CenterViewController"),
            self.loadControllerNamed("DeliverablesTableViewController")]
  }()
  
  private func loadControllerNamed(name: String) -> UIViewController {
    return UIStoryboard(name: "Main", bundle: nil) .
      instantiateViewControllerWithIdentifier(name)
  }
  
  func pageViewController(pageViewController: UIPageViewController,
                          viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
      return nil
    }
    
    let previousIndex = viewControllerIndex - 1
    
    guard previousIndex >= 0 else {
      return nil
    }
    
    guard orderedViewControllers.count > previousIndex else {
      return nil
    }
    
    return orderedViewControllers[previousIndex]
  }
  
  func pageViewController(pageViewController: UIPageViewController,
                          viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    guard let viewControllerIndex = orderedViewControllers.indexOf(viewController) else {
      return nil
    }
    
    let nextIndex = viewControllerIndex + 1
    let orderedViewControllersCount = orderedViewControllers.count
    
    guard orderedViewControllersCount != nextIndex else {
      return nil
    }
    
    guard orderedViewControllersCount > nextIndex else {
      return nil
    }
    
    return orderedViewControllers[nextIndex]
  }
  
  func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
    print("willTransitionToViewControllers: \(pendingViewControllers)")
  }
  
  func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    print("didFinishAnimating \(previousViewControllers)")
  }
}