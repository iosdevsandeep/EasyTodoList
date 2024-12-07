//
//  UserDefaultsTodoRepository.swift
//  EasyTodoList
//
//  Created by Vupadhi iOS on 06/12/24.
//

import Foundation
import UIKit

//MARK: UserDefaults repository implementation
class UserDefaultsTodoRepository: TodoRepositoryProtocol {
    private let userDefaults = UserDefaults.standard
    private let todosKey = "TodoItems"
    
    private func saveTodos(_ todos: [TodoItem]) {
        if let data = try? JSONEncoder().encode(todos) {
            userDefaults.set(data, forKey: todosKey)
        }
    }
    
    func addTodo(_ todo: TodoItem) {
        var todos = getAllTodos()
        todos.append(todo)
        saveTodos(todos)
    }
    
    func removeTodo(_ todo: TodoItem) {
        var todos = getAllTodos()
        todos.removeAll { $0.id == todo.id }
        saveTodos(todos)
    }
    
    func updateTodo(_ todo: TodoItem) {
        var todos = getAllTodos()
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
            saveTodos(todos)
        }
    }
    
    func getAllTodos() -> [TodoItem] {
        guard let data = userDefaults.data(forKey: todosKey),
              let todos = try? JSONDecoder().decode([TodoItem].self, from: data) else {
                  return []
        }
        return todos
    }
    
    func getTodosByStatus(isCompleted: Bool) -> [TodoItem] {
        return getAllTodos().filter { $0.isCompleted == isCompleted }
    }
    
}
