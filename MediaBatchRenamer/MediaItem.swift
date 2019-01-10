//
//  MediaItem.swift
//  MediaBatchRenamer
//
//  Created by Emil Hörnlund on 2019-01-09.
//  Copyright © 2019 Emil Hörnlund. All rights reserved.
//

import Foundation

enum MediaType {
    case show(String, Int, Int, String)
    case movie(String)
    
    func filename(extension ext: String) -> String {
        switch self {
        case .show(let show, let season, let episode, let title):
            return "\(show) - S\(String(format: "%02d", season))E\(String(format: "%02d", episode)) - \(title).\(ext)"
        case .movie(let title):
            return "\(title).\(ext)"
        }
    }
}

struct MediaItem {
    var type: MediaType
    var inputURL: URL
    
    var inputName: String {
        return inputURL.lastPathComponent
    }
    
    var outputName: String {
        let ext = inputURL.pathExtension
        return type.filename(extension: ext)
    }
    
    var outputURL: URL {
        return self.inputURL.deletingLastPathComponent().appendingPathComponent(outputName)
    }
}
