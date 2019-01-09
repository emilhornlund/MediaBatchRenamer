//
//  main.swift
//  MediaBatchRenamer
//
//  Created by Emil Hörnlund on 2019-01-09.
//  Copyright © 2019 Emil Hörnlund. All rights reserved.
//

import Foundation
import AVFoundation

let ProjectVersion = "1.0.0"

let consoleIO = ConsoleIO()

func listMedia() throws -> [AVAsset] {
    let pathURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let fileURLs = try FileManager.default.contentsOfDirectory(at: pathURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    let assets = fileURLs.compactMap({ fileURL -> AVAsset? in
        let asset = AVAsset(url: fileURL)
        return !asset.tracks(withMediaType: AVMediaType.video).isEmpty ? asset : nil
    })
    return assets
}

func parseTVShow(from asset: AVAsset) -> MediaType? {
    func getValueByIdentifier(_ id: String) -> String? {
        return asset.metadata.filter({($0.identifier?.rawValue.isEqual(id))!}).first?.stringValue
    }
    guard let show = getValueByIdentifier("itsk/tvsh") else { return nil }
    guard let seasonStr = getValueByIdentifier("itsk/tvsn"), let season = Int(seasonStr) else { return nil }
    guard let episodeStr = getValueByIdentifier("itsk/tves"), let episode = Int(episodeStr) else { return nil }
    guard let title = getValueByIdentifier("itsk/%A9nam") else { return nil }
    return .show(show, season, episode, title)
}

func run() {
    if CommandLine.arguments.contains("-v") || CommandLine.arguments.contains("--version") {
        let date = Date()
        let calendar = Calendar.current
        consoleIO.writeMessage("MediaBatchRenamer, version \(ProjectVersion)")
        consoleIO.writeMessage("Copyright (C) \(calendar.component(.year, from: date)) Emil Hörnlund\n")
    } else if CommandLine.arguments.contains("-h") || CommandLine.arguments.contains("--help") {
        consoleIO.printUsage()
    } else {
        do {
            let list = try listMedia()
            let tvshows = list.compactMap({ asset -> MediaItem? in
                guard let tvshow = parseTVShow(from: asset), let assetURL = (asset as? AVURLAsset)?.url else { return nil }
                return MediaItem(type: tvshow, inputURL: assetURL)
            }).filter({ $0.inputName != $0.outputName })
            if !tvshows.isEmpty {
                for item in tvshows {
                    consoleIO.writeMessage("\(item.inputName) -> \(item.outputName)")
                }
                consoleIO.writeMessage("\nFound \(tvshows.count) tvshow(s)")
                consoleIO.writeMessage("Are you sure you want to rename the files? (Y/n)")
                if case let input = consoleIO.getInput().uppercased(), input == "Y" {
                    for tvshow in tvshows {
                        try FileManager.default.moveItem(at: tvshow.inputURL, to: tvshow.outputURL)
                    }
                }
            } else {
                consoleIO.writeMessage("No media was found\n")
            }
        } catch {
            consoleIO.writeMessage(error.localizedDescription)
        }
    }
}
run()
