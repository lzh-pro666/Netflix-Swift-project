//
//  YoutubuSearchResponse.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/13.
//

import Foundation

struct YoutubeSearchResponse: Codable{
    let items: [VideoElement]
}
struct VideoElement: Codable {
    let id: IdVideoElement
}
struct IdVideoElement: Codable {
    let kind: String?
    let videoId: String?
}
