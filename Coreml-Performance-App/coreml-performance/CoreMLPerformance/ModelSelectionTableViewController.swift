//
//  ModelSelectionTableViewController.swift
//  CoreMLPerformance
//
//  Created by Jiarui Yu on 4/28/23.
//  Copyright © 2023 Vladimir Chernykh. All rights reserved.
//

import UIKit


class ModelSelectionTableViewController: UITableViewController {
    weak var delegate: ModelSelectionDelegate?
    
    let models = ["MobileVit", "Mobilenet", "Efficientnet", "Efficientformer", "Nextvit", "MobileOne", "FasterNet", "SwiftFormer"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Select Model"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = models[indexPath.row]
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showSubcategories(forModel: models[indexPath.row])
    }
    
    func showSubcategories(forModel model: String) {
        let subcategoriesTableViewController = SubcategoriesTableViewController()
        subcategoriesTableViewController.model = model
        subcategoriesTableViewController.delegate = delegate // Pass the delegate
        navigationController?.pushViewController(subcategoriesTableViewController, animated: true)
    }
}
