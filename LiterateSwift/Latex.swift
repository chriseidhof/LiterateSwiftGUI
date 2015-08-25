//
//  Latex.swift
//  LiterateSwift
//
//  Created by Chris Eidhof on 17/07/15.
//  Copyright © 2015 Unsigned Integer. All rights reserved.
//

import Foundation
import CommonMark

protocol ToLatex {
    var latex: Latex { get }
}

enum Escape {
    case Literal
    case Normal
    case URL
}

struct Latex {
    let raw: String
    init(raw l: String) { self.raw = l }
    init(escape str: String) {
        raw = escape(str, mode: .Normal)
    }
    init(literal str: String) {
        raw = str
    }
    init(urlEscape str: String) {
        raw = escape(str, mode: .URL)
    }
}

extension Latex: ToLatex {
    var latex: Latex { return self }
}

func +(x: Latex, y: Latex) -> Latex {
    return Latex(raw: x.raw + y.raw)
}

extension Array where Element: ToLatex {
    var joined: Latex {
        return Latex(raw: self.map { $0.latex.raw }.joinWithSeparator(""))
    }
}

extension String {
    func cmd() -> Latex {
        return Latex(raw:"\\\(self)")
    }
    func cmd(contents: String) -> Latex {
        return cmd(Latex(escape: contents))
    }
    func cmd(contents: Latex) -> Latex {
        return Latex(raw: "\\\(self){\(contents.raw)}")
    }

    func cmd<A: ToLatex>(param: Latex, children: [A]) -> Latex {
        return Latex(raw: "\\\(self){\(param.raw)}{\(children.joined.raw)}")
    }

    func cmd<A: ToLatex>(contents: [A]) -> Latex {
        return Latex(raw: "\\\(self){\(contents.joined.raw)}")
    }

    func env(contents: Latex) -> Latex {
        return Latex(raw: "\\begin{\(self)}\n\(contents.raw)\n\\end{\(self)}\n\n")
    }

    func env<A: ToLatex>(contents: [A]) -> Latex {
        return env(contents.joined)
    }
}

extension String {
    func contains(c: Character) -> Bool {
        return characters.contains(c)
    }
}

private let mapping: [Character:String] = [
    "|": "\\textbar{}",
    "<": "\\textless{}",
    ">": "\\textgreater{}",
    "[": "{[}",
    "]": "{]}",
//    "\"": "\\textquotedbl{}",
    "'": "\\textquotesingle{}",
    "\u{a0}": "~", // nbsp
    "\u{2026}": "\\ldots{}", // hellip
    "ọ": "\\d{o}",
    "ọ̀": "\\d{ó}",
//    "🇬🇧": "$\\vcenter{\\hbox{\\includegraphics{uk-f}}}$",
]

private let mappingInNormal: [Character: String] = [ // Only in normal mode
    "\u{2018}": "`", //lsquo
    "\u{2019}": "'", //rsquo
    "\u{201c}": "``", //ldquo
    "\u{201d}": "''", //rdquo
    "\u{2014}": "---", //emdash
    "\u{2013}": "--", //endash
]

func escape(string: String, mode: Escape) -> String {
    var result: String = ""
    var previous: Character = "x" // Doesn't matter, as long as it's not -
    let f = escapeLatex(mode)
    for char in string.characters {
        result += f(char: char, next: previous)
        previous = char
    }
    return result
}

func escapeLatex(escape: Escape)(char: Character, next: Character) -> String {
    let str = String([char])
    if "{}#%&".contains(char) {
        return "\\" + str
    } else if "$_".contains(char) && escape == .Normal {
        return "\\" + str
    } else if char == "-" && next == "-" {
        return "\\-"
    } else if char == "~" && escape == .Normal {
        return "\\textasciitilde{}"
    } else if char == "^" {
        return "\\^{}"
    } else if char == "\\" && escape != .URL {
        return "\\textbackslash{}"
    } else if let result = mapping[char] {
        return result
    } else if let result = mapping[char] where escape == .Normal {
        return result
    }
    return str
}


extension InlineElement: ToLatex {
    var latex: Latex {
        switch self {
        case let .Code(code): return "texttt".cmd(code)
        case let .Emphasis(children): return "emph".cmd(children)
        case let .Strong(children): return "textbf".cmd(children)
        case .Text(let t): return Latex(escape: t)
        case .SoftBreak: return Latex(raw: " ")
        case .LineBreak: return Latex(raw: "\\\\")
        case let .Link(children, _, url): return "href".cmd(Latex(urlEscape: url ?? ""), children: children)
        case let .Image(_, _, url): return "protect".cmd() + "includegraphics".cmd(Latex(urlEscape: url!))
        case .InlineHtml(_): return Latex(raw: "") // Don't know how to process this
        }
    }
}

func header(level: Int) -> String? {
    let levels = ["chapter",
     "section",
     "subsection",
     "subsubsection",
     "paragraph",
     "subparagraph"
    ]
    guard level-1 < levels.count else { return nil }
    return levels[level-1]

}

extension Block: ToLatex {
    var latex: Latex {
        switch self {
        case .BlockQuote(let items):
            return "quote".env(items)
        case let .CodeBlock(text, language) where language == "swift":
            return "swiftlisting".env(Latex(literal: text))
        case let .CodeBlock(text, _):
            return "verbatim".env(Latex(literal: text))
        case let .Header(children, level):
            return header(level)!.cmd(children) + Latex(raw: "\n")
        case .HorizontalRule:
            return Latex(raw: "\n\n\\begin{center}\\rule{0.5\\linewidth}{\\linethickness}\\end{center}\n\n")
        case .Html(_):
            return Latex(raw: "") // ?
        case let .List(items, type):
            let command = type == ListType.Unordered ? "itemize" : "enumerate"
            return command.env(items.map {
                return "item ".cmd() + $0.joined
                })
        case .Paragraph(let text):
            return text.joined + Latex(raw: "\n\n")
        }
    }
}

public func latexString(x: [Block]) -> String {
    return x.joined.raw
}