//
//  CommonMark.swift
//  CommonMark
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation

func stringUnlessNil(p: UnsafePointer<Int8>) -> String? {
    return p == nil ? nil : String(UTF8String: p)
}

public func markdownToHTML(markdown: String) -> String? {
    if let cString = markdown.cStringUsingEncoding(NSUTF8StringEncoding) {
        let byteSize = markdown.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        let outString = cmark_markdown_to_html(cString, Int32(byteSize), 0)
        return String(UTF8String: outString)
    }
    return nil
}

public func parseFile(filename: String) -> Node? {
    let parsed = cmark_parse_file(fopen(filename, "r"), 0)
    if parsed == nil {
        return nil
    } else {
        return Node(node: parsed)
    }
}

public class Node: Printable {
    let node: COpaquePointer
    
    init(node: COpaquePointer) {
        self.node = node
    }
    
    init(type: cmark_node_type) {
        self.node = cmark_node_new(type)
    }
    
    deinit {
        if type.value == CMARK_NODE_DOCUMENT.value {
            cmark_node_free(node)
        }
    }
    
    public var type: cmark_node_type {
        return cmark_node_get_type(node)
    }
    
    public var listType: cmark_list_type {
        get { return cmark_node_get_list_type(node) }
        set { cmark_node_set_list_type(node, newValue) }
    }
    
    public var listStart: Int {
        get { return Int(cmark_node_get_list_start(node)) }
        set { cmark_node_set_list_start(node, Int32(newValue)) }
    }
    
    public var typeString: String {
        return String(UTF8String: cmark_node_get_type_string(node))!
    }
    
    public var literal: String? {
        get { return stringUnlessNil(cmark_node_get_literal(node)) }
        set {
          if let value = newValue {
              cmark_node_set_literal(node, value)
          } else {
              cmark_node_set_literal(node, nil)
          }
        }
    }
    
    public var headerLevel: Int {
        get { return Int(cmark_node_get_header_level(node)) }
        set { cmark_node_set_header_level(node, Int32(newValue)) }
    }
    
    public var fenceInfo: String? {
        get { return stringUnlessNil(cmark_node_get_fence_info(node)) }
        set {
          if let value = newValue {
              cmark_node_set_fence_info(node, value)
          } else {
              cmark_node_set_fence_info(node, nil)
          }
        }
    }
    
    public var urlString: String? {
        get { return stringUnlessNil(cmark_node_get_url(node)) }
        set {
          if let value = newValue {
              cmark_node_set_url(node, value)
          } else {
              cmark_node_set_url(node, nil)
          }
        }
    }
    
    public var title: String? {
        get { return stringUnlessNil(cmark_node_get_title(node)) }
        set {
          if let value = newValue {
              cmark_node_set_title(node, value)
          } else {
              cmark_node_set_title(node, nil)
          }
        }
    }
    
    public var children: [Node] {
        get {
            var result: [Node] = []
            var child = cmark_node_first_child(node)
            while (child != nil) {
                result.append(Node(node: child))
                child = cmark_node_next(child)
            }
            return result
        }
        set {
            for child in newValue {
                cmark_node_append_child(node, child.node)
            }
        }
    }
    
    public var html: String? {
        return stringUnlessNil(cmark_render_html(node, 0))
    }
    
    public var xml: String? {
        return stringUnlessNil(cmark_render_xml(node, 0))
    }
    
    public var commonMark: String? {
        return stringUnlessNil(cmark_render_commonmark(node, CMARK_OPT_DEFAULT, 80))
    }
    
    public var description: String {
        return "\(typeString) {\n \(literal ?? String())\(children.description ?? String()) \n}"
    }
}