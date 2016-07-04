//
//  SizungMarkdownParser.swift
//  Sizung
//
//  Created by Markus Klepp on 09/06/16.
//  Copyright © 2016 Sizung. All rights reserved.
//

import Bumblebee

class SizungMarkdownParser {

  let fontSize: CGFloat = 13

  var markdown = BumbleBee()
  var defaultAttr: Dictionary<String, AnyObject> = [:]

  init() {

    // italic pattern
    markdown.add("*?*", recursive: false) {
      (pattern: String, text: String, start: Int) -> (String, [NSObject : AnyObject]?) in
      if pattern == "**" {
        return (pattern, nil)
      }
      let replace = pattern[pattern.startIndex.advancedBy(1)...pattern.endIndex.advancedBy(-2)]
      return (replace, [NSFontAttributeName: R.font.brandonGrotesqueMedium(size: self.fontSize)!])
    }
    //bold pattern
    markdown.add("**?**", recursive: false) {
      (pattern: String, text: String, start: Int) -> (String, [NSObject : AnyObject]?) in
      let replace = pattern[pattern.startIndex.advancedBy(2)...pattern.endIndex.advancedBy(-3)]
      return (replace, [NSFontAttributeName: R.font.brandonTextW01Medium(size: self.fontSize)!])
    }
    //mention pattern
    markdown.add("@[?](?)", recursive: false) {
      (pattern: String, text: String, start: Int) -> (String, [NSObject : AnyObject]?) in
      let replace =
        pattern[
          pattern.rangeOfString("[")!.startIndex.advancedBy(1)
            ...
            pattern.rangeOfString("]")!.endIndex.advancedBy(-2)
      ]
      return (replace, [NSFontAttributeName: R.font.brandonTextW01Medium(size: self.fontSize)!])
    }

    // default font
    defaultAttr = [NSFontAttributeName: R.font.brandonTextRegular(size: self.fontSize)!]
  }

  func parseMarkdown(rawText: String) -> NSAttributedString {
    return markdown.process(rawText, attributes: defaultAttr)
  }
}
