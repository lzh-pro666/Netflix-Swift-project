//
//  TitleViewModel.swift
//  Netflix project
//
//  Created by mac—lzh on 2025/3/12.
//

import Foundation

struct TitleViewModel{
    let titleName: String
    let posterURL: String
    let id: Int?
    
    init(titleName: String, posterURL: String, id: Int? = nil) {
        self.titleName = titleName
        self.posterURL = posterURL
        self.id = id
    }
}
