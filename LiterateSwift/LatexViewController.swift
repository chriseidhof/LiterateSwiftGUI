//
//  LatexViewController.swift
//  LiterateSwift
//
//  Created by Chris Eidhof on 17/07/15.
//  Copyright © 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import CommonMark
import LiterateSwift


class LatexViewController: NSViewController {
    @IBOutlet var textview: NSTextView?

    func loadNode(elements: [Block]) {
        let text = latexString(elements)
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
