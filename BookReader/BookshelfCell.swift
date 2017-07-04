//
//  BookshelfCell.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/04.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

class BookshelfCell: UITableViewCell {
    var thumbnail: UIImage? = nil {
        didSet {
            thumbnailImageView.image = thumbnail
        }
    }
    var title: String = "No title" {
        didSet {
            titleLabel.text = title
        }
    }
    var author: String = "" {
        didSet {
            authorLabel.text = author
        }
    }
    var url: NSURL?

    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var authorLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        authorLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        authorLabel.textColor = .gray

        titleLabel.text = title
        authorLabel.text = author
    }

    override func prepareForReuse() {
        thumbnailImageView.image = nil
    }
}
