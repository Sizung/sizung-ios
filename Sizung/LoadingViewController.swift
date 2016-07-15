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

      self.logoView.alpha = 0.4

      UIView.animateWithDuration(
        1.0,
        delay: 0.0,
        options: [ .Repeat, .CurveLinear, .Autoreverse],
        animations: {
          self.logoView.alpha = 1
        }, completion: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
