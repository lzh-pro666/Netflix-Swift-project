//
//  APICaller.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/11.
//

import Foundation

// 定义 api 所需要的各端链接
struct Constants {
    static let API_KEY = "1bb06d30401e70397eb7b11a0ed7012f"
    static let base_url = "https://api.themoviedb.org"
    static let language = "zh-CN"
    static let YoutubeAPI_KEY = "AIzaSyC-iRfggcVu-t3AXLltG_wld2rfuS5sqMk"
    static let YoutubeBaseURL = "https://youtube.googleapis.com/youtube/v3/search?"
    static let PexelsAPI_KEY = "A38uNxp3zKmohN3VGFJkgx6XfGeWXExvNvccOJLCTObT9TinOd56c9uI"
    static let PexelsBaseURL = "https://api.pexels.com/videos/search?"
}

enum APIError: Error {
    case failedTogetData
}

// 定义响应 api 的类
class APICaller{
    
    // 使用单例模式创建 apicaller 实例
    static let shared = APICaller()
    
    // 通过 url 获取数据，使用逃逸闭包，用于异步返回结果
    func getTrendingMovie(completion: @escaping (Result<[Title], Error>) -> Void){
        guard let url = URL(string: "\(Constants.base_url)/3/trending/movie/day?language=\(Constants.language)&api_key=\(Constants.API_KEY)") else {
            return
        }
        // 使用 URLSession 创建一个网络请求任务，创建一个简单的 URLRequest，默认方法为 GET。dataTask(with:completionHandler:)：创建并返回一个 URLSessionDataTask，用于发送请求并处理响应。completionHandler，用于处理网络请求的响应
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){ data, _, error in
            // 确保响应数据不为空，确保没有错误
            guard let data = data, error == nil else {
                return
            }
            do{
                // 将数据转化为 swift 对象
                let results = try JSONDecoder().decode(TrendingTitleResponse.self, from: data)
                completion(.success(results.results))
            }catch{
                completion(.failure(APIError.failedTogetData))
            }
        }
        // 启动网络请求
        task.resume()
    }
    //获取热门 tv
    func getTrendingTV(completion: @escaping (Result<[Title], Error>) ->Void){
        guard let url = URL(string: "\(Constants.base_url)/3/trending/tv/day?language=\(Constants.language)&api_key=\(Constants.API_KEY)") else{
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){ data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(TrendingTitleResponse.self, from: data)
                completion(.success(results.results))
            }catch{
                completion(.failure(APIError.failedTogetData))
            }
        }
        task.resume()
    }
    // 获取将会更新的电影
    func getUpcomingMovie(completion: @escaping (Result<[Title], Error>) ->Void){
        guard let url = URL(string: "\(Constants.base_url)/3/movie/upcoming?language=\(Constants.language)&page=1&&api_key=\(Constants.API_KEY)") else{
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){
            data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(TrendingTitleResponse.self, from: data)
                completion(.success(results.results))
            }catch
            {
                completion(.failure(APIError.failedTogetData))
            }
        }
        task.resume()
    }
    
    // 获取受欢迎的电影
    func getPopular(completion: @escaping(Result<[Title], Error>) -> Void){
        guard let url = URL(string: "\(Constants.base_url)/3/movie/upcoming?language=\(Constants.language)&page=1&&api_key=\(Constants.API_KEY)") else{
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){
            data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(TrendingTitleResponse.self, from: data)
                completion(.success(results.results))
            }catch{
                completion(.failure(APIError.failedTogetData))
            }
        }
        task.resume()
    }
    // 获取评分最高的电影
    func getTopRate(completion: @escaping(Result<[Title], Error>) -> Void){
        guard let url = URL(string: "\(Constants.base_url)/3/movie/top_rated?language=\(Constants.language)&page=1&&api_key=\(Constants.API_KEY)") else{
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){
            data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(TrendingTitleResponse.self, from: data)
                completion(.success(results.results))
            }catch{
                completion(.failure(APIError.failedTogetData))
            }
        }
        task.resume()
    }
    func getDiscoverMovies(completion: @escaping(Result<[Title], Error>) -> Void){
        guard let url = URL(string: "\(Constants.base_url)/3/discover/movie?api_key=\(Constants.API_KEY)&language=\(Constants.language)&sort_by=popularity.desc&include_adult=false&include_video=false&page=18with_watch_monetization_types=flatrate") else{
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){
            data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(TrendingTitleResponse.self, from: data)
                completion(.success(results.results))
            }catch{
                completion(.failure(APIError.failedTogetData))
            }
        }
        task.resume()
    }
    // 定义查询
    func search(with query: String, completion: @escaping(Result<[Title], Error>) -> Void){
        
        // 将字符串 query 进行百分比编码（percent-encoding），以便安全地用作 URL 的主机部分。
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)else {
            return
        }
        guard let url = URL(string: "\(Constants.base_url)/3/search/movie?api_key=\(Constants.API_KEY)&language=\(Constants.language)&query=\(query)") else{
            return
        }
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){
            data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(TrendingTitleResponse.self, from: data)
                completion(.success(results.results))
            }catch{
                completion(.failure(APIError.failedTogetData))
            }
        }
        task.resume()
    }
    //  youtube
    func getMovie(with query: String, completion: @escaping (Result<VideoElement, Error>) -> Void){
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return
        }
        guard let url = URL(string: "\(Constants.YoutubeBaseURL)q=\(query)&key=\(Constants.YoutubeAPI_KEY)") else {return}
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)){
            data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(YoutubeSearchResponse.self, from: data)
                completion(.success(results.items[0]))
            }catch{
                completion(.failure(APIError.failedTogetData))
            }
        }
        task.resume()
    }
    
    func getDownloadMovie(with query: String, completion: @escaping (Result<PexelsVideo, Error>) -> Void){
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return
        }
        guard let url = URL(string: "\(Constants.PexelsBaseURL)query=\(query)")else {
            return
        }
        // 设置请求头
        var request = URLRequest(url: url)
        request.setValue("\(Constants.PexelsAPI_KEY)", forHTTPHeaderField: "Authorization") // 替换为你的 Pexels API 密钥
        let task = URLSession.shared.dataTask(with: request){
            data, _, error in
            guard let data = data, error == nil else{
                return
            }
            do{
                let results = try JSONDecoder().decode(PexelsVideoResponse.self, from: data)
                completion(.success(results.videos[0]))
            }catch{
                completion(.failure(error))
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    
}

