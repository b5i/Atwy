//
//  SearchViewController+UITableViewDelegate.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let rowView = tableView.cellForRow(at: indexPath) as? SearchHistoryEntryView, let removeAction = rowView.removeAction else { return nil }
        
        return .init(actions: [.init(style: .destructive, title: "Delete", handler: {_,_, completion in
            removeAction()
            completion(true)
        })])
    }
}
