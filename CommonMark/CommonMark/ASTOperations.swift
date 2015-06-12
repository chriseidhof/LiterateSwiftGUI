//
//  ASTOperations.swift
//  CommonMark
//
//  Created by Chris Eidhof on 23/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation

func flatten<A>(x: [[A]]) -> [A] {
    return x.flatMap { $0 }
}


public func deepApply(elements: [Block], _ f: Block -> [Block]) -> [Block] {
    return elements.flatMap(deepApply(f))
}

public func deepApply(elements: [Block], _ f: InlineElement -> [InlineElement]) -> [Block] {
    return elements.flatMap(deepApply(f))
}


public func deepApply(f: Block -> [Block])(element: Block) -> [Block] {
   let recurse: Block -> [Block] = deepApply(f)
   switch element {
   case let .List(items, type):
     let mapped = Block.List(items: items.map { $0.flatMap(recurse) }, type: type)
     return f(mapped)
   case .BlockQuote(let items):
     return f(Block.BlockQuote(items: items.flatMap(recurse)))
   default:
     return f(element)
   }
}

public func deepApply(f: InlineElement -> [InlineElement])(element: Block) -> [Block] {
    let recurse: Block -> [Block] = deepApply(f)
    let applyInline: InlineElement -> [InlineElement] = deepApply(f)
    switch element {
    case .Paragraph(let children):
        return [Block.Paragraph(text: children.flatMap(applyInline))]
    case let .List(items, type):
        return [Block.List(items: items.map { $0.flatMap(recurse) }, type: type)]
    case .BlockQuote(let items):
        return [Block.BlockQuote(items: items.flatMap(recurse))]
    case let .Header(text, level):
        return [Block.Header(text: text.flatMap(applyInline), level: level)]
    default:
        return [element]
    }
}


public func deepApply(f: InlineElement -> [InlineElement])(element: InlineElement) -> [InlineElement] {
    let recurse: InlineElement -> [InlineElement] = deepApply(f)
    switch element {
    case .Emphasis(let children):
        return f(InlineElement.Emphasis(children: children.flatMap(recurse)))
    case .Strong(let children):
        return f(InlineElement.Strong(children: children.flatMap(recurse)))
    case let .Link(children, title, url):
        return f(InlineElement.Link(children: children.flatMap(recurse), title: title, url: url))
    case let .Image(children, title, url):
        return f(InlineElement.Image(children: children.flatMap(recurse), title: title, url: url))
    default:
        return f(element)
    }
}


public func deepCollect<A>(elements: [Block], _ f: Block -> [A]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

public func deepCollect<A>(elements: [Block], _ f: InlineElement -> [A]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

private func deepCollect<A>(f: Block -> [A])(element: Block) -> [A] {
   let recurse: Block -> [A] = deepCollect(f)
   switch element {
   case .List(let items, _):
    return flatten(items).flatMap(recurse) + f(element)
   case .BlockQuote(let items):
     return items.flatMap(recurse) + f(element)
   default:
     return f(element)
   }
}

private func deepCollect<A>(f: InlineElement -> [A])(element: Block) -> [A] {
    let collectInline: InlineElement -> [A] = deepCollect(f)
    let recurse: Block -> [A] = deepCollect(f)
    switch element {
    case .Paragraph(let children):
        return children.flatMap(collectInline)
    case let .List(items, _):
        return flatten(items).flatMap(recurse)
    case .BlockQuote(let items):
        return items.flatMap(recurse)
    case let .Header(text, _):
        return text.flatMap(collectInline)
    default:
        return []
    }
}

private func deepCollect<A>(f: InlineElement -> [A])(element: InlineElement) -> [A] {
    let recurse: InlineElement -> [A] = deepCollect(f)
    switch element {
    case .Emphasis(let children):
        return children.flatMap(recurse) + f(element)
    case .Strong(let children):
        return children.flatMap(recurse) + f(element)
    case let .Link(children, _, _):
        return children.flatMap(recurse) + f(element)
    case let .Image(children, _, _):
        return children.flatMap(recurse) + f(element)
    default:
        return f(element)
    }
}

public func deepFilter(f: Block -> Bool)(elements: [Block]) -> [Block] {
    return elements.flatMap(deepFilter(f))
}

private func deepFilter(f: Block -> Bool) -> Block -> [Block] {
    return deepCollect { element in
        return f(element) ? [element] : []
    }
}

public func deepFilter(f: InlineElement -> Bool)(elements: [Block]) -> [InlineElement] {
    return elements.flatMap(deepFilter(f))
}

private func deepFilter(f: InlineElement -> Bool) -> Block -> [InlineElement] {
    return deepCollect { element in
        return f(element) ? [element] : []
    }
}
