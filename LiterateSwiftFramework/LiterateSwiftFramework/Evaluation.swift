//
//  Evaluation.swift
//  LiterateSwiftFramework
//
//  Created by Chris Eidhof on 25/05/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import Foundation

private func exec(#commandPath: String, #workingDirectory: String, #arguments: [String]) -> (output: String, stderr: String) {
    let task = NSTask()
    task.currentDirectoryPath = workingDirectory
    task.launchPath = commandPath
    task.arguments = arguments
    task.environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"]

    let stdout = NSPipe()
    task.standardOutput = stdout
    let stderr = NSPipe()
    task.standardError = stderr

    task.launch()

    func read(pipe: NSPipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return NSString(data: data, encoding: NSUTF8StringEncoding)! as String
    }
    let stdoutoutput : String = read(stdout)
    let stderroutput : String = read(stderr)

    task.waitUntilExit()

    return (output: stdoutoutput, stderr: stderroutput)
}

private func ignoreOutputAndPrintStdErr(input: (output: String,stderr: String)) -> () {
    printstderr(input.stderr)
}

private func printstderr(s: String) {
    NSFileHandle.fileHandleWithStandardError().writeData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
}

func evaluateSwift(code: String, #expression: String) -> String {
    let hasPrintlnStatements = !(expression.rangeOfString("println", options: NSStringCompareOptions.allZeros, range: nil, locale: nil) == nil)
    var expressionLines: [String] = expression.lines.filter { count($0) > 0 }
    let contents: String
    if !hasPrintlnStatements {
        let lastLine = expressionLines.removeLast()
        let shouldIncludeLet = expressionLines.filter { $0.hasPrefix("let result___ ") }.count == 0
        let resultIs = shouldIncludeLet ? "let result___ : Any = " : ""
        contents = "\n".join([code, "", "\n".join(expressionLines), "", "\(resultIs) \(lastLine)", "println(\"\\(result___)\")"])
    } else {
        contents = "\n".join([code, "", "\n".join(expressionLines)])
    }

    let base = NSUUID().UUIDString
    let basename = base.stringByAppendingPathExtension("swift")
    let filename = "/tmp".stringByAppendingPathComponent(basename!)

    contents.writeToFile(filename)
    var arguments: [String] =  "--sdk macosx swiftc".words
    let objectName = base.stringByAppendingPathExtension("o")!
    ignoreOutputAndPrintStdErr(exec(commandPath:"/usr/bin/xcrun", workingDirectory:"/tmp", arguments:arguments + ["-c", filename]))
    ignoreOutputAndPrintStdErr(exec(commandPath: "/usr/bin/xcrun", workingDirectory: "/tmp", arguments: arguments + ["-o", "app", objectName]))
    let workingDirectory = NSFileManager.defaultManager().currentDirectoryPath
    let (stdout, stderr) = exec(commandPath: "/tmp/app", workingDirectory: workingDirectory, arguments: [workingDirectory])
    printstderr(stderr)
    return stdout
}