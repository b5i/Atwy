//
//  SearchViewController+UITableViewDataSource.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if SearchView.Model.shared.autoCompletion.isEmpty && textBinding.text.isEmpty {
            return PersistenceModel.shared.currentData.searchHistory.count
        } else {
            return SearchView.Model.shared.autoCompletion.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchHistoryEntryView.reuseIdentifier, for: indexPath) as! SearchHistoryEntryView
        if textBinding.text.isEmpty {
            guard PersistenceModel.shared.currentData.searchHistory.count > indexPath.row else { cell.setupView(forText: "", clickAction: {}, removeAction: nil); return cell }
            let searchHistoryEntry = PersistenceModel.shared.currentData.searchHistory[indexPath.row]
            cell.setupView(forText: searchHistoryEntry.query, clickAction: { [weak searchBar, weak textBinding] in
                textBinding?.text = searchHistoryEntry.query
                searchBar?.dismissKeyboard()
            }, removeAction: { [weak autocompletionScrollView, weak clearHistoryLabel, weak textBinding] in
                PersistenceModel.shared.removeSearch(withUUID: searchHistoryEntry.uuid)
                autocompletionScrollView?.deleteRows(at: [indexPath], with: .automatic)
                clearHistoryLabel?.isHidden = !(textBinding?.text.isEmpty ?? false) || PersistenceModel.shared.currentData.searchHistory.isEmpty
            })
            return cell
        } else {
            guard SearchView.Model.shared.autoCompletion.count > indexPath.row else { cell.setupView(forText: "", clickAction: {}, removeAction: nil); return cell }
            
            let text = SearchView.Model.shared.autoCompletion[indexPath.row]
            cell.setupView(forText: text, clickAction: { [weak searchBar, weak textBinding] in
                textBinding?.text = text
                searchBar?.dismissKeyboard()
            }, removeAction: nil)
            return cell
        }
    }
}
