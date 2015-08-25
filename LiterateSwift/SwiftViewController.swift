//
//  SwiftViewController.swift
//  LiterateSwift2
//
//  Created by Chris Eidhof on 25/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import CommonMark
import LiterateSwift

class SwiftViewController: NSViewController {

    @IBOutlet var textview: NSTextView?

    func loadNode(elements: [Block]) {
        let text = (deepCollect(elements, { toArray(codeBlock($0, { $0 == "swift" || $0 == "print-swift" })) })).unlines()
        let attributes: [String: AnyObject] = [NSFontAttributeName: NSFont(name: "Monaco", size: 14)!]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        textview?.textStorage?.setAttributedString(attributedString)
    }

    override func viewDidAppear() {
        guard let doc = view.window?.windowController?.document as? MarkdownDocument else { return }
        doc.callbacks.append(self.loadNode)
        loadNode(doc.elements)
    }

}