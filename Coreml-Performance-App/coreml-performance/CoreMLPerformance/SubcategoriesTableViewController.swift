//
//  SubcategoriesTableViewController.swift
//  CoreMLPerformance
//
//  Created by Jiarui Yu on 4/28/23.
//  Copyright © 2023 Vladimir Chernykh. All rights reserved.
//

import UIKit

protocol ModelSelectionDelegate: AnyObject {
    func didSelectModel(_ model: String)
}

class SubcategoriesTableViewController: UITableViewController {
    weak var delegate: ModelSelectionDelegate?
    
    var model: String?
    var subcategories: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = model
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        // Add subcategories based on the selected model
        switch model {
        case "MobileVit":
            subcategories = ["Mobilevit-xxs", "Mobilevit-xs", "Mobilevit-s", "Mobilevit_v2_050",
                             "Mobilevit_v2_100", "Mobilevit_v2_150"]
        case "Mobilenet":
            subcategories = ["mobilenet_v1", "mobilenet_v2", "mobilenet_v3_small", "mobilenet_v3_large"]
        case "Efficientnet":
            subcategories = ["efficientnet-b0", "efficientnet-b1", "efficientnet-b2", "efficientnet-b3",
                             "efficientnet-b4", "efficientnet-b5", "efficientnet-b6", "efficientnet-b7",
                             "efficientnet_v2_s", "efficientnet_v2_m", "efficientnet_v2_l"]
        case "Efficientformer":
            subcategories = ["efficientformer_l1", "efficientformer_l3", "efficientformer_l7",
                             "efficientformerv2_s0", "efficientformerv2_s1", "efficientformerv2_s2",
                             "efficientformerv2_l"]
        case "Nextvit":
            subcategories = ["nextvit_small_224x224", "nextvit_base_224x224", "nextvit_large_224x224"]
        case "MobileOne":
            subcategories = ["mobileone_s0", "mobileone_s1", "mobileone_s2", "mobileone_s3", "mobileone_s4"]
        case "FasterNet":
            subcategories = ["FasterNet-T0", "FasterNet-T1", "FasterNet-T2", "FasterNet-S", "FasterNet-M", "FasterNet-L"]
        case "SwiftFormer":
            subcategories = ["SwiftFormer_XS", "SwiftFormer_S", "SwiftFormer_L1", "SwiftFormer_L3"]
        default:
            break
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subcategories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = subcategories[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSubcategory = subcategories[indexPath.row]
        delegate?.didSelectModel(selectedSubcategory)
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

   

