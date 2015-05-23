//
//  LiterateSwift.swift
//  LiterateSwiftFramework
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import Foundation

import CommonMark

public func codeWithLanguage(node: Node, language: String) -> [Node] {
    return node.children.filter { child in
        child.fenceInfo == language
    }
}