//
//  DataPersistenceManager.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/4/14.
//

import Foundation
import UIKit
import CoreData


class DataPersistenceManager{
    
    enum DatabaseError: Error{
        case failedtoSaveData
        case failedtoFetchData
        case failedtoDeleteData
    }
    
    static let shared = DataPersistenceManager()
    
    func downloadTitleWith(model: Title, completion: @escaping (Result<Void, Error>) -> Void){
        // CoreData 的持久化存储（NSPersistentContainer）通常在 AppDelegate 中初始化
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        // CoreData 的所有数据操作（例如保存电影、标记收藏）都在上下文中进行。
        let context = appDelegate.persistentContainer.viewContext
        
        let item = TitleItem(context: context)
        item.original_title = model.original_title
        item.id = Int64(model.id)
        item.original_name = model.original_name
        item.overview = model.overview
        item.media_type = model.media_type
        item.poster_path = model.poster_path
        item.release_date = model.release_date
        item.vote_count = Int64(model.vote_count)
        
        do{
            try context.save()
            completion(.success(()))
        }catch{
            completion(.failure(DatabaseError.failedtoSaveData))
        }
    }
    
    // 保存视频信息到CoreData
    func downloadVideoWith(id: Int, url: String, link: String, localPath: String, completion: @escaping (Result<Void, Error>) -> Void){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        
        let item = VideoItem(context: context)
        item.id = Int64(id)
        item.url = url
        item.link = link
        item.localPath = localPath
        
        do{
            try context.save()
            completion(.success(()))
        }catch{
            completion(.failure(DatabaseError.failedtoSaveData))
        }
    }
    
    // 根据ID查询视频
    func fetchVideoWithID(_ id: Int, completion: @escaping(Result<VideoItem?, Error>) -> Void) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        
        let request: NSFetchRequest<VideoItem> = VideoItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        do {
            let videos = try context.fetch(request)
            completion(.success(videos.first))
        } catch {
            completion(.failure(DatabaseError.failedtoFetchData))
        }
    }
    
    // 获取所有视频
    func fetchingVideosFromDataBase(completion: @escaping(Result<[VideoItem], Error>) -> Void){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        
        let request: NSFetchRequest<VideoItem>
        request = VideoItem.fetchRequest()
        
        do{
            let videos = try context.fetch(request)
            completion(.success(videos))
        }catch{
            completion(.failure(DatabaseError.failedtoFetchData))
        }
    }
    
    // 删除视频
    func deleteVideoWith(model: VideoItem, completion: @escaping(Result<Void, Error>) -> Void){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        
        // 如果视频有本地文件，删除文件
        if let localPath = model.localPath, !localPath.isEmpty {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: localPath) {
                do {
                    try fileManager.removeItem(atPath: localPath)
                } catch {
                    print("删除视频文件失败: \(error.localizedDescription)")
                }
            }
        }
        
        context.delete(model)
        
        do{
            try context.save()
            completion(.success(()))
        }catch{
            completion(.failure(DatabaseError.failedtoDeleteData))
        }
    }
    
    func fetchingTitlesFromDataBase(completion: @escaping(Result<[TitleItem], Error>) -> Void){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        // CoreData 的所有数据操作（例如保存电影、标记收藏）都在上下文中进行。
        let context = appDelegate.persistentContainer.viewContext
        
        // 声明一个类型为 NSFetchRequest<TitleItem> 的常量 request，用于后续配置 CoreData 的查询请求。
        //NSFetchRequest 是 CoreData 中用于查询数据的对象，类似于 SQL 的 SELECT 语句。
        let request: NSFetchRequest<TitleItem>
        // TitleItem.fetchRequest() 是 CoreData 自动为实体生成的方法，返回一个针对 TitleItem 的默认 fetch 请求,会返回所有 TitleItem 实例。
        request = TitleItem.fetchRequest()
        
        do{
            // 调用上下文的 fetch(_:) 方法，执行 request 定义的查询。
            let titles = try context.fetch(request)
            completion(.success(titles))
        }catch{
            completion(.failure(DatabaseError.failedtoFetchData))
        }
            
    }
    func deleteTitlesWith(model: TitleItem, completion: @escaping(Result<Void, Error>) -> Void){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        // CoreData 的所有数据操作（例如保存电影、标记收藏）都在上下文中进行。
        let context = appDelegate.persistentContainer.viewContext
        context.delete(model)
        do{
            // 调用上下文的 fetch(_:) 方法，执行 request 定义的查询。
            try context.save()
            completion(.success(()))
        }catch{
            completion(.failure(DatabaseError.failedtoDeleteData))
        }
            
    }
}
