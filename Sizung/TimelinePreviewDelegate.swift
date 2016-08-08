//
//  TimelinePreviewDelegate.swift
//  Sizung
//
//  Created by Markus Klepp on 05/08/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import QuickLook

extension TimelineTableViewController: QLPreviewControllerDelegate, QLPreviewControllerDataSource {

  func showPreview() {
    let previewController = QLPreviewController()
    previewController.dataSource = self
    self.presentViewController(previewController, animated: true, completion: nil)
  }

  func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
    return 1
  }

  func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
    return previewFilePath!
  }
}
