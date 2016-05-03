//
//  StyleController.swift
//  Attributed String Editor
//
//  Created by Timothy Purdum on 5/1/16.
//  Copyright © 2016 Cedar River Music. All rights reserved.
//

import Foundation
import UIKit

class StyleController {
    
    var defaultFont = UIFont(name: "Helvetica", size: 16)
    var defaultBold = UIFont(name: "Helvetica-Bold", size: 16)
    var defaultItalic = UIFont(name: "Helvetica-Oblique", size: 16)
    var defaultBoldItalic = UIFont(name: "Helvetica-BoldOblique", size: 16)
    
    func convertAttributedStringToHTML(attributedString: NSAttributedString) -> String {
        
        var fontSize : CGFloat = 16
        var ranges = [Int]()
        var arrayOfBolds = [Int]()
        var arrayOfItalics = [Int]()
        var arrayOfLines = [Int]()
        var arrayOfLists = [Int]()
        var simpleString = attributedString.string
        
        attributedString.enumerateAttributesInRange(NSMakeRange(0, attributedString.length), options: NSAttributedStringEnumerationOptions()) { (dictOfAttrs: [String : AnyObject], range: NSRange, _) -> Void in
            for (attributeName, value) in dictOfAttrs {
                
                if attributeName == NSFontAttributeName {
                    let font = value as! UIFont
                    fontSize = font.pointSize
                    let fontDescriptor = font.fontDescriptor()
                    let symbolicTraits = fontDescriptor.symbolicTraits
                    if symbolicTraits.contains(.TraitBold) {
                        ranges.append(range.location)
                        arrayOfBolds.append(range.location)
                        ranges.append(range.location + range.length)
                        arrayOfBolds.append(range.location + range.length)
                    }
                    if symbolicTraits.contains(.TraitItalic) {
                        ranges.append(range.location)
                        arrayOfItalics.append(range.location)
                        ranges.append(range.location + range.length)
                        arrayOfItalics.append(range.location + range.length)
                    }
                } else if attributeName == NSUnderlineStyleAttributeName {
                    let underlineStyle = value as! Int
                    if underlineStyle == 1 {
                        ranges.append(range.location)
                        arrayOfLines.append(range.location)
                        ranges.append(range.location + range.length)
                        arrayOfLines.append(range.location + range.length)
                    }
                } else if attributeName == NSParagraphStyleAttributeName {
                    if value.headIndent == 36 {
                        print("New paragraph starts at \(range.location)")
                        if arrayOfLists.contains(range.location) {
                            arrayOfLists.removeAtIndex(arrayOfLists.indexOf(range.location)!)
                        } else {
                            ranges.append(range.location)
                            arrayOfLists.append(range.location)
                        }
                        ranges.append(range.location + range.length)
                        arrayOfLists.append(range.location + range.length)
                    } else {
                        print("Non-list paragraph starts at \(range.location)")
                    }
                }
            }
        }
        var shift = 0
        var setOfRanges = Array(Set(ranges))
        setOfRanges.sortInPlace()
        var boldOn = false
        var italicOn = false
        var lineOn = false
        var listStarted = false
        var typeOfList = ""
        for indexOfAttr in setOfRanges {
            if shift < 0 {
                shift = 0
            } else if shift > simpleString.characters.count - 1 {
                shift = simpleString.characters.count  - 1
            }
            if arrayOfBolds.contains(indexOfAttr) {
                if !boldOn {
                    simpleString.insertContentsOf("<b>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                    shift += 3
                    boldOn = true
                } else {
                    simpleString.insertContentsOf("</b>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                    shift += 4
                    boldOn = false
                }
            }
            if arrayOfItalics.contains(indexOfAttr) {
                if !italicOn {
                    simpleString.insertContentsOf("<i>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                    shift += 3
                    italicOn = true
                } else {
                    simpleString.insertContentsOf("</i>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                    shift += 4
                    italicOn = false
                }
            }
            if arrayOfLines.contains(indexOfAttr) {
                if !lineOn {
                    simpleString.insertContentsOf("<u>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                    shift += 3
                    lineOn = true
                } else {
                    simpleString.insertContentsOf("</u>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                    shift += 4
                    lineOn = false
                }
            }
            if arrayOfLists.contains(indexOfAttr) {
                print("String Length: \(simpleString.characters.count), IndexOfAttr: \(indexOfAttr), Shift: \(shift), ListStarted: \(listStarted)")
                if !listStarted {
                    let index = simpleString.startIndex.advancedBy(indexOfAttr + shift)
                    let tabRange = simpleString.rangeOfString("\t", options: NSStringCompareOptions.init(rawValue: 0), range: Range(index.advancedBy(1) ..< simpleString.endIndex), locale: nil)
                    let prefixRange = Range(index ..< tabRange!.endIndex)
                    let prefix = simpleString.substringWithRange(prefixRange)
                    if prefix.containsString("•") {
                        typeOfList = "unordered"
                        print("Found a starting Tab mark!")
                        simpleString.removeRange(prefixRange)
                        shift -= prefixRange.count
                        if shift + indexOfAttr < 1 {
                            simpleString.insertContentsOf("<ul><li>".characters, at: simpleString.startIndex)
                        } else {
                            simpleString.insertContentsOf("<ul><li>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                        }
                        shift += 8
                        listStarted = true
                    } else {
                        typeOfList = "ordered"
                        simpleString.removeRange(prefixRange)
                        shift -= prefixRange.count
                        if shift + indexOfAttr < 1 {
                            simpleString.insertContentsOf("<ol><li>".characters, at: simpleString.startIndex)
                        } else {
                            simpleString.insertContentsOf("<ol><li>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                        }
                        shift += 8
                        listStarted = true
                    }
                } else {
                    if typeOfList == "unordered" {
                        simpleString.insertContentsOf("</li></ul>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                        shift += 10
                        listStarted = false
                    } else {
                        simpleString.insertContentsOf("</li></ol>".characters, at: simpleString.startIndex.advancedBy(indexOfAttr + shift))
                        shift += 10
                        listStarted = false
                    }
                }
                
                
                
            }
        }
        let nsString : NSString = simpleString
        var i = 0
        while i < nsString.length {
            let startOfList = nsString.rangeOfString("<li>", options: NSStringCompareOptions.init(rawValue: 0), range: NSMakeRange(i, nsString.length - i))
            let endOfList = nsString.rangeOfString("</li>", options: NSStringCompareOptions.init(rawValue: 0), range: NSMakeRange(i, nsString.length - i))
            if startOfList.location != NSNotFound && endOfList.location != NSNotFound {
                i = endOfList.location + endOfList.length
                let listRange = NSMakeRange(startOfList.location + startOfList.length, endOfList.location)
                let listString : NSString = nsString.substringWithRange(listRange)
                let newListString = listString.stringByReplacingOccurrencesOfString("\n", withString: "</li>\n<li>")
                nsString.stringByReplacingCharactersInRange(listRange, withString: newListString)
            } else {
                break
            }
        }
        simpleString = simpleString.stringByReplacingOccurrencesOfString("\n", withString: "<br>")
        simpleString = simpleString.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "\n\r"))
        simpleString.insertContentsOf("<div style=\"font-size:\(fontSize)px\">".characters, at: simpleString.startIndex)
        simpleString.insertContentsOf("</div>".characters, at: simpleString.endIndex)
        return simpleString
    }
    
    func convertHTMLToAttributedString(html: String) -> NSAttributedString {
        var attrString : NSAttributedString
        do {
            attrString = try NSAttributedString(data: html.dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding], documentAttributes: nil)
        } catch {
            print("Error in decoding HTML")
            attrString = NSAttributedString(string: html)
        }
        return attrString
    }
    
    func insertStyleAttribute(style: String, selectedRange: NSRange, text: NSAttributedString) -> NSAttributedString {
        print("Selected range: Location \(selectedRange.location) Length \(selectedRange.length)")
        let textNSString : NSString = text.string
        let newString = NSMutableAttributedString(attributedString: text)
        switch style {
        case "ordered", "unordered":
            //BULLETS & NUMBERS
            var newOrder = true
            
            let previousLineBreak = textNSString.rangeOfString("\n", options: NSStringCompareOptions.BackwardsSearch, range: NSMakeRange(0, selectedRange.location), locale: nil)
            let nextLineBreak = textNSString.rangeOfString("\n", options: NSStringCompareOptions.init(rawValue: 0), range: NSMakeRange(selectedRange.location + selectedRange.length, textNSString.length - selectedRange.location - selectedRange.length), locale: nil)
            var lineRange = NSRange()
            if previousLineBreak.location == NSNotFound && nextLineBreak.location == NSNotFound {
                lineRange = NSMakeRange(0, textNSString.length)
            } else if previousLineBreak.location == NSNotFound {
                lineRange = NSMakeRange(0, nextLineBreak.location)
            } else if nextLineBreak.location == NSNotFound {
                lineRange = NSMakeRange(previousLineBreak.location + previousLineBreak.length, textNSString.length - previousLineBreak.length - previousLineBreak.location)
            } else {
                lineRange = NSMakeRange(previousLineBreak.location + previousLineBreak.length, nextLineBreak.location - previousLineBreak.length - previousLineBreak.location)
            }
            let line = NSAttributedString(attributedString: text.attributedSubstringFromRange(lineRange))
            var htmlLine = convertAttributedStringToHTML(line)
            print("HTML Line: \(htmlLine)")
            if style == "ordered" {
                if htmlLine.containsString("<ol>") {
                    htmlLine.removeRange(htmlLine.rangeOfString("<ol>")!)
                }
                if htmlLine.containsString("</ol>") {
                    htmlLine.removeRange(htmlLine.rangeOfString("</ol>")!)
                }
            } else {
                if htmlLine.containsString("<ul>") {
                    htmlLine.removeRange(htmlLine.rangeOfString("<ul>")!)
                }
                if htmlLine.containsString("</ul>") {
                    htmlLine.removeRange(htmlLine.rangeOfString("</ul>")!)
                }
            }
            while htmlLine.containsString("<li>") {
                htmlLine.removeRange(htmlLine.rangeOfString("<li>")!)
                newOrder = false
                print("Already was a list! Removing...")
            }
            while htmlLine.containsString("</li>") {
                htmlLine.removeRange(htmlLine.rangeOfString("</li>")!)
            }
            
            if newOrder {
                if style == "ordered" {
                    htmlLine.insertContentsOf("<ol><li>".characters, at: htmlLine.startIndex)
                    htmlLine.insertContentsOf("</li></ol>".characters, at: htmlLine.endIndex)
                } else {
                    htmlLine.insertContentsOf("<ul><li>".characters, at: htmlLine.startIndex)
                    htmlLine.insertContentsOf("</li></ul>".characters, at: htmlLine.endIndex)
                }
                htmlLine = htmlLine.stringByReplacingOccurrencesOfString("<br>", withString: "</li><br><li>")
            }
            let newAttrLine = NSMutableAttributedString(attributedString: convertHTMLToAttributedString(htmlLine))
            let newNSStringLine : NSString = newAttrLine.string
            let endStop = newNSStringLine.rangeOfString("\n", options: NSStringCompareOptions.BackwardsSearch, range: NSMakeRange(0, newNSStringLine.length))
            newAttrLine.replaceCharactersInRange(endStop, withString: "")
            newString.replaceCharactersInRange(lineRange, withAttributedString: newAttrLine)
        case "underline":
            var addUnderline = true
            newString.enumerateAttributesInRange(selectedRange, options: NSAttributedStringEnumerationOptions()) {
                (dictOfAttrs: [String : AnyObject], range: NSRange, _) -> Void in
                for (attrName, existing) in dictOfAttrs {
                    if attrName == NSUnderlineStyleAttributeName {
                        let lineStyle = existing as? Int
                        if lineStyle == NSUnderlineStyle.StyleSingle.rawValue {
                            addUnderline = false
                            let newStyle = NSUnderlineStyle.StyleNone.rawValue
                            newString.removeAttribute(NSUnderlineStyleAttributeName, range: selectedRange)
                            newString.addAttribute(NSUnderlineStyleAttributeName, value: newStyle, range: selectedRange)
                        }
                    }
                }
            }
            if addUnderline {
                let newStyle = NSUnderlineStyle.StyleSingle.rawValue
                newString.addAttribute(NSUnderlineStyleAttributeName, value: newStyle, range: selectedRange)
            }
        case "bold":
            var addBold = true
            newString.enumerateAttributesInRange(selectedRange, options: NSAttributedStringEnumerationOptions()) {
                (dictOfAttrs: [String : AnyObject], range: NSRange, _) -> Void in
                for (attrName, existing) in dictOfAttrs {
                    if attrName == NSFontAttributeName {
                        if existing as! NSObject == self.defaultBold! {
                            addBold = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultFont!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultItalic! {
                            addBold = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultBoldItalic!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultBoldItalic! {
                            addBold = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultItalic!, range: selectedRange)
                        }
                    }
                }
            }
            if addBold {
                newString.addAttribute(NSFontAttributeName, value: defaultBold!, range: selectedRange)
            }
        case "italic":
            var addItalic = true
            newString.enumerateAttributesInRange(selectedRange, options: NSAttributedStringEnumerationOptions()) {
                (dictOfAttrs: [String : AnyObject], range: NSRange, _) -> Void in
                for (attrName, existing) in dictOfAttrs {
                    if attrName == NSFontAttributeName {
                        if existing as! NSObject == self.defaultItalic! {
                            addItalic = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultFont!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultBold! {
                            addItalic = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultBoldItalic!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultBoldItalic! {
                            addItalic = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultBold!, range: selectedRange)
                        }
                    }
                }
            }
            if addItalic {
                newString.addAttribute(NSFontAttributeName, value: defaultItalic!, range: selectedRange)
            }
        default:
            break
        }
        return newString
    }
    
    func checkListStyle(text: NSAttributedString, range: NSRange) -> (String, Int?) {
        var style = "normal"
        var lineNum : Int?
        text.enumerateAttribute(NSParagraphStyleAttributeName, inRange: range, options: NSAttributedStringEnumerationOptions()) {
            (attribute, range: NSRange, _) -> Void in
            let paragraph = attribute as? NSParagraphStyle
            if paragraph != nil {
                let textNSString : NSString = text.string
                if paragraph!.headIndent == 30 {
                    if textNSString.containsString("•\t") {
                        style = "unordered"
                    } else {
                        style = "ordered"
                        let tabStop = textNSString.rangeOfString("\t")
                        var beforeTab : NSString = textNSString.substringToIndex(tabStop.location)
                        if beforeTab.containsString("\n") {
                            let lineBreak = beforeTab.rangeOfString("\n", options: NSStringCompareOptions.BackwardsSearch)
                            beforeTab = beforeTab.substringFromIndex(lineBreak.location + lineBreak.length)
                        }
                        if Int(beforeTab as String) != nil {
                            lineNum = Int(beforeTab as String)
                        }
                    }
                }
            }
        }
        return (style, lineNum)
    }
}