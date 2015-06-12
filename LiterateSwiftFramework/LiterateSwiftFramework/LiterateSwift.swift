//
//  LiterateSwift.swift
//  LiterateSwiftFramework
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import Foundation

import CommonMark

func isCodeBlock(matchingLanguage: String? -> Bool)(element: Block) -> Bool {
    switch element {
    case .CodeBlock(_, let lang) where matchingLanguage(lang):
        return true
    default:
        return false

    }

}

public func codeBlock(element: Block, _ includeLanguage: String? -> Bool) -> String? {
    switch element {
    case .CodeBlock(let code, let lang) where includeLanguage(lang):
        return code
    default:
        return nil
        
    }
}

public func toArray<A>(optional: A?) -> [A] {
    if let x = optional {
        return [x]
    } else {
        return []
    }
}

public func extractSwift(child: Block) -> [String] {
    return toArray(codeBlock(child, { $0 == "swift"  }))
}

public func printableSwiftBlocks(child: Block) -> [String] {
    return toArray(codeBlock(child, { $0 == "print-swift" } ))
}

public func evaluateAndReplacePrintSwift(document: [Block]) -> [Block] {
    let isPrintSwift = { codeBlock($0, { $0 == "print-swift" }) }
    let swiftCode = "\n".join(deepCollect(document, extractSwift))
    let eval: Block -> [Block] = {
        if let code = isPrintSwift($0) {
            return [
                Block.CodeBlock(text: code, language: "swift"),
                Block.CodeBlock(text: evaluateSwift(swiftCode, expression: code), language: "")
            ]
        } else {
            return [$0]
        }
    }
    return deepApply(document, eval)
}

extension String {
    var lines: [String] {
        return self.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }

    var words: [String] {
        return self.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }

    func writeToFile(destination: String) {
        do {
            try writeToFile(destination, atomically: true, encoding: NSUTF8StringEncoding)
        } catch _ {
        }
    }
}
