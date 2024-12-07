//
//  TodoItem.swift
//  EasyTodoList
//
//  Created by Vupadhi iOS on 06/12/24.
//

import Foundation
import UIKit

//MARK: Data Model
struct TodoItem: Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    
    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
    }
}
