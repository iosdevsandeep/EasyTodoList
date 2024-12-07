//
//  TodoViewModel.swift
//  EasyTodoList
//
//  Created by Vupadhi iOS on 06/12/24.
//

import Foundation

//MARK: View model
class TodoViewModel {
    private let repository: TodoRepositoryProtocol
    private(set) var todos: [TodoItem] = []
    private(set) var completedTodos: [TodoItem] = []
    private(set) var pendingTodos: [TodoItem] = []
    
    var todosUpdated: (() -> Void)?
    
    init(repository: TodoRepositoryProtocol = UserDefaultsTodoRepository()) {
        self.repository = repository
        fetchTodos()
    }
    
    func fetchTodos() {
        todos = repository.getAllTodos()
        completedTodos = repository.getTodosByStatus(isCompleted: true)
        pendingTodos = repository.getTodosByStatus(isCompleted: false)
        todosUpdated?()
    }
    
    func addTodo(title: String) {
        let newTodo = TodoItem(title: title)
        repository.addTodo(newTodo)
        fetchTodos()
    }
    
    func toggleTodoCompletion(todo: TodoItem) {
        var updatedTodo = todo
        updatedTodo.isCompleted.toggle()
        repository.updateTodo(updatedTodo)
        
        // Remove the task from the previous list and add it to the new list
        if updatedTodo.isCompleted {
            pendingTodos.removeAll { $0.id == updatedTodo.id }
            completedTodos.append(updatedTodo)
        } else {
            completedTodos.removeAll { $0.id == updatedTodo.id }
            pendingTodos.append(updatedTodo)
        }
        
        // Sort the lists by creation date
        pendingTodos.sort { $0.id > $1.id }
        completedTodos.sort { $0.id > $1.id }
        
        // Update the main todos list
        todos = pendingTodos + completedTodos
       
        fetchTodos()
    }
    
    func deleteTodo(todo: TodoItem) {
        repository.removeTodo(todo)
        fetchTodos()
    }
}
