//
//  SwiftViewController.swift
//  LiterateSwift2
//
//  Created by Chris Eidhof on 25/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import CommonMark
import LiterateSwiftFramework

class SwiftViewController: NSViewController {
    
    @IBOutlet var textview: NSTextView?
    
    func loadNode(elements: [Block]) {
        let text = "\n".join(deepCollect(elements, { toArray(codeBlock($0, { $0 == "swift" || $0 == "print-swift" })) }))
        let attributes: [NSObject: AnyObject] = [NSFontAttributeName: NSFont(name: "Monaco", size: 14)!]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        textview?.textStorage?.setAttributedString(attributedString)
    }

    override func viewDidAppear() {
        if let doc = view.window?.windowController()?.document as? MarkdownDocument {
            doc.callbacks.append(self.loadNode)
            loadNode(doc.elements)
        }
        
    }

}