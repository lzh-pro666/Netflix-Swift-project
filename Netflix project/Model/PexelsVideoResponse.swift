//
//  PexelsSearchResponse.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/15.
//

import Foundation

// 顶层响应
struct PexelsVideoResponse: Codable {
    let videos: [PexelsVideo]
}

// 视频对象
struct PexelsVideo: Codable {
    let id: Int
    let url: String
    let videoFiles: [PexelsVideoFile]

    enum CodingKeys: String, CodingKey {
        case id, url
        case videoFiles = "video_files"
    }
}

// 视频文件
struct PexelsVideoFile: Codable {
    let link: String
}
