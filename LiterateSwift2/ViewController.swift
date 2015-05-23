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

class ViewController: NSViewController {

    @IBOutlet var webview: WebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func loadNode(node: Node?) {
//        webview.mainFrame.loadHTMLString(node?.html, baseURL: nil)
        
        if let node = node {
            
            let children: [Block] = node.children.map{ parseNode($0)! }
            
            let z: [Block] = deepApply(children, prependLanguage)
            let swiftCode: [String] = deepCollect({
                switch $0 {
                case .CodeBlock(let code, let lang) where lang == "swift":
                   return [code]
                default:
                    return []
                    
                }
            })(elements: children)
            println("\n".join(swiftCode))
            
            let doc = document(z)
            webview.mainFrame.loadHTMLString(doc.html, baseURL: nil)
        }
    }
    
    override func viewWillAppear() {
        if let doc = view.window?.windowController()?.document as? MarkdownDocument {
            doc.callback = self.loadNode
            loadNode(doc.node)
        }
    }

    override var representedObject: AnyObject? {
        didSet {
            println("rep \(representedObject)")
        // Update the view, if already loaded.
        }
    }


}

