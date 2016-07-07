//
//  ConversationViewController.swift
//  Sizung
//
//  Created by Markus Klepp on 07/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import UIKit

class ConversationViewController: UIViewController {


  var conversation: Conversation!

  @IBOutlet weak var titleButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()

    self.titleButton.setTitle("@\(conversation.title)", forState: .Normal)

    // Do any additional setup after loading the view.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  @IBAction func close(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if R.segue.conversationViewController.embed(segue: segue) != nil {
      if let conversationContentViewController = segue.destinationViewController as? ConversationContentViewController {
        conversationContentViewController.conversation = self.conversation
      }
    }
  }
}
