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

enum PlaygroundNode {
    case Comment(Block)
    case Code(String)
}

func convert(blocks: [Block]) -> [PlaygroundNode] {
    return blocks.map {
        if let code = codeBlock($0, { $0 == "swift" || $0 == "print-swift" }) {
            return .Code(code)
        } else {
            return .Comment($0)
        }
    }
}

extension String {
    var lines: [String] {
        return componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
}

extension SequenceType where Generator.Element == String {
    func unlines() -> String {
        return "\n".join(self)
    }
}


func render(nodes: [PlaygroundNode]) -> String {
    let strings: [String] = nodes.map {
        switch $0 {
        case .Comment(let c): return Node(blocks: [c]).commonMark!.lines.map { "//: " + $0 }.unlines()
        case .Code(let c): return c
        }
    }
    return "\n".join(strings)
}

class PlaygroundViewController: NSViewController {

    @IBOutlet var textview: NSTextView?


    func loadNode(elements: [Block]) {
        let text = render(convert(elements))
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