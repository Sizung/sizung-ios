//
//  LoadingViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 15/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

  @IBOutlet weak var logoView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    UIApplication.sharedApplication().statusBarStyle = .Default

    self.logoView.alpha = 0.2

    UIView.animateWithDuration(
      1.5,
      delay: 0.5,
      options: [ .Repeat, .CurveLinear, .Autoreverse],
      animations: {
        self.logoView.alpha = 1
      }, completion: nil)
  }
}
