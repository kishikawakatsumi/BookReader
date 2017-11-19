//
//  OutlineCell.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

class OutlineCell: UITableViewCell {
    var label: String? = nil {
        didSet {
            titleLabel.text = label
        }
    }
    var pageLabel: String? = nil {
        didSet {
            pageNumberLabel.text = pageLabel
        }
    }
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pageNumberLabel: UILabel!
    @IBOutlet private weak var indentationConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        pageNumberLabel.textColor = .gray
        pageNumberLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
    }

    override func updateConstraints() {
        super.updateConstraints()
        indentationConstraint.constant = CGFloat(15 + 10 * indentationLevel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if indentationLevel == 0 {
            titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        } else {
            titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        }

        separatorInset = UIEdgeInsets(top: 0, left: safeAreaInsets.right + indentationConstraint.constant, bottom: 0, right: 0)
    }
}
