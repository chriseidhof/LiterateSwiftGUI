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

func stripLink(child: InlineElement) -> [InlineElement] {
    switch child {
    case let .Link(children, title, url):
        return children
    default:
        return [child]
    }
}


func addFootnote() -> InlineElement -> [InlineElement] {
    var counter = 0
    return { child in
        switch child {
        case let .Link(children, title, url):
            counter++
            return children + [InlineElement.InlineHtml(text: "<sup>\(counter)</sup>")]
        default:
            return [child]
        }
    }
}

func linkURLs(blocks: [Block]) -> [String?] {
    return deepCollect(blocks) { (element: InlineElement) -> [String?] in
        switch element {
        case let .Link(children, title, url):
            return [url]
        default:
            return []
        }

    }
}

func tableOfContents(blocks: [Block]) -> [Block] {
    let headers = deepCollect(blocks) { (b: Block) -> [Block] in
        switch b {
        case let .Header(text, level):
            let prepend = String(Array(count: level, repeatedValue: "#")) + " "
            return [Block.Paragraph(text: [InlineElement.Text(text: prepend)] + text)]
        default: return []
        }
    }
    return [Block.Paragraph(text: [InlineElement.Emphasis(children: ["Table of contents"])])] + headers + [Block.HorizontalRule]
}


class RenderViewController: NSViewController {

    @IBOutlet var webview: WebView!
    
    func loadNode(elements: [Block]) {
        let elements = evaluateAndReplacePrintSwift(tableOfContents(elements) + deepApply(elements, prependLanguage))
        webview.mainFrame.loadHTMLString(document(elements).html, baseURL: nil)
    }
    
    override func viewDidAppear() {
        if let doc = view.window?.windowController()?.document as? MarkdownDocument {
            doc.callbacks.append(self.loadNode)
            loadNode(doc.elements)
        }
    }
}

