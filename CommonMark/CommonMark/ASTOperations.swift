//
//  ASTOperations.swift
//  CommonMark
//
//  Created by Chris Eidhof on 23/05/15.
//  Copyright (c) 2015 Unsigned Integer. All rights reserved.
//

import Foundation

public func deepApply(elements: [Block], f: Block -> [Block]) -> [Block] {
    return elements.flatMap(deepApply(f))
}

public func deepApply(f: Block -> [Block])(element: Block) -> [Block] {
   let recurse: Block -> [Block] = deepApply(f)
   switch element {
   case let .List(items, type):
    let mapped = Block.List(items: flatMap(items, recurse), type: type)
     return f(mapped)
   case .ListItem(let items):
     return f(Block.ListItem(items: flatMap(items, recurse)))
   case .BlockQuote(let items):
     return f(Block.BlockQuote(items: items.flatMap(recurse)))
   default:
     return f(element)
   }
}

public func deepCollect<A>(f: Block -> [A])(elements: [Block]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

public func deepCollect<A>(f: Block -> [A])(element: Block) -> [A] {
   let recurse: Block -> [A] = deepCollect(f)
   switch element {
   case .List(let items, _):
     return flatMap(items, recurse) + f(element)
   case .ListItem(let items):
     return flatMap(items, recurse) + f(element)
   case .BlockQuote(let items):
     return flatMap(items, recurse) + f(element)
   default:
     return f(element)
   }
}

public func deepFilter(f: Block -> Bool)(elements: [Block]) -> [Block] {
    return elements.flatMap(deepFilter(f))
}

public func deepFilter(f: Block -> Bool)(element: Block) -> [Block] {
    let recurse: Block -> [Block] = deepFilter(f)
    let selff = f(element) ? [element] : []
    switch element {
    case let .List(items, type):
        return flatMap(items, recurse) + selff
    case .ListItem(let items):
        return flatMap(items, recurse) + selff
    case .BlockQuote(let items):
        return flatMap(items, recurse) + selff
    default:
        return selff
    }
}

//func deepMap(x: Block, f: Inline -> [Inline]) -> Block {
//    return x
//}
