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


public func deepApply(elements: [Block], f: Block -> [Block]) -> [Block] {
    return elements.flatMap(deepApply(f))
}

public func deepApply(f: Block -> [Block])(element: Block) -> [Block] {
   let recurse: Block -> [Block] = deepApply(f)
   switch element {
   case let .List(items, type):
     let mapped = Block.List(items: map(items) { flatMap($0, recurse) }, type: type)
     return f(mapped)
   case .BlockQuote(let items):
     return f(Block.BlockQuote(items: items.flatMap(recurse)))
   default:
     return f(element)
   }
}

public func deepCollect<A>(elements: [Block], f: Block -> [A]) -> [A] {
    return elements.flatMap(deepCollect(f))
}

public func deepCollect<A>(f: Block -> [A])(element: Block) -> [A] {
   let recurse: Block -> [A] = deepCollect(f)
   switch element {
   case .List(let items, _):
    return flatMap(flatten(items), recurse) + f(element)
   case .BlockQuote(let items):
     return flatMap(items, recurse) + f(element)
   default:
     return f(element)
   }
}

public func deepFilter(f: Block -> Bool)(elements: [Block]) -> [Block] {
    return elements.flatMap(deepFilter(f))
}

public func deepFilter(f: Block -> Bool) -> Block -> [Block] {
    return deepCollect { element in
        return f(element) ? [element] : []
    }
}