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
import LiterateSwift

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

func stripSampleImpl(child: Block) -> [Block] {
    guard case let .CodeBlock(code, language) = child where language == "swift" else { return [child] }

    let cleanCode = code.stringByReplacingOccurrencesOfString("_sample_impl", withString: "")
    return [.CodeBlock(text: cleanCode, language: language)]
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
        let prepend = "".join(Array(count: level, repeatedValue: "_")) + " "
        return [Block.Paragraph(text: [InlineElement.Code(text: prepend)] + text)]
    }
    return [Block.Paragraph(text: [InlineElement.Emphasis(children: ["Table of contents"])])] + headers + [Block.HorizontalRule]
}

func replaceOrError(s: String)(b: Block) -> [Block] {
    do {
        return try replaceSnippet(s)(child: b)
    } catch {
        return [Block.CodeBlock(text: "<<Error couldn't find \(s)>>", language: "")]
    }
}


class RenderViewController: NSViewController {

    @IBOutlet var webview: WebView!

    func loadNode(fileName: String)(elements: [Block]) {
        let directory = fileName.stringByDeletingLastPathComponent



        let elements = evaluateAndReplacePrintSwift(tableOfContents(elements) + deepApply(elements, { stripSampleImpl($0).flatMap(replaceOrError(directory)) }))
        let prelude = "<body style='font-family: \"Akkurat TT\", \"Helvetica\"'>"
        let html = prelude + (Node(blocks: elements).html ?? "") + "</body>"
        webview.mainFrame.loadHTMLString(html, baseURL: nil)
    }

    override func viewDidAppear() {
        if let doc = view.window?.windowController?.document as? MarkdownDocument, let fileName = doc.fileURL?.path {
            
            let load = self.loadNode(fileName)
            doc.callbacks.append(load)
            load(elements: doc.elements)
        }
    }
}
