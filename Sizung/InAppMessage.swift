//
//  InAppMessage.swift
//  Sizung
//
//  Created by Markus Klepp on 03/07/16.
//  Copyright © 2016 Sizung. All rights reserved.
//


import Whisper

class InAppMessage {

  static func showErrorMessage(text: String) {
    let murmur = Murmur(
      title: text,
      backgroundColor: UIColor.redColor(),
      titleColor: UIColor.whiteColor(),
      font: R.font.brandonGrotesqueMedium(size: 12)!
    )

    Whistle(murmur)
  }
}
