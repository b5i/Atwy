//
//  SearchViewController+UITableViewDataSource.swift
//  Atwy
//
//  Created by Antoine Bollengier on 16.07.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import UIKit

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchHistoryEntryView.reuseIdentifier, for: indexPath) as! SearchHistoryEntryView
        
        switch indexPath.section {
        case 0:
            // history
            guard self.historyAutocompletionEntries.count > indexPath.row else { cell.setupView(forText: "", clickAction: {}, removeAction: nil); return cell }
            let searchHistoryEntry = self.historyAutocompletionEntries[indexPath.row]
            cell.setupView(forText: searchHistoryEntry.query, clickAction: { [weak searchBar, weak textBinding] in
                textBinding?.text = searchHistoryEntry.query
                searchBar?.dismissKeyboard()
            }, removeAction: { [weak self] in
                guard let self = self else { return }
                PersistenceModel.shared.removeSearch(withUUID: searchHistoryEntry.uuid)
                self.historyAutocompletionEntries.removeAll(where: {$0.uuid == searchHistoryEntry.uuid})
                self.autocompletionScrollView?.deleteRows(at: [indexPath], with: .automatic)
                self.clearHistoryLabel?.isHidden = !self.textBinding.text.isEmpty || self.historyAutocompletionEntries.isEmpty
            })
            return cell
        case 1:
            // search
            guard SearchView.Model.shared.autoCompletion.count > indexPath.row else { cell.setupView(forText: "", clickAction: {}, removeAction: nil); return cell }
            
            let text = SearchView.Model.shared.autoCompletion[indexPath.row]
            cell.setupView(forText: text, clickAction: { [weak searchBar, weak textBinding] in
                textBinding?.text = text
                searchBar?.dismissKeyboard()
            }, removeAction: nil)
            return cell
        default:
            cell.setupView(forText: "", clickAction: {}, removeAction: nil)
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // history
            return self.historyAutocompletionEntries.count
        case 1:
            // search
            return SearchView.Model.shared.autoCompletion.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            // history
            return self.historyAutocompletionEntries.isEmpty ? 0 : SearchSectionHeaderView.headerSize
        case 1:
            // search
            return SearchView.Model.shared.autoCompletion.isEmpty ? 0 : SearchSectionHeaderView.headerSize
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SearchSectionHeaderView.reuseIdentifier) as? SearchSectionHeaderView else { return nil }
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            // history
            return "Recent searches"
        case 1:
            // search
            return "Search suggestions"
        default:
            return nil
        }
    }
}
