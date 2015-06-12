//
//  SwiftAST.swift
//  CommonMark
//
//  Created by Chris Eidhof on 22/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation

public enum ListType {
    case Unordered
    case Ordered
}

public enum InlineElement {
    case Text(text: String)
    case SoftBreak
    case LineBreak
    case Code(text: String)
    case InlineHtml(text: String)
    case Emphasis(children: [InlineElement])
    case Strong(children: [InlineElement])
    case Link(children: [InlineElement], title: String?, url: String?)
    case Image(children: [InlineElement], title: String?, url: String?)
    
}

extension InlineElement : StringLiteralConvertible {
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(stringLiteral: value)
    }
    
    public init(stringLiteral: StringLiteralType) {
        self = InlineElement.Text(text: stringLiteral)
    }
}

public enum Block {
    case List(items: [[Block]], type: ListType)
    case BlockQuote(items: [Block])
    case CodeBlock(text: String, language: String?)
    case Html(text: String)
    case Paragraph(text: [InlineElement])
    case Header(text: [InlineElement], level: Int)
    case HorizontalRule
}

func parseInlineElement(node: Node) -> InlineElement {
    let parseChildren = { node.children.map(parseInlineElement) }
    switch node.type {
    case CMARK_NODE_TEXT: return .Text(text: node.literal!)
    case CMARK_NODE_SOFTBREAK: return .SoftBreak
    case CMARK_NODE_LINEBREAK: return .LineBreak
    case CMARK_NODE_CODE: return .Code(text: node.literal!)
    case CMARK_NODE_INLINE_HTML: return .InlineHtml(text: node.literal!)
    case CMARK_NODE_EMPH: return .Emphasis(children: parseChildren())
    case CMARK_NODE_STRONG: return .Strong(children: parseChildren())
    case CMARK_NODE_LINK: return .Link(children: parseChildren(), title: node.title, url: node.urlString)
    case CMARK_NODE_IMAGE: return .Image(children: parseChildren(), title: node.title, url: node.urlString)
    default:
        fatalError("Expected inline element, got \(node.typeString)")
    }
}

public func parseListItem(node: Node) -> [Block] {
    switch node.type {
    case CMARK_NODE_ITEM:
        return node.children.map(parseBlock)
    default:
        fatalError("Unrecognized node \(node.typeString), expected a list item")
    }
}

public func parseBlock(node: Node) -> Block {
    let parseInlineChildren = { node.children.map(parseInlineElement) }
    let parseBlockChildren = { node.children.map(parseBlock) }
    switch node.type {
    case CMARK_NODE_PARAGRAPH:
        return .Paragraph(text: parseInlineChildren())
    case CMARK_NODE_BLOCK_QUOTE:
        return .BlockQuote(items: parseBlockChildren())
    case CMARK_NODE_LIST:
        let type = node.listType == CMARK_BULLET_LIST ? ListType.Unordered : ListType.Ordered
        return .List(items: node.children.map(parseListItem), type: type)
    case CMARK_NODE_CODE_BLOCK:
        return .CodeBlock(text: node.literal!, language: node.fenceInfo)
    case CMARK_NODE_HTML:
        return .Html(text: node.literal!)
    case CMARK_NODE_HEADER:
        return .Header(text: parseInlineChildren(), level: node.headerLevel)
    case CMARK_NODE_HRULE:
        return .HorizontalRule
    default:
        fatalError("Unrecognized node: \(node.typeString)")
    }
}

extension Node {
    convenience init(type: cmark_node_type, literal: String) {
        self.init(type: type)
        self.literal = literal
    }
    convenience init(type: cmark_node_type, blocks: [Block]) {
        self.init(type: type, children: blocks.map(toNode))
    }
    convenience init(type: cmark_node_type, elements: [InlineElement]) {
        self.init(type: type, children: elements.map(toNode))
    }

    public convenience init(blocks: [Block]) {
        self.init(type: CMARK_NODE_DOCUMENT, blocks: blocks)
    }
}

extension Node {
    public var elements: [Block] {
        return children.map(parseBlock)
    }
}


func toNode(element: InlineElement) -> Node {
    let node: Node
    switch element {
    case .Text(let text):
        node = Node(type: CMARK_NODE_TEXT, literal: text)
    case .Emphasis(let children):
        node = Node(type: CMARK_NODE_EMPH, elements: children)
    case .Code(let text):
         node = Node(type: CMARK_NODE_CODE, literal: text)
    case .Strong(let children):
        node = Node(type: CMARK_NODE_STRONG, elements: children)
    case .InlineHtml(let text):
        node = Node(type: CMARK_NODE_INLINE_HTML, literal: text)
    case let .Link(children, title, url):
        node = Node(type: CMARK_NODE_LINK, elements: children)
        node.title = title
        node.urlString = url
    case let .Image(children, title, url):
        node = Node(type: CMARK_NODE_IMAGE, elements: children)
        node.title = title
        node.urlString = url
    case .SoftBreak: node = Node(type: CMARK_NODE_SOFTBREAK)
    case .LineBreak: node = Node(type: CMARK_NODE_LINEBREAK)
    }
    return node
}

func toNode(block: Block) -> Node {
   let node: Node
   switch block {
   case .Paragraph(let children):
     node = Node(type: CMARK_NODE_PARAGRAPH, elements: children)
   case let .List(items, type):
     let listItems = items.map { Node(type: CMARK_NODE_ITEM, blocks: $0) }
     node = Node(type: CMARK_NODE_LIST, children: listItems)
     node.listType = type == .Unordered ? CMARK_BULLET_LIST : CMARK_ORDERED_LIST
   case .BlockQuote(let items):
     node = Node(type: CMARK_NODE_BLOCK_QUOTE, blocks: items)
   case let .CodeBlock(text, language):
     node = Node(type: CMARK_NODE_CODE_BLOCK, literal: text)
     node.fenceInfo = language
   case .Html(let text):
     node = Node(type: CMARK_NODE_HTML, literal: text)
   case let .Header(text, _):
     node = Node(type: CMARK_NODE_HEADER, elements: text)
   case .HorizontalRule:
     node = Node(type: CMARK_NODE_HRULE)
   }
   return node
}