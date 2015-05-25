//
//  LiterateSwift.swift
//  LiterateSwiftFramework
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import Foundation

import CommonMark

public func codeBlock(element: Block, includeLanguage: String? -> Bool) -> [String] {
    switch element {
    case .CodeBlock(let code, let lang) where includeLanguage(lang):
        return [code]
    default:
        return []
        
    }
}

public func extractSwift(child: Block) -> [String] {
    return codeBlock(child, { $0 == "swift"  })
}