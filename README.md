LiterateSwift is a (GUI) tool to edit your literate swift files.

A literate swift file is written in CommonMark, written with fenced code blocks. A code block can be either of three things: swift, highlight-swift, or print-swift.

A file is transformed like this: first, all `swift` code-blocks are assembled into one big swift file. Then, for every print-swift block, a new file is generated, containing the `swift` code blocks and the contents of that print-swift block.

To install, just run `pod install`, it will install the dependencies (cmark, CommonMark and LiterateSwift).

### Weaving

Additionally, you can include snippets from other swift files in subdirectories (or the same directory).

If you surround your code like this:

    // <<MyView>>
    class View {
        var window: Window
        init(window: Window) {
            self.window = window
        }
    }
    class Window {
        var view: View?
    }
    // <</MyView>>

And put it in a file with the extension .swift, somewhere in the same directory as the markdown file (or a subdirectory), you can then include it in your Markdown file, inside a code block:

    ```
    <<MyView>>
    ```
