//
//  BookmarkViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit

class BookmarkViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var pdfDocument: PDFDocument?
    var bookmarks = [Int]()

    weak var delegate: BookmarkViewControllerDelegate?

    let thumbnailCache = NSCache<NSNumber, UIImage>()
    private let downloadQueue = DispatchQueue(label: "com.kishikawakatsumi.pdfviewer.thumbnail")

    var cellSize: CGSize {
        if let collectionView = collectionView {
            var width = collectionView.frame.width
            var height = collectionView.frame.height
            if width > height {
                swap(&width, &height)
            }
            width = (width - 20 * 4) / 3
            height = width * 1.5
            return CGSize(width: width, height: height)
        }
        return CGSize(width: 100, height: 150)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundView = UIView()
        backgroundView.backgroundColor = .gray
        collectionView?.backgroundView = backgroundView

        collectionView?.register(UINib(nibName: String(describing: ThumbnailGridCell.self), bundle: nil), forCellWithReuseIdentifier: "Cell")

        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
        refreshData()
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookmarks.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ThumbnailGridCell

        let pageNumber = bookmarks[indexPath.item]
        if let page = pdfDocument?.page(at: pageNumber) {
            cell.pageNumber = pageNumber

            let key = NSNumber(value: pageNumber)
            if let thumbnail = thumbnailCache.object(forKey: key) {
                cell.image = thumbnail
            } else {
                let size = cellSize
                downloadQueue.async {
                    let thumbnail = page.thumbnail(of: size, for: .cropBox)
                    self.thumbnailCache.setObject(thumbnail, forKey: key)
                    if cell.pageNumber == pageNumber {
                        DispatchQueue.main.async {
                            cell.image = thumbnail
                        }
                    }
                }
            }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let page = pdfDocument?.page(at: bookmarks[indexPath.item]) {
            delegate?.bookmarkViewController(self, didSelectPage: page)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }

    private func refreshData() {
        if let documentURL = pdfDocument?.documentURL?.absoluteString,
            let bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int] {
            self.bookmarks = bookmarks
            collectionView?.reloadData()
        }
    }

    @objc func userDefaultsDidChange(_ notification: Notification) {
        refreshData()
    }
}

protocol BookmarkViewControllerDelegate: class {
    func bookmarkViewController(_ bookmarkViewController: BookmarkViewController, didSelectPage page: PDFPage)
}
