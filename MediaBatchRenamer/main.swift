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

enum ProcessResult {
    case success, canceled, noresult
}

func listMedia() throws -> [AVAsset] {
    let pathURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let fileURLs = try FileManager.default.contentsOfDirectory(at: pathURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    let assets = fileURLs.compactMap({ fileURL -> AVAsset? in
        let asset = AVAsset(url: fileURL)
        return !asset.tracks(withMediaType: AVMediaType.video).isEmpty ? asset : nil
    })
    return assets
}

func getAssetMetadataValueByIdentifier(_ asset: AVAsset, _ id: String) -> String? {
    return asset.metadata.filter({($0.identifier?.rawValue.isEqual(id))!}).first?.stringValue
}

func parseTVShow(from asset: AVAsset) -> MediaType? {
    guard let show = getAssetMetadataValueByIdentifier(asset, "itsk/tvsh") else { return nil }
    guard let seasonStr = getAssetMetadataValueByIdentifier(asset, "itsk/tvsn"), let season = Int(seasonStr) else { return nil }
    guard let episodeStr = getAssetMetadataValueByIdentifier(asset, "itsk/tves"), let episode = Int(episodeStr) else { return nil }
    guard let title = getAssetMetadataValueByIdentifier(asset, "itsk/%A9nam") else { return nil }
    return .show(show, season, episode, title)
}

func parseMovie(from asset: AVAsset) -> MediaType? {
    guard let name = getAssetMetadataValueByIdentifier(asset, "itsk/%A9nam") else { return nil }
    return .movie(name)
}

func processTVShowEpisodes() throws -> ProcessResult {
    let list = try listMedia()
    
    let tvshows = list.compactMap({ asset -> MediaItem? in
        guard let tvshow = parseTVShow(from: asset), let assetURL = (asset as? AVURLAsset)?.url else { return nil }
        return MediaItem(type: tvshow, inputURL: assetURL)
    }).filter({ $0.inputName != $0.outputName })
    
    if !tvshows.isEmpty {
        for item in tvshows {
            consoleIO.writeMessage("\(item.inputName) -> \(item.outputName)")
        }
        consoleIO.writeMessage("\nFound \(tvshows.count) episode(s)")
        consoleIO.writeMessage("Are you sure you want to rename the files? (Y/n)")
        if case let input = consoleIO.getInput().uppercased(), input == "Y" {
            for tvshow in tvshows {
                try FileManager.default.moveItem(at: tvshow.inputURL, to: tvshow.outputURL)
            }
            return .success
        } else { return .canceled }
    } else {
        return .noresult
    }
}

func processMovies() throws -> ProcessResult {
    let list = try listMedia()
    
    let movies = list.compactMap({ asset -> MediaItem? in
        guard let movie = parseMovie(from: asset), let assetURL = (asset as? AVURLAsset)?.url else { return nil }
        return MediaItem(type: movie, inputURL: assetURL)
    }).filter({ $0.inputName != $0.outputName })
    
    if !movies.isEmpty {
        for item in movies {
            consoleIO.writeMessage("\(item.inputName) -> \(item.outputName)")
        }
        consoleIO.writeMessage("\nFound \(movies.count) movies(s)")
        consoleIO.writeMessage("Are you sure you want to rename the files? (Y/n)")
        if case let input = consoleIO.getInput().uppercased(), input == "Y" {
            for movie in movies {
                try FileManager.default.moveItem(at: movie.inputURL, to: movie.outputURL)
            }
            return .success
        } else { return .canceled }
    } else {
        return .noresult
    }
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
            let episodesResult = try processTVShowEpisodes()
            let moviesResult = try processMovies()
            if episodesResult == .noresult && moviesResult == .noresult {
                consoleIO.writeMessage("No media was found\n")
            }
        } catch {
            consoleIO.writeMessage(error.localizedDescription)
        }
    }
}
run()
