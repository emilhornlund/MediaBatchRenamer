//
//  ConsoleIO.swift
//  MediaBatchRenamer
//
//  Created by Emil Hörnlund on 2019-01-09.
//  Copyright © 2019 Emil Hörnlund. All rights reserved.
//

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .error:
            fputs("\(message)\n", stderr)
        }
    }
    
    func printUsage() {
        writeMessage("options:")
        writeMessage("      -h, --help")
        writeMessage("      -v, --version\n")
    }
    
    func getInput() -> String {
        let keyboard = FileHandle.standardInput
        let inputData = keyboard.availableData
        let strData = String(data: inputData, encoding: String.Encoding.utf8)!
        return strData.trimmingCharacters(in: CharacterSet.newlines)
    }
    
    @discardableResult
    func shell(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
}
