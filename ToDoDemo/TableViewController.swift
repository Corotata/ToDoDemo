//
//  TableViewController.swift
//  ToDoDemo
//
//  Created by WANG WEI on 2017/7/6.
//  Copyright © 2017年 OneV's Den. All rights reserved.
//

import UIKit

let inputCellReuseId = "inputCell"
let todoCellResueId = "todoCell"

class TableViewController: UITableViewController {
    
    struct State: StateType {
        var dataSource = TableViewControllerDataSource(todos: [], owner: nil)
        var text: String = ""
    }
    
    enum Action: ActionType {
        case updateText(text: String)
        case addToDos(items: [String])
        case removeToDo(index: Int)
        case loadToDos
    }
    
    enum Command: CommandType {
        case loadToDos(completion: ([String]) -> Action )
    }
    
    func reducer(action: Action, state: State) -> (state: State, command: Command?) {
        var state = state
        var command: Command? = nil
        
        switch action {
        case .updateText(let text):
            state.text = text
        case .addToDos(let items):
            state.dataSource = TableViewControllerDataSource(todos: items + state.dataSource.todos, owner: state.dataSource.owner)
        case .removeToDo(let index):
            let oldTodos = state.dataSource.todos
            state.dataSource = TableViewControllerDataSource(todos: Array(oldTodos[..<index] + oldTodos[(index + 1)...]), owner: state.dataSource.owner)
        case .loadToDos:
            command = Command.loadToDos(completion: Action.addToDos)
        }
        return (state, command)
    }
    
    var store: Store<Action, State, Command>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataSource = TableViewControllerDataSource(todos: [], owner: self)
        store = Store<Action, State, Command>(reducer: reducer, initialState: State(dataSource: dataSource, text: ""))
        store.subscribe { [weak self] state, previousState, command in
            self?.updateView(state: state, previousState: previousState, command: command)
        }
        updateView(state: store.state, previousState: nil, command: nil)
        store.dispatch(.loadToDos)
    }
    
    func updateView(state: State, previousState: State?, command: Command?) {
        
        if let command = command {
            switch command {
            case .loadToDos(let handler):
                ToDoStore.shared.getToDoItems { self.store.dispatch(handler($0)) }
            }
        }
        
        guard let previousState = previousState else { return }
        
        if previousState.dataSource.todos != state.dataSource.todos {
            let dataSource = state.dataSource
            tableView.dataSource = dataSource
            tableView.reloadData()
            title = "TODO - (\(dataSource.todos.count))"
        }
        
        if (previousState.text != state.text) {
            let isItemLengthEnough = state.text.count >= 3
            navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
            
            let inputIndexPath = IndexPath(row: 0, section: TableViewControllerDataSource.Section.input.rawValue)
            let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell
            inputCell?.textField.text = state.text
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == TableViewControllerDataSource.Section.todos.rawValue else { return }
        store.dispatch(.removeToDo(index: indexPath.row))
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        store.dispatch(.addToDos(items: [store.state.text]))
        store.dispatch(.updateText(text: ""))
    }
}

extension TableViewController: TableViewInputCellDelegate {
    func inputChanged(cell: TableViewInputCell, text: String) {
        store.dispatch(.updateText(text: text))
    }
}

