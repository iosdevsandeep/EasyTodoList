//
//  TodoViewController.swift
//  EasyTodoList
//
//  Created by Vupadhi iOS on 06/12/24.
//

import UIKit

class TodoViewController: UIViewController {

    private let viewModel = TodoViewModel()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        bindViewModel()
    }
    
    private func setUpUI() {
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
    }
    
    private func bindViewModel() {
        viewModel.todosUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc private func addNewTodo() {
        let aleretController = UIAlertController(title: "New Todo", message: "Enter a new Task", preferredStyle: .alert)
        
        aleretController.addTextField { textField in
            textField.placeholder = "Task description"
            textField.autocapitalizationType = .words
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let tf = aleretController.textFields?.first,
                  let text = tf.text, !text.isEmpty else { return }
            self?.viewModel.addTodo(title: text)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        aleretController.addAction(addAction)
        aleretController.addAction(cancelAction)
        
        present(aleretController, animated: true)
    }

}

extension TodoViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
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
        cell.textLabel?.strikeThrough = todo.isCompleted
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Pending Tasks" : "Completed Tasks"
    }
    
}

extension TodoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
        
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

