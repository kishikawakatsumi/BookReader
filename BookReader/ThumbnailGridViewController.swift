//
//  ThumbnailGridViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit

class ThumbnailGridViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var pdfDocument: PDFDocument?
    weak var delegate: ThumbnailGridViewControllerDelegate?

    private let downloadQueue = DispatchQueue(label: "com.kishikawakatsumi.pdfviewer.thumbnail")
    let thumbnailCache = NSCache<NSNumber, UIImage>()

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
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pdfDocument?.pageCount ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ThumbnailGridCell

        if let page = pdfDocument?.page(at: indexPath.item) {
            let pageNumber = indexPath.item
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
        if let page = pdfDocument?.page(at: indexPath.item) {
            delegate?.thumbnailGridViewController(self, didSelectPage: page)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
}

protocol ThumbnailGridViewControllerDelegate: class {
    func thumbnailGridViewController(_ thumbnailGridViewController: ThumbnailGridViewController, didSelectPage page: PDFPage)
}
