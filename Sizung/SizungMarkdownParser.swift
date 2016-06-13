//
//  SizungMarkdownParser.swift
//  Sizung
//
//  Created by Markus Klepp on 09/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Bumblebee

class SizungMarkdownParser {
  
  let fontSize: CGFloat = 17
  
  var markdown = BumbleBee()
  
  init() {
    // italic pattern
    markdown.add("*?*", recursive: false) { (pattern: String, text: String, start: Int) -> (String, [NSObject : AnyObject]?) in
      if pattern == "**" {
        return (pattern, nil)
      }
      let replace = pattern[pattern.startIndex.advancedBy(1)...pattern.endIndex.advancedBy(-2)]
      return (replace,[NSFontAttributeName: UIFont.italicSystemFontOfSize(self.fontSize), NSForegroundColorAttributeName: UIColor.redColor()])
    }
    //bold pattern
    markdown.add("**?**", recursive: false) { (pattern: String, text: String, start: Int) -> (String, [NSObject : AnyObject]?) in
      let replace = pattern[pattern.startIndex.advancedBy(2)...pattern.endIndex.advancedBy(-3)]
      return (replace,[NSFontAttributeName: UIFont.boldSystemFontOfSize(self.fontSize), NSForegroundColorAttributeName: UIColor.blueColor()])
    }
    //mention pattern
    markdown.add("@[?](?)", recursive: false) { (pattern: String, text: String, start: Int) -> (String, [NSObject : AnyObject]?) in
      let replace = pattern[pattern.rangeOfString("[")!.startIndex.advancedBy(1)...pattern.rangeOfString("]")!.endIndex.advancedBy(-2)]
      return (replace,[NSFontAttributeName: UIFont.boldSystemFontOfSize(self.fontSize), NSForegroundColorAttributeName: UIColor.greenColor()])
    }
  }
  
  func parseMarkdown(rawText: String) -> NSAttributedString {
    return markdown.process(rawText)
  }
}
