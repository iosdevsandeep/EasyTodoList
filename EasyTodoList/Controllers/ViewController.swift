//
//  ViewController.swift
//  EasyTodoList
//
//  Created by Vupadhi iOS on 06/12/24.
//

import UIKit
import Foundation

// MARK: - Model
struct TodoItemModel: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}

// MARK: - Repository Protocol with Async Methods
protocol TodoRepositoryProtocolModel {
    func addTodo(_ todo: TodoItemModel) async throws
    func removeTodo(_ todo: TodoItemModel) async throws
    func updateTodo(_ todo: TodoItemModel) async throws
    func getAllTodos() async -> [TodoItemModel]
    func getTodosByStatus(isCompleted: Bool) async -> [TodoItemModel]
}

// MARK: - Async Actor-based Repository
actor UserDefaultsTodoRepositoryModel: TodoRepositoryProtocolModel {
    private let userDefaults = UserDefaults.standard
    private let todosKey = "TodoItemModels"
    private var cachedTodos: [TodoItemModel] = []
    
    init() {
        Task { await loadInitialTodos() }
    }
    
    private func loadInitialTodos() {
        guard let data = userDefaults.data(forKey: todosKey),
              let todos = try? JSONDecoder().decode([TodoItemModel].self, from: data) else {
            return
        }
        cachedTodos = todos
    }
    
    private func saveTodos() throws {
        let data = try JSONEncoder().encode(cachedTodos)
        userDefaults.set(data, forKey: todosKey)
    }
    
    func addTodo(_ todo: TodoItemModel) async throws {
        cachedTodos.append(todo)
        try saveTodos()
    }
    
    func removeTodo(_ todo: TodoItemModel) async throws {
        cachedTodos.removeAll { $0.id == todo.id }
        try saveTodos()
    }
    
    func updateTodo(_ todo: TodoItemModel) async throws {
        guard let index = cachedTodos.firstIndex(where: { $0.id == todo.id }) else {
            return
        }
        cachedTodos[index] = todo
        try saveTodos()
    }
    
    func getAllTodos() async -> [TodoItemModel] {
        return cachedTodos
    }
    
    func getTodosByStatus(isCompleted: Bool) async -> [TodoItemModel] {
        return cachedTodos.filter { $0.isCompleted == isCompleted }
    }
}

// MARK: - ViewModel with Concurrency
@MainActor
class TodoViewModelModel {
    private let repository: TodoRepositoryProtocolModel
    private(set) var todos: [TodoItemModel] = []
    private(set) var completedTodos: [TodoItemModel] = []
    private(set) var pendingTodos: [TodoItemModel] = []
    
    var todosUpdated: ((Result<Void, Error>) -> Void)?
    
    init(repository: TodoRepositoryProtocolModel = UserDefaultsTodoRepositoryModel()) {
        self.repository = repository
        Task { await fetchTodos() }
    }
    
    func fetchTodos() async {
        do {
            todos = await repository.getAllTodos()
            completedTodos = await repository.getTodosByStatus(isCompleted: true)
            pendingTodos = await repository.getTodosByStatus(isCompleted: false)
            
            // Sort todos by creation date
            todos.sort { $0.createdAt > $1.createdAt }
            completedTodos.sort { $0.createdAt > $1.createdAt }
            pendingTodos.sort { $0.createdAt > $1.createdAt }
            
            todosUpdated?(.success(()))
        } catch {
            todosUpdated?(.failure(error))
        }
    }
    
    func addTodo(title: String) {
        Task {
            do {
                let newTodo = TodoItemModel(title: title)
                try await repository.addTodo(newTodo)
                await fetchTodos()
            } catch {
                todosUpdated?(.failure(error))
            }
        }
    }
    
//    func toggleTodoCompletion(todo: TodoItemModel) {
//        Task {
//            do {
//                var updatedTodo = todo
//                updatedTodo.isCompleted.toggle()
//                try await repository.updateTodo(updatedTodo)
//                await fetchTodos()
//            } catch {
//                todosUpdated?(.failure(error))
//            }
//        }
//    }
    
    func toggleTodoCompletion(todo: TodoItemModel) {
        Task {
            do {
                var updatedTodo = todo
                updatedTodo.isCompleted.toggle()
                try await repository.updateTodo(updatedTodo)
                
                // Remove the task from the previous list and add it to the new list
                if updatedTodo.isCompleted {
                    pendingTodos.removeAll { $0.id == updatedTodo.id }
                    completedTodos.append(updatedTodo)
                } else {
                    completedTodos.removeAll { $0.id == updatedTodo.id }
                    pendingTodos.append(updatedTodo)
                }
                
                // Sort the lists by creation date
                pendingTodos.sort { $0.createdAt > $1.createdAt }
                completedTodos.sort { $0.createdAt > $1.createdAt }
                
                // Update the main todos list
                todos = pendingTodos + completedTodos
                
                await fetchTodos()
                
                todosUpdated?(.success(()))
            } catch {
                todosUpdated?(.failure(error))
            }
        }
    }
    
    func deleteTodo(todo: TodoItemModel) {
        Task {
            do {
                try await repository.removeTodo(todo)
                await fetchTodos()
            } catch {
                todosUpdated?(.failure(error))
            }
        }
    }
}

// MARK: - Main View Controller
class ViewController: UIViewController {
    private let viewModel = TodoViewModelModel()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TodoCell")
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        table.estimatedRowHeight = 100
        table.rowHeight = UITableView.automaticDimension
        return table
    }()
    
    private lazy var addButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewTodo))
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshTodos), for: .valueChanged)
        return refresh
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Todo List"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = addButton
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.refreshControl = refreshControl
    }
    
    private func bindViewModel() {
        viewModel.todosUpdated = { [weak self] result in
            switch result {
            case .success:
                self?.tableView.reloadData()
                self?.refreshControl.endRefreshing()
            case .failure(let error):
                self?.showErrorAlert(error)
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc private func addNewTodo() {
        let alertController = UIAlertController(title: "New Todo", message: "Enter a new task", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Task description"
            textField.autocapitalizationType = .words
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let textField = alertController.textFields?.first,
                  let text = textField.text, !text.isEmpty else { return }
            self?.viewModel.addTodo(title: text)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @objc private func refreshTodos() {
        Task {
            await viewModel.fetchTodos()
        }
    }
    
    private func showErrorAlert(_ error: Error) {
        let alertController = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource Extension
extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Pending and Completed sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? viewModel.pendingTodos.count : viewModel.completedTodos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath)
        
        let todo = indexPath.section == 0 ? viewModel.pendingTodos[indexPath.row] : viewModel.completedTodos[indexPath.row]
        
        cell.textLabel?.text = todo.title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textColor = todo.isCompleted ? .systemGray : .label
        cell.textLabel?.attributedText = todo.isCompleted ? NSAttributedString(string: todo.title, attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]) : NSAttributedString(string: todo.title, attributes: [.strikethroughStyle: nil])


        
        print("iscompleted", todo.isCompleted)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return section == 0 ? "Pending Tasks" : "Completed Tasks"
    }
}

// MARK: - UITableViewDelegate Extension
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let todo = indexPath.section == 0 ? viewModel.pendingTodos[indexPath.row] : viewModel.completedTodos[indexPath.row]
        viewModel.toggleTodoCompletion(todo: todo)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let todo = indexPath.section == 0 ? viewModel.pendingTodos[indexPath.row] : viewModel.completedTodos[indexPath.row]
            viewModel.deleteTodo(todo: todo)
        }
    }
}


