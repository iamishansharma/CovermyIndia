//
//  searchVC.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 21/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

import UIKit
import MapmyIndiaAPIKit
import MapmyIndiaMaps

class SearchVC: UIViewController, MapmyIndiaMapViewDelegate, UISearchBarDelegate
{
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var table: UITableView!

    var data = [MapmyIndiaAtlasSuggestion]()

    override func viewDidLoad()
    {
        super.viewDidLoad();
        searchBar.delegate = self
        table.delegate = self;
        table.dataSource = self;
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        let autoSuggestManager = MapmyIndiaAutoSuggestManager.shared

        let autoSuggestOptions = MapmyIndiaAutoSearchAtlasOptions(query: searchText, withRegion: .india)

        autoSuggestOptions.zoom = 5
        autoSuggestManager.getAutoSuggestions(autoSuggestOptions)
        {
            (suggestions,error) in
            if error != nil
            {
                /*self.showAlert(title: "Location not found!", message: "'\(searchText ?? "nil")' not found.",
                    handlerOK:
                    {
                        action in
                },
                    handlerCancle:
                    {
                        actionCanel in
                })*/
            }
            else if let suggestions = suggestions, !suggestions.isEmpty
            {
                let n = suggestions.count;

                self.data.removeAll();

                for i in 0...n-1
                {
                    self.data.append(suggestions[i]);
                }

                self.table.reloadData();
            }
            else
            {
                /*self.showAlert(title: "Location not found!", message: "'\(textField.text ?? "nil")' not found.",
                    handlerOK:
                    {
                        action in
                },
                    handlerCancle:
                    {
                        actionCanel in
                })*/
            }
        }
    }

    func showAlert(title: String, message: String, handlerOK:((UIAlertAction) -> Void)?, handlerCancle: ((UIAlertAction) -> Void)?)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Try Again", style: .destructive, handler: handlerOK)
        alert.addAction(action)
        DispatchQueue.main.async
        {
                self.present(alert, animated: true, completion: nil)
        }
    }
}

extension SearchVC: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row].placeName
        cell.detailTextLabel?.text = data[indexPath.row].placeAddress
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {

    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.dismiss(animated: true, completion: nil);
    }
}
