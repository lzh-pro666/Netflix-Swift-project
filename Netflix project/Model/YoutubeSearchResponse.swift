//
//  YoutubuSearchResponse.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/13.
//

import Foundation

/*
 id =             {
     kind = "youtube#video";
     videoId = DRv2aT9gXGA;
 };
 */

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
