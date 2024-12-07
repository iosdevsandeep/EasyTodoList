//
//  TodoRepositoryProtocol.swift
//  EasyTodoList
//
//  Created by Vupadhi iOS on 06/12/24.
//

import Foundation
import UIKit

//MARK: Protocol for TodoItem Repository
protocol TodoRepositoryProtocol {
    func addTodo(_ todo: TodoItem)
    func removeTodo(_ todo: TodoItem)
    func updateTodo(_ todo: TodoItem)
    func getAllTodos() -> [TodoItem]
    func getTodosByStatus(isCompleted: Bool) -> [TodoItem]
}
