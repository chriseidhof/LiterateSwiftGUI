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
    case List(items: [Block], type: ListType)
    case ListItem(items: [Block])
    case BlockQuote(items: [Block])
    case CodeBlock(text: String, language: String?)
    case Html(text: String)
    case Paragraph(text: [InlineElement])
    case Header(text: [InlineElement], level: Int)
    case HorizontalRule
}

func parseInlineElement(node: Node) -> InlineElement? {
    let parseChildren = { node.children.map { parseInlineElement($0)! } }
    switch node.type.value {
    case CMARK_NODE_TEXT.value: return InlineElement.Text(text: node.literal!)
    case CMARK_NODE_SOFTBREAK.value: return InlineElement.SoftBreak
    case CMARK_NODE_LINEBREAK.value: return InlineElement.LineBreak
    case CMARK_NODE_CODE.value: return InlineElement.Code(text: node.literal!)
    case CMARK_NODE_INLINE_HTML.value: return InlineElement.InlineHtml(text: node.literal!)
    case CMARK_NODE_EMPH.value: return InlineElement.Emphasis(children: parseChildren())
    case CMARK_NODE_STRONG.value: return InlineElement.Strong(children: parseChildren())
    case CMARK_NODE_LINK.value: return InlineElement.Link(children: parseChildren(), title: node.title, url: node.urlString)
    case CMARK_NODE_IMAGE.value: return InlineElement.Image(children: parseChildren(), title: node.title, url: node.urlString)
    default: return nil
    }
}

public func parseNode(node: Node) -> Block? {
    let parseInlineChildren = { node.children.map { parseInlineElement($0)! } }
    let parseBlockChildren =  { node.children.map { parseNode($0)! } }
    switch node.type.value {
    case CMARK_NODE_PARAGRAPH.value:
        return .Paragraph(text: parseInlineChildren())
    case CMARK_NODE_BLOCK_QUOTE.value:
        return Block.BlockQuote(items: parseBlockChildren())
    case CMARK_NODE_LIST.value:
        let type = node.listType.value == CMARK_BULLET_LIST.value ? ListType.Unordered : ListType.Ordered
        return Block.List(items: parseBlockChildren(), type: type) // todo
    case CMARK_NODE_ITEM.value:
        return Block.ListItem(items: parseBlockChildren())
    case CMARK_NODE_CODE_BLOCK.value:
        return Block.CodeBlock(text: node.literal!, language: node.fenceInfo)
    case CMARK_NODE_HTML.value:
        return Block.Html(text: node.literal!)
    case CMARK_NODE_HEADER.value:
        return Block.Header(text: parseInlineChildren(), level: node.headerLevel)
    case CMARK_NODE_HRULE.value:
        return Block.HorizontalRule
    default:
        println("Unrecognized node: \(node.typeString)")
        return nil
    }
}

func toNode(element: InlineElement) -> Node {
    let node: Node
    switch element {
    case .Text(let text):
        node = Node(type: CMARK_NODE_TEXT)
        node.literal = text
    case .Emphasis(let children):
        node = Node(type: CMARK_NODE_EMPH)
        node.children = children.map(toNode)
    case .SoftBreak: node = Node(type: CMARK_NODE_EMPH)
    case .LineBreak: node = Node(type: CMARK_NODE_EMPH)
    case .Code(let text): 
         node = Node(type: CMARK_NODE_CODE)
         node.literal = text
    case .Strong(let children):
        node = Node(type: CMARK_NODE_STRONG)
        node.children = children.map(toNode)
    case let .Link(children, title, url):
        node = Node(type: CMARK_NODE_LINK)
        node.children = children.map(toNode)
        node.title = title
        node.urlString = url
    case let .Image(children, title, url):
        node = Node(type: CMARK_NODE_IMAGE)
        node.children = children.map(toNode)
        node.title = title
        node.urlString = url
    case .InlineHtml(let text):
         node = Node(type: CMARK_NODE_INLINE_HTML)
         node.literal = text
    }
    return node
}

func toNode(block: Block) -> Node {
   let node: Node
   switch block {
   case .Paragraph(let children):
     node = Node(type: CMARK_NODE_PARAGRAPH)
     node.children = children.map(toNode)
   case let .List(items, type):
     node = Node(type: CMARK_NODE_LIST)
     node.children = items.map(toNode)
     node.listType = CMARK_BULLET_LIST // TODO
   case .ListItem(let items):
     node = Node(type: CMARK_NODE_ITEM)
     node.children = items.map(toNode)
   case .BlockQuote(let items):
     node = Node(type: CMARK_NODE_BLOCK_QUOTE)
     node.children = items.map(toNode)
   case let .CodeBlock(text, language):
     node = Node(type: CMARK_NODE_CODE_BLOCK)
     node.fenceInfo = language
     node.literal = text
   case .Html(let text):
     node = Node(type: CMARK_NODE_HTML)
     node.literal = text
   case let .Header(text, level):
     node = Node(type: CMARK_NODE_HEADER)
     node.children = text.map(toNode)
   case .HorizontalRule:
     node = Node(type: CMARK_NODE_HRULE)
   }
   return node
    
    
    
}

public func document(blocks: [Block]) -> Node {
    let node = Node(type: CMARK_NODE_DOCUMENT)
    node.children = blocks.map(toNode)
    return node
}
