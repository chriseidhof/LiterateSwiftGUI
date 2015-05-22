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

class ViewController: NSViewController {

    @IBOutlet var webview: WebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear() {
        let callback: Node? -> () = { node in
           self.webview.mainFrame.loadHTMLString(node?.html, baseURL: nil)
        }
        if let doc = view.window?.windowController()?.document as? MarkdownDocument {
            doc.callback = callback
            callback(doc.node)
        }
    }

    override var representedObject: AnyObject? {
        didSet {
            println("rep \(representedObject)")
        // Update the view, if already loaded.
        }
    }


}

