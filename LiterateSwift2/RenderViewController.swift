//
//  ViewController.swift
//  LiterateSwift2
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Cocoa
import WebKit
import CommonMark
import LiterateSwiftFramework

func prependLanguage(child: Block) -> [Block] {
        switch child {
        case .CodeBlock(let t, let language) where language != nil:
            let explanation = Block.Paragraph(text: [.Text(text: "Example: "), .Emphasis(children: [.Text(text: language!)])])
            return [explanation, child]
        default:
            return [child]
        }
}

class RenderViewController: NSViewController {

    @IBOutlet var webview: WebView!
    
    func loadNode(elements: [Block]) {
        let doc = document(evaluateAndReplacePrintSwift(deepApply(elements, prependLanguage)))
        webview.mainFrame.loadHTMLString(doc.html, baseURL: nil)
    }
    
    override func viewDidAppear() {
        if let doc = view.window?.windowController()?.document as? MarkdownDocument {
            doc.callbacks.append(self.loadNode)
            loadNode(doc.elements)
        }
    }
}

