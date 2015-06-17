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
    guard case let .CodeBlock(_, language) = child where language != nil else { return [child] }

    let explanation = Block.Paragraph(text: [.Text(text: "Example: "), .Emphasis(children: [.Text(text: language!)])])
    return [explanation, child]
}

func stripLink(child: InlineElement) -> [InlineElement] {
    if case let .Link(children, _, _) = child {
        return children
    }
    return [child]
}


func addFootnote() -> InlineElement -> [InlineElement] {
    var counter = 0
    return { child in
        if case let .Link(children, _, _) = child {
            counter++
            return children + [InlineElement.InlineHtml(text: "<sup>\(counter)</sup>")]
        } else {
            return [child]
        }
    }
}

func linkURLs(blocks: [Block]) -> [String?] {
    return deepCollect(blocks) { (element: InlineElement) -> [String?] in
        guard case let .Link(_, _, url) = element else { return [] }
        return [url]
    }
}

func tableOfContents(blocks: [Block]) -> [Block] {
    let headers = deepCollect(blocks) { (b: Block) -> [Block] in
        guard case let .Header(text, level) = b else { return [] }
        let prepend = String(Array(count: level, repeatedValue: "#")) + " "
        return [Block.Paragraph(text: [InlineElement.Text(text: prepend)] + text)]
    }
    return [Block.Paragraph(text: [InlineElement.Emphasis(children: ["Table of contents"])])] + headers + [Block.HorizontalRule]
}


class RenderViewController: NSViewController {

    @IBOutlet var webview: WebView!
    
    func loadNode(fileName: String)(elements: [Block]) {
        let directory = fileName.stringByDeletingLastPathComponent

        let elements = evaluateAndReplacePrintSwift(tableOfContents(elements) + deepApply(elements, { prependLanguage($0).flatMap(replaceSnippet(directory)) }))
        webview.mainFrame.loadHTMLString(Node(blocks: elements).html, baseURL: nil)
    }
    
    override func viewDidAppear() {
        if let doc = view.window?.windowController?.document as? MarkdownDocument {
            let fileName = doc.fileURL!.path!
            let load = self.loadNode(fileName)
            doc.callbacks.append(load)
            load(elements: doc.elements)
        }
    }
}

