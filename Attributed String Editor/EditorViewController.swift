//
//  EditorViewController.swift
//  Attributed String Editor
//
//  Created by Timothy Purdum on 5/1/16.
//  Copyright © 2016 Cedar River Music. All rights reserved.
//

import UIKit
import Foundation

class EditorViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var textView: UITextView!
    @IBOutlet var toolbar: EditingToolbar!
    @IBOutlet var htmlBox: UILabel!
    let styler = StyleController()
    var paragraphType : String?
    var paragraphStyle : NSMutableParagraphStyle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        textView.inputAccessoryView = toolbar
        textView.allowsEditingTextAttributes = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender {
        case toolbar.boldButton:
            let range = textView.selectedRange
            let text = textView.attributedText
            let newText = styler.insertStyleAttribute("bold", selectedRange: range, text: text!)
            var attributes = textView.typingAttributes
            textView.attributedText = newText.0
            let currentFontName = (attributes[NSFontAttributeName] as? UIFont)?.fontName.lowercased()
            if currentFontName != nil {
                if currentFontName!.contains("bold") && (currentFontName!.contains("italic") || currentFontName!.contains("oblique")) {
                    attributes[NSFontAttributeName] = styler.defaultItalic
                } else if currentFontName!.contains("italic") || currentFontName!.contains("oblique") {
                    attributes[NSFontAttributeName] = styler.defaultBoldItalic
                } else if currentFontName!.contains("bold") {
                    attributes[NSFontAttributeName] = styler.defaultFont
                } else {
                    attributes[NSFontAttributeName] = styler.defaultBold
                }
            }
            textView.typingAttributes = attributes
            textView.selectedRange = range
        case toolbar.italicButton:
            let range = textView.selectedRange
            let text = textView.attributedText
            let newText = styler.insertStyleAttribute("italic", selectedRange: range, text: text!)
            var attributes = textView.typingAttributes
            textView.attributedText = newText.0
            let currentFontName = (attributes[NSFontAttributeName] as? UIFont)?.fontName.lowercased()
            if currentFontName != nil {
                if currentFontName!.contains("bold") && (currentFontName!.contains("italic") || currentFontName!.contains("oblique")) {
                    attributes[NSFontAttributeName] = styler.defaultBold
                } else if currentFontName!.contains("italic") || currentFontName!.contains("oblique") {
                    attributes[NSFontAttributeName] = styler.defaultFont
                } else if currentFontName!.contains("bold") {
                    attributes[NSFontAttributeName] = styler.defaultBoldItalic
                } else {
                    attributes[NSFontAttributeName] = styler.defaultItalic
                }
            }
            textView.typingAttributes = attributes
            textView.selectedRange = range
        case toolbar.underlineButton:
            let range = textView.selectedRange
            let text = textView.attributedText
            let newText = styler.insertStyleAttribute("underline", selectedRange: range, text: text!)
            var attributes = textView.typingAttributes
            textView.attributedText = newText.0
            let currentLineStyle = attributes[NSUnderlineStyleAttributeName] as? NSUnderlineStyle.RawValue
            if currentLineStyle == NSUnderlineStyle.styleSingle.rawValue {
                attributes[NSUnderlineStyleAttributeName] = NSUnderlineStyle.styleNone.rawValue
            } else {
                attributes[NSUnderlineStyleAttributeName] = NSUnderlineStyle.styleNone.rawValue
            }
            textView.typingAttributes = attributes
            textView.selectedRange = range
        case toolbar.bulletButton:
            let range = textView.selectedRange
            let text = textView.attributedText
            let newText = styler.insertStyleAttribute("unordered", selectedRange: range, text: text!)
            textView.attributedText = newText.0
            textView.selectedRange = newText.1
        case toolbar.numberedListButton:
            let range = textView.selectedRange
            let text = textView.attributedText
            let newText = styler.insertStyleAttribute("ordered", selectedRange: range, text: text!)
            textView.attributedText = newText.0
            textView.selectedRange = newText.1
        default:
            break
        }
    }
    
    
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        paragraphStyle = textView.typingAttributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle
        var attributes = textView.typingAttributes
        attributes[NSParagraphStyleAttributeName] = paragraphStyle
        textView.typingAttributes = attributes
        print("Index: \(textView.selectedRange.location)")
        /*//Check if trying to select a bullet or numbered list
        let selectedRange = textView.selectedRange
        let textNSString : NSString = textView.attributedText.string
        let rangeOfNewLine = textNSString.rangeOfString("\n", options: NSStringCompareOptions.BackwardsSearch, range: NSMakeRange(selectedRange.location - 5, selectedRange.length))*/
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        var attributes = textView.typingAttributes
        paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle
        if text == "\n" {
            if paragraphStyle?.headIndent == 36 {
                print("Started new list line!")
                let checkRow = styler.checkNewLineParagraphStyle(text: textView.attributedText, range: range)
                if checkRow.1 {
                    let mutString = NSMutableAttributedString(attributedString: checkRow.0)
                    mutString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle!, range: NSMakeRange(0, mutString.length))
                    self.textView.attributedText = mutString
                    self.textView.typingAttributes = attributes
                    self.textView.selectedRange = checkRow.2
                    return false
                }
            }
        } else if text == "" {
            print("Backspace!")
            if paragraphStyle?.headIndent == 36 {
                let nsString : NSString = textView.attributedText.string as NSString
                let contentsOfRange = nsString.substring(with: range)
                if contentsOfRange.contains("\t") {
                    var beginningOfLineIndex = 0
                    let lineBreakRange = nsString.range(of: "\n", options: NSString.CompareOptions.backwards, range: NSMakeRange(0, range.location))
                    if lineBreakRange.location != NSNotFound {
                        beginningOfLineIndex = lineBreakRange.location + lineBreakRange.length
                    }
                    let prefixRange = NSMakeRange(beginningOfLineIndex, range.location + range.length - beginningOfLineIndex)
                    let mutString = NSMutableAttributedString(attributedString: self.textView.attributedText)
                    mutString.replaceCharacters(in: prefixRange, with: "")
                    var endOfLine = mutString.length
                    let nextLineBreakRange = nsString.range(of: "\n", options: NSString.CompareOptions.init(rawValue: 0), range: NSMakeRange(prefixRange.location, mutString.length - prefixRange.location))
                    if nextLineBreakRange.location != NSNotFound {
                        endOfLine = nextLineBreakRange.location
                    }
                    let lineRange = NSMakeRange(prefixRange.location, endOfLine - prefixRange.location)
                    mutString.addAttribute(NSParagraphStyleAttributeName, value: NSParagraphStyle.default, range: lineRange)
                    self.textView.attributedText = mutString
                    attributes[NSParagraphStyleAttributeName] = NSParagraphStyle.default
                    self.textView.typingAttributes = attributes
                    self.textView.selectedRange = NSMakeRange(beginningOfLineIndex, 0)
                    return false
                }
            }
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        let html = styler.convertToHTML(textView.attributedText)
        htmlBox.text = html
    }
}

