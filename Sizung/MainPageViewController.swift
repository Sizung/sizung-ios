//
//  MainPageViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 27/05/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class MainPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  
  var previousIndex: Int = 1
  var nextIndex: Int = 1
  
  var mainPageViewControllerDelegate: MainPageViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.dataSource = self
    self.delegate = self
    
    setSelectedIndex(nextIndex)
  }
  
  var orderedViewControllers: [UIViewController] = []
  
  func loadControllerNamed(name: String) -> UIViewController {
    return UIStoryboard(name: "Main", bundle: nil) .
      instantiateViewControllerWithIdentifier(name)
  }
  
  func setSelectedIndex(index: Int) {
    previousIndex = nextIndex
    nextIndex = index
    
    var direction: UIPageViewControllerNavigationDirection = .Forward
    if previousIndex > nextIndex {
      direction = .Reverse
    }
    
    if orderedViewControllers.count > index {
      setViewControllers([orderedViewControllers[index]],
                         direction: direction,
                         animated: true,
                         completion: nil)
    }
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
    self.nextIndex = self.orderedViewControllers.indexOf(pendingViewControllers.first!)!
  }
  
  func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    if(finished && completed) {
      self.previousIndex = self.orderedViewControllers.indexOf(previousViewControllers.first!)!
      if mainPageViewControllerDelegate != nil {
        mainPageViewControllerDelegate?.mainpageViewController(self, didSwitchToIndex: self.nextIndex)
      }
    }
  }
}

protocol MainPageViewControllerDelegate {
  func mainpageViewController(mainPageViewController: MainPageViewController, didSwitchToIndex index: Int)
}