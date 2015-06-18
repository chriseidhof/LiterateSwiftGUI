//
//  Weave.swift
//  LiterateSwift2
//
//  Created by Chris Eidhof on 16/06/15.
//  Copyright © 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import CommonMark

private let nameRegex = try! NSRegularExpression(pattern: "^<<(\\w+)>>$", options: NSRegularExpressionOptions())

func matchName(string: String) -> String? {
    let matches = nameRegex.matchesInString(string, options: NSMatchingOptions(), range: NSMakeRange(0, string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
    guard matches.count == 1 else { return nil }
    return (string as NSString).substringWithRange(matches[0].rangeAtIndex(1))
}

public func replaceSnippet(directory: String)(child: Block) -> [Block] {
    if case let .CodeBlock(code, language) = child where language == "highlight-swift",
        let name = matchName(code) {
            let code = findSnippet(directory)(name: name) ?? "<<ERROR couldn't find \(name)>>"
            return [Block.CodeBlock(text: code, language: language)]
    } else {
        return [child]
    }
}

func findNestedFiles(directory: String, test: String -> Bool) -> [String] {
    do {
        let fm = NSFileManager.defaultManager()
        return try fm.subpathsOfDirectoryAtPath(directory).filter(test)
    } catch {
        return []
    }
}

func extractSnippet(filename: String, snippetName: String) -> String? {
    let contents: String = try! NSString(contentsOfFile: filename, encoding: NSUTF8StringEncoding) as String
    var result: [String]?
    for line in contents.lines {
        if line.hasPrefix("// <</\(snippetName)>>") {
            return "\n".join(result!)
        } else if result != nil {
            result?.append(line)
        } else if line.hasPrefix("// <<\(snippetName)") {
            result = []
        }
    }
    return nil
}

func findSnippet(directory: String)(name: String) -> String? {
    let files = findNestedFiles(directory) { $0.pathExtension == "swift" }
    for swiftFile in files  {
        if let snippet = extractSnippet(directory.stringByAppendingPathComponent(swiftFile), snippetName: name) {
            return snippet
        }
    }
    return nil
}