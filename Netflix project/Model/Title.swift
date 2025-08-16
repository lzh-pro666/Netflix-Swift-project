//
//  Movie.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/11.
//

import Foundation

// Codable协议将 Swift 类型与外部数据格式（如 JSON 或 Property List）进行相互转换。
struct TrendingTitleResponse: Codable {
    let results: [Title]
}

struct Title: Codable {
    let id: Int
    let media_type: String?
    let original_name: String?
    let original_title: String?
    let poster_path: String?
    let overview: String?
    let vote_count: Int
    let release_date: String?
    let vote_average: Double
}
