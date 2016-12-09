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
    
    var defaultFont : AnyObject?
    var defaultBold : AnyObject?
    var defaultItalic : AnyObject?
    var defaultBoldItalic : AnyObject?
    
    init() {
        #if os(iOS)
            defaultFont = UIFont(name: "Optima", size: 16)
            defaultBold = UIFont(name: "Optima-Bold", size: 16)
            defaultItalic = UIFont(name: "Optima-Italic", size: 16)
            defaultBoldItalic = UIFont(name: "Optima-BoldItalic", size: 16)
        #elseif os(OSX)
            defaultFont = NSFont(name: "Optima", size: 16)
            defaultBold = NSFont(name: "Optima-Bold", size: 16)
            defaultItalic = NSFont(name: "Optima-Italic", size: 16)
            defaultBoldItalic = NSFont(name: "Optima-BoldItalic", size: 16)
        #endif
    }
    
    func convertHTMLToAttributedString(_ html: String) -> NSAttributedString {
        var newHTML = html
        var imageCount = 0
        while newHTML.contains("<img") {
            let tagStart = newHTML.range(of: "<img")
            let tagEnd = newHTML.range(of: ">", options: NSString.CompareOptions.init(rawValue: 0), range: Range(tagStart!.upperBound..<newHTML.endIndex), locale: nil)
            if tagEnd != nil {
                let folderTag = newHTML.range(of: "images/")
                if folderTag != nil {
                    let endTag = newHTML.range(of: "png", options: NSString.CompareOptions.init(rawValue: 0), range: Range(folderTag!.upperBound..<newHTML.endIndex), locale: nil)
                    if endTag != nil {
                        newHTML.replaceSubrange(Range(tagStart!.lowerBound..<tagEnd!.upperBound), with: "*IMAGE\(imageCount)*")
                        imageCount += 1
                    } else {
                        break
                    }
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        if newHTML.hasSuffix("</ol>") {
            newHTML = newHTML.replacingOccurrences(of: "</ol>", with: "")
        }
        if newHTML.hasSuffix("</ul>") {
            newHTML = newHTML.replacingOccurrences(of: "</ul>", with: "")
        }
        var attrString : NSMutableAttributedString
        do {
            attrString = try NSMutableAttributedString(data: newHTML.data(using: String.Encoding.utf8)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
        } catch {
            print("Error in decoding HTML")
            attrString = NSMutableAttributedString(string: newHTML)
        }
        attrString.enumerateAttributes(in: NSMakeRange(0, attrString.length), options: NSAttributedString.EnumerationOptions.init(rawValue: 0)) { (dictOfAttrs : [String: Any], range, _) in
            for (name, value) in dictOfAttrs {
                if name == NSFontAttributeName {
                    
                    #if os(iOS)
                        let font = value as! UIFont
                        let newFont = font.withSize(16)
                    #elseif os(OSX)
                        let font = value as! NSFont
                        let manager = NSFontManager()
                        let newFont = manager.convert(font, toSize: 16)
                    #endif
                    
                    attrString.removeAttribute(name, range: range)
                    attrString.addAttribute(name, value: newFont, range: range)
                }
            }
        }
        var trimRange = (attrString.string as NSString).rangeOfCharacter(from: NSCharacterSet(charactersIn: "\n") as CharacterSet, options: NSString.CompareOptions.backwards)
        while trimRange.length != 0 && NSMaxRange(trimRange) == attrString.length {
            attrString.replaceCharacters(in: trimRange, with: "")
            trimRange = (attrString.string as NSString).rangeOfCharacter(from: NSCharacterSet(charactersIn: "\n") as CharacterSet, options: NSString.CompareOptions.backwards)
        }
        return attrString
    }
    
    func convertToHTML(_ stringObject: NSObject) -> String {
        let attributedString = stringObject as? NSAttributedString
        
        var ranges = [Int]()
        var arrayOfBolds = [Int]()
        var arrayOfItalics = [Int]()
        var arrayOfLines = [Int]()
        var simpleString = attributedString!.string
        var arrayOfImages = [Int: [Int]]()
        
        attributedString!.enumerateAttributes(in: NSMakeRange(0, attributedString!.length), options: NSAttributedString.EnumerationOptions()) { (dictOfAttrs: [String : Any], range: NSRange, _) -> Void in
            for (attributeName, value) in dictOfAttrs {
                
                if attributeName == NSFontAttributeName {
                    #if os(iOS)
                        let font = value as! UIFont
                        let fontDescriptor = font.fontDescriptor
                        let symbolicTraits = fontDescriptor.symbolicTraits
                        if symbolicTraits.contains(.traitBold) {
                            ranges.append(range.location)
                            arrayOfBolds.append(range.location)
                            ranges.append(range.location + range.length)
                            arrayOfBolds.append(range.location + range.length)
                        }
                        if symbolicTraits.contains(.traitItalic) {
                            ranges.append(range.location)
                            arrayOfItalics.append(range.location)
                            ranges.append(range.location + range.length)
                            arrayOfItalics.append(range.location + range.length)
                        }
                    #elseif os(OSX)
                        let font = value as! NSFont
                        let fontDescriptor = font.fontDescriptor
                        let symbolicTraits = fontDescriptor.symbolicTraits
                        
                        let isBold = 0 != (symbolicTraits & NSFontSymbolicTraits(NSFontBoldTrait))
                        if isBold {
                            ranges.append(range.location)
                            arrayOfBolds.append(range.location)
                            ranges.append(range.location + range.length)
                            arrayOfBolds.append(range.location + range.length)
                        }
                        let isItalic = 0 != (symbolicTraits & NSFontSymbolicTraits(NSFontItalicTrait))
                        if isItalic {
                            ranges.append(range.location)
                            arrayOfItalics.append(range.location)
                            ranges.append(range.location + range.length)
                            arrayOfItalics.append(range.location + range.length)
                        }
                    #endif
                    
                    
                } else if attributeName == NSUnderlineStyleAttributeName {
                    let underlineStyle = value as! Int
                    if underlineStyle == 1 {
                        ranges.append(range.location)
                        arrayOfLines.append(range.location)
                        ranges.append(range.location + range.length)
                        arrayOfLines.append(range.location + range.length)
                    }
                } else if attributeName == NSAttachmentAttributeName {
                    let attachment = value as! NSTextAttachment
                    #if os(iOS)
                        var image = attachment.image
                        if image == nil {
                            print("Saving image from bounds")
                            image = attachment.image(forBounds: attachment.bounds, textContainer: nil, characterIndex: range.location)
                        }
                    #elseif os(OSX)
                        var image : NSImage?
                        image = attachment.image
                        if image == nil {
                            print("Saving image from bounds")
                            image = attachment.image(forBounds: attachment.bounds, textContainer: nil, characterIndex: range.location)
                        }
                        
                    #endif
                }
            }
        }
        var shift = 0
        var setOfRanges = Array(Set(ranges))
        setOfRanges.sort()
        var boldOn = false
        var italicOn = false
        var lineOn = false
        for indexOfAttr in setOfRanges {
            if shift < 0 {
                shift = 0
            } else if shift > simpleString.characters.count - 1 {
                shift = simpleString.characters.count  - 1
            }
            if arrayOfBolds.contains(indexOfAttr) {
                if !boldOn {
                    simpleString.insert(contentsOf: "<b>".characters, at: simpleString.index(simpleString.startIndex, offsetBy: indexOfAttr + shift))
                    shift += 3
                    boldOn = true
                } else {
                    simpleString.insert(contentsOf: "</b>".characters, at: simpleString.index(simpleString.startIndex, offsetBy: indexOfAttr + shift))
                    shift += 4
                    boldOn = false
                }
            }
            if arrayOfItalics.contains(indexOfAttr) {
                if !italicOn {
                    simpleString.insert(contentsOf: "<i>".characters, at: simpleString.index(simpleString.startIndex, offsetBy: indexOfAttr + shift))
                    shift += 3
                    italicOn = true
                } else {
                    simpleString.insert(contentsOf: "</i>".characters, at: simpleString.index(simpleString.startIndex, offsetBy: indexOfAttr + shift))
                    shift += 4
                    italicOn = false
                }
            }
            if arrayOfLines.contains(indexOfAttr) {
                if !lineOn {
                    simpleString.insert(contentsOf: "<u>".characters, at: simpleString.index(simpleString.startIndex, offsetBy: indexOfAttr + shift))
                    shift += 3
                    lineOn = true
                } else {
                    simpleString.insert(contentsOf: "</u>".characters, at: simpleString.index(simpleString.startIndex, offsetBy: indexOfAttr + shift))
                    shift += 4
                    lineOn = false
                }
            }
            if arrayOfImages[indexOfAttr] != nil {
                let fileName = "\(arrayOfImages[indexOfAttr]![0]).png"
                let tag = "<img src=\"images/\(fileName)\" width=\(arrayOfImages[indexOfAttr]![1]) height=\(arrayOfImages[indexOfAttr]![2])>"
                let insertPoint = simpleString.index(simpleString.startIndex, offsetBy: indexOfAttr + shift)
                simpleString.remove(at: insertPoint)
                shift -= 1
                simpleString.insert(contentsOf: tag.characters, at: insertPoint)
                shift += tag.characters.count
            }
        }
        
        //Move closing brackets to the ends of lines
        simpleString = simpleString.replacingOccurrences(of: "\n</i>", with: "</i>\n")
        simpleString = simpleString.replacingOccurrences(of: "\n</i>", with: "</i>\n")
        simpleString = simpleString.replacingOccurrences(of: "\n</i>", with: "</i>\n")
        
        //FIND LISTS
        let splitByLines = simpleString.components(separatedBy: "\n")
        
        var bulletsStarted = false
        var numbersStarted = false
        var number = 1
        var newLines : [String] = []
        for i in 0..<splitByLines.count {
            var section = splitByLines[i].trimmingCharacters(in: NSCharacterSet(charactersIn: " ") as CharacterSet)
            if !section.isEmpty {
                if section[section.startIndex] == "\t" {
                    if section.characters.count > 1 && section[section.index(section.startIndex, offsetBy: 1)] == "•" && section[section.index(section.startIndex, offsetBy: 2)] == "\t" {
                        
                        //Line starts with a bullet!
                        
                        //Finish Old Lists
                        if numbersStarted {
                            newLines[i - 1].append("</ol>")
                            numbersStarted = false
                        }
                        
                        if !bulletsStarted {
                            //Start new bulleted list
                            section = section.replacingOccurrences(of: "\t•\t", with: "<ul><li>")
                            bulletsStarted = true
                        } else {
                            //Continue bullets
                            section = section.replacingOccurrences(of: "\t•\t", with: "<li>")
                        }
                        //Close list item
                        section.append("</li>")
                        
                    } else if Int(String(section[section.index(section.startIndex, offsetBy: 1)])) != nil {
                        //Line starts with a number!
                        
                        //Finish old bullet lists
                        if bulletsStarted {
                            newLines[i - 1].append("</ul>")
                            bulletsStarted = false
                        }
                        //find the period after the number
                        let periodRange = section.range(of: ".")
                        if periodRange != nil {
                            //find the number range (between tabs)
                            let prefixRange = Range(section.index(section.startIndex, offsetBy: 1)..<periodRange!.lowerBound)
                            let prefix = section.substring(with: prefixRange)
                            if Int(prefix) != nil {
                                //Line starts with a number!
                                number = Int(prefix)!
                                if !numbersStarted {
                                    //Begin numbered list
                                    section = section.replacingOccurrences(of: "\t\(number).\t", with: "<ol start=\"\(number)\"><li>")
                                    numbersStarted = true
                                } else {
                                    //Continue numbered list
                                    section = section.replacingOccurrences(of: "\t\(number).\t", with: "<li>")
                                }
                                //Close list items
                                section.append("</li>")
                            } else {
                                if i > 0 {
                                    if numbersStarted {
                                        newLines[i - 1].append("</ol>")
                                        numbersStarted = false
                                    }
                                    if bulletsStarted {
                                        newLines[i - 1].append("</ul>")
                                        bulletsStarted = false
                                    }
                                }
                            }
                        } else {
                            if i > 0 {
                                if numbersStarted {
                                    newLines[i - 1].append("</ol>")
                                    numbersStarted = false
                                }
                                if bulletsStarted {
                                    newLines[i - 1].append("</ul>")
                                    bulletsStarted = false
                                }
                            }
                        }
                    } else {
                        if i > 0 {
                            if numbersStarted {
                                newLines[i - 1].append("</ol>")
                                numbersStarted = false
                            }
                            if bulletsStarted {
                                newLines[i - 1].append("</ul>")
                                bulletsStarted = false
                            }
                        }
                    }
                } else {
                    if i > 0 {
                        if numbersStarted {
                            newLines[i - 1].append("</ol>")
                            numbersStarted = false
                        }
                        if bulletsStarted {
                            newLines[i - 1].append("</ul>")
                            bulletsStarted = false
                        }
                    }
                }
            }
            newLines.append(section)
        }
        var newString = ""
        for j in 0..<newLines.count {
            newString += newLines[j]
            if j < newLines.count - 1 {
                if !newLines[j].hasSuffix("</li>") && !newLines[j].hasSuffix("</ol>") && !newLines[j].hasSuffix("</ul>") {
                    newString += "<br>"
                }
            } else {
                if bulletsStarted {
                    newString += "</ul>"
                }
                if numbersStarted {
                    newString += "</ol>"
                }
            }
        }
        
        simpleString = newString.trimmingCharacters(in: NSCharacterSet(charactersIn: "\n\r") as CharacterSet)
 
        return simpleString
    }
    
    
    func insertStyleAttribute(_ style: String, selectedRange: NSRange, text: NSAttributedString) -> (NSAttributedString, NSRange) {
        print("Selected range: Location \(selectedRange.location) Length \(selectedRange.length)")
        let textNSString : NSString = text.string as NSString
        let newString = NSMutableAttributedString(attributedString: text)
        var newRange = selectedRange
        switch style {
        case "ordered", "unordered":
            //BULLETS & NUMBERS
            var newOrder = true
            print("Original string: \(textNSString)")
            //Search for existing list
            let previousLineBreak = textNSString.range(of: "\n", options: NSString.CompareOptions.backwards, range: NSMakeRange(0, selectedRange.location), locale: nil)
            let nextLineBreak = textNSString.range(of: "\n", options: NSString.CompareOptions.init(rawValue: 0), range: NSMakeRange(selectedRange.location + selectedRange.length, textNSString.length - selectedRange.location - selectedRange.length), locale: nil)
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
            let line = NSAttributedString(attributedString: text.attributedSubstring(from: lineRange))
            var htmlLine = convertToHTML(line)
            if style == "ordered" {
                if htmlLine.contains("<ol") {
                    let opening = htmlLine.range(of: "<ol")
                    let closing = htmlLine.range(of: ">", options: NSString.CompareOptions.init(rawValue: 0), range: Range(opening!.upperBound..<htmlLine.endIndex), locale: nil)
                    htmlLine.removeSubrange(Range(opening!.lowerBound..<closing!.upperBound))
                }
                if htmlLine.contains("</ol>") {
                    htmlLine.removeSubrange(htmlLine.range(of: "</ol>")!)
                }
            } else {
                if htmlLine.contains("<ul>") {
                    htmlLine.removeSubrange(htmlLine.range(of: "<ul>")!)
                }
                if htmlLine.contains("</ul>") {
                    htmlLine.removeSubrange(htmlLine.range(of: "</ul>")!)
                }
            }
            while htmlLine.contains("<li>") {
                htmlLine.removeSubrange(htmlLine.range(of: "<li>")!)
                newOrder = false
                print("Already was a list! Removing...")
                if style == "ordered" {
                    newRange = NSMakeRange(newRange.location - 4, newRange.length)
                } else {
                    newRange = NSMakeRange(newRange.location - 3, newRange.length)
                }
            }
            while htmlLine.contains("</li>") {
                htmlLine.removeSubrange(htmlLine.range(of: "</li>")!)
            }
            
            if newOrder {
                if style == "ordered" {
                    var start = ""
                    var before = ""
                    var shift = 4
                    if htmlLine.contains(".") {
                        let period = htmlLine.range(of: ".")
                        before = htmlLine.substring(to: period!.lowerBound)
                        if Int(before) != nil {
                            start = " start=\(before)"
                            htmlLine = htmlLine.substring(from: period!.upperBound)
                            shift = 1
                        }
                    }
                    htmlLine.insert(contentsOf: "<ol\(start)><li>".characters, at: htmlLine.startIndex)
                    htmlLine.insert(contentsOf: "</li></ol>".characters, at: htmlLine.endIndex)
                    newRange = NSMakeRange(newRange.location + shift, newRange.length)
                } else {
                    var shift = 3
                    if htmlLine.hasPrefix("- ") {
                        htmlLine = htmlLine.substring(from: htmlLine.index(htmlLine.startIndex, offsetBy: 2))
                        shift = 1
                    }
                    
                    htmlLine.insert(contentsOf: "<ul><li>".characters, at: htmlLine.startIndex)
                    htmlLine.insert(contentsOf: "</li></ul>".characters, at: htmlLine.endIndex)
                    newRange = NSMakeRange(newRange.location + shift, newRange.length)
                }
                htmlLine = htmlLine.replacingOccurrences(of: "<br>", with: "</li><li>")
            }
            let newAttrLine = NSMutableAttributedString(attributedString: convertHTMLToAttributedString(htmlLine))
            newString.replaceCharacters(in: lineRange, with: newAttrLine)
            print("List line: \(newString.string)")
            
        case "underline":
            var addUnderline = true
            newString.enumerateAttributes(in: selectedRange, options: NSAttributedString.EnumerationOptions()) {
                (dictOfAttrs: [String : Any], range: NSRange, _) -> Void in
                for (attrName, existing) in dictOfAttrs {
                    if attrName == NSUnderlineStyleAttributeName {
                        let lineStyle = existing as? Int
                        if lineStyle == NSUnderlineStyle.styleSingle.rawValue {
                            addUnderline = false
                            let newStyle = NSUnderlineStyle.styleNone.rawValue
                            newString.removeAttribute(NSUnderlineStyleAttributeName, range: selectedRange)
                            newString.addAttribute(NSUnderlineStyleAttributeName, value: newStyle, range: selectedRange)
                        }
                    }
                }
            }
            if addUnderline {
                let newStyle = NSUnderlineStyle.styleSingle.rawValue
                newString.addAttribute(NSUnderlineStyleAttributeName, value: newStyle, range: selectedRange)
            }
        case "bold":
            var addBold = true
            newString.enumerateAttributes(in: selectedRange, options: NSAttributedString.EnumerationOptions()) {
                (dictOfAttrs: [String : Any], range: NSRange, _) -> Void in
                for (attrName, existing) in dictOfAttrs {
                    if attrName == NSFontAttributeName {
                        if existing as! NSObject == self.defaultBold! as! NSObject {
                            addBold = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultFont!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultItalic! as! NSObject {
                            addBold = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultBoldItalic!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultBoldItalic! as! NSObject {
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
            newString.enumerateAttributes(in: selectedRange, options: NSAttributedString.EnumerationOptions()) {
                (dictOfAttrs: [String : Any], range: NSRange, _) -> Void in
                for (attrName, existing) in dictOfAttrs {
                    if attrName == NSFontAttributeName {
                        if existing as! NSObject == self.defaultItalic! as! NSObject {
                            addItalic = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultFont!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultBold! as! NSObject {
                            addItalic = false
                            newString.removeAttribute(NSFontAttributeName, range: selectedRange)
                            newString.addAttribute(NSFontAttributeName, value: self.defaultBoldItalic!, range: selectedRange)
                        } else if existing as! NSObject == self.defaultBoldItalic! as! NSObject {
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
        return (newString, newRange)
    }
    
    func checkNewLineParagraphStyle(text: NSAttributedString, range: NSRange) -> (NSAttributedString, Bool, NSRange) {
        let stringText : NSString = text.string as NSString
        let tabRange = stringText.range(of: "\t", options: NSString.CompareOptions.backwards, range: NSMakeRange(0, range.location))
        if tabRange.location != NSNotFound {
            let previousTabRange = stringText.range(of: "\t", options: NSString.CompareOptions.backwards, range: NSMakeRange(0, tabRange.location))
            if previousTabRange.location != NSNotFound {
                let tabSign = stringText.substring(with: NSMakeRange(previousTabRange.location + previousTabRange.length, tabRange.location - previousTabRange.location - previousTabRange.length))
                //Check if this line is empty
                let lineBreakRange = stringText.range(of: "\n", options: NSString.CompareOptions.init(rawValue: 0), range: NSMakeRange(tabRange.location + tabRange.length, stringText.length - tabRange.location - tabRange.length))
                var endLineIndex = stringText.length
                if lineBreakRange.location != NSNotFound {
                    endLineIndex = lineBreakRange.location
                }
                let lineContent = stringText.substring(with: NSMakeRange(tabRange.location + tabRange.length, endLineIndex - tabRange.location - tabRange.length))
                print("Line content: \(lineContent)")
                if !lineContent.isEmpty {
                    var replacementString = "\n\t•\t"
                    if !tabSign.contains("•") {
                        let numString = tabSign.trimmingCharacters(in: NSCharacterSet(charactersIn: ".\t") as CharacterSet)
                        if let tabNum = Int(numString) {
                            replacementString = "\n\t\(tabNum + 1).\t"
                        }
                    }
                    let mutString = NSMutableAttributedString(attributedString: text)
                    mutString.replaceCharacters(in: range, with: replacementString)
                    return (mutString, true, (NSMakeRange(range.location + replacementString.characters.count, 0)))
                }
            }
        }
        return (text, false, range)
    }
}

extension NSAttributedString {
    func replaceHTMLTag(tag: String, withAttributes attributes: [String: AnyObject]) -> NSAttributedString {
        let openTag = "<\(tag)>"
        let closeTag = "</\(tag)>"
        let resultingText: NSMutableAttributedString = self.mutableCopy() as! NSMutableAttributedString
        while true {
            let plainString = resultingText.string as NSString
            let openTagRange = plainString.range(of: openTag)
            if openTagRange.length == 0 {
                break
            }
            
            let affectedLocation = openTagRange.location + openTagRange.length
            
            let searchRange = NSMakeRange(affectedLocation, plainString.length - affectedLocation)
            
            let closeTagRange = plainString.range(of: closeTag, options: NSString.CompareOptions(rawValue: 0), range: searchRange)
            
            resultingText.setAttributes(attributes, range: NSMakeRange(affectedLocation, closeTagRange.location - affectedLocation))
            resultingText.deleteCharacters(in: closeTagRange)
            resultingText.deleteCharacters(in: openTagRange)
        }
        return resultingText as NSAttributedString
    }
}

class StringCleaner {
    func decode(downloadedString: String) -> String {
        var decodeString = downloadedString
        while decodeString.range(of: "&#") != nil {
            let rangeOfUnicode = decodeString.range(of: "&#")
            let endOfRange = decodeString.range(of: ";", options: .literal, range: Range(rangeOfUnicode!.upperBound ..< decodeString.endIndex), locale: nil)
            if rangeOfUnicode != nil && endOfRange != nil {
                if decodeString.characters.distance(from: rangeOfUnicode!.lowerBound, to: endOfRange!.upperBound) > 0 {
                    let unicode = decodeString[Range(rangeOfUnicode!.upperBound ..< endOfRange!.lowerBound)]
                    if let unicodeInt = Int(unicode) {
                        let unicodeScalar = UnicodeScalar(unicodeInt)
                        print("Replacing unicode \(unicodeInt) with \(unicodeScalar)")
                        decodeString = decodeString.replacingOccurrences(of: "&#\(unicodeInt);", with: "\(unicodeScalar)")
                    }
                }
            }
        }
        
        let listOfThingsToDecode = ["&amp;" : "&", "&lt;" : "<", "&gt;" : ">", "&quot;" : "\"", "&apos;" : "'", "Ã" : "", "Â" : "", "ƒ" : "", "€" : "", "œ" : "", "&copy;" : "©"]
        
        for (thing, replace) in listOfThingsToDecode {
            decodeString = decodeString.replacingOccurrences(of: thing, with: replace)
        }
        
        return decodeString
    }
}

#if os(iOS)
    extension UIImage {
        func scaleImage(newSize: CGSize)-> UIImage {
            UIGraphicsBeginImageContext(newSize)
            self.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }
    }
#elseif os(OSX)
    extension NSImage {
        func scaleImage(newSize: CGSize) -> NSImage {
            let img = NSImage(size: newSize)
            img.lockFocus()
            let ctx = NSGraphicsContext.current()
            ctx?.imageInterpolation = .high
            self.draw(in: NSRect(origin: CGPoint.zero, size: newSize), from: NSRect(origin: CGPoint.zero, size: size), operation: NSCompositingOperation.copy, fraction: 1)
            img.unlockFocus()
            
            return img
        }
    }
#endif

extension String {
    func encodeAmpersand()-> String {
        return self.replacingOccurrences(of: "&", with: "%26")
    }
}
