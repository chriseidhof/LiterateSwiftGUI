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

public func parseFile(filename: String) -> Node? {
    let parsed = cmark_parse_file(fopen(filename, "r"), 0)
    if parsed == nil {
        return nil
    } else {
        return Node(node: parsed)
    }
}

public struct Node: Printable {
    let node: COpaquePointer
    
    init(node: COpaquePointer) {
        self.node = node
    }
    
    public var type: cmark_node_type {
        return cmark_node_get_type(node)
    }
    
    public var listType: cmark_list_type {
        return cmark_node_get_list_type(node)
    }
    
    public var listStart: Int {
        return Int(cmark_node_get_list_start(node))
    }
    
    public var typeString: String {
        return String(UTF8String: cmark_node_get_type_string(node))!
    }
    
    public var literal: String? {
        return stringUnlessNil(cmark_node_get_literal(node))
    }
    
    public var headerLevel: Int {
        return Int(cmark_node_get_header_level(node))
    }
    
    public var fenceInfo: String? {
        return stringUnlessNil(cmark_node_get_fence_info(node))
    }
    
    public var urlString: String? {
        return stringUnlessNil(cmark_node_get_url(node))
    }
    
    public var title: String? {
        return stringUnlessNil(cmark_node_get_title(node))
    }
    
    public var children: [Node] {
        var result: [Node] = []
        var child = cmark_node_first_child(node)
        while (child != nil) {
            result.append(Node(node: child))
            child = cmark_node_next(child)
        }
        return result
    }
    
    public var html: String? {
        return stringUnlessNil(cmark_render_html(node, 0))
    }
    
    public var xml: String? {
        return stringUnlessNil(cmark_render_xml(node, 0))
    }
    
    public var description: String {
        return "\(typeString) {\n \(literal ?? String())\(children.description ?? String()) \n}"
    }
}
