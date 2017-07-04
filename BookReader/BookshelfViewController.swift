//
//  BookshelfViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit

class BookshelfViewController: UITableViewController {
    var documents = [PDFDocument]()

    let thumbnailCache = NSCache<NSURL, UIImage>()
    private let downloadQueue = DispatchQueue(label: "com.kishikawakatsumi.pdfviewer.thumbnail")

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorInset.left = 56
        refreshData()
        NotificationCenter.default.addObserver(self, selector: #selector(documentDirectoryDidChange(_:)), name: .documentDirectoryDidChange, object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? BookViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            viewController.pdfDocument = documents[indexPath.row]
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BookshelfCell

        let document = documents[indexPath.row]
        if let documentAttributes = document.documentAttributes {
            if let title = documentAttributes["Title"] as? String {
                cell.title = title
            }
            if let author = documentAttributes["Author"] as? String {
                cell.author = author
            }
            if document.pageCount > 0 {
                if let page = document.page(at: 0), let key = document.documentURL as NSURL? {
                    cell.url = key

                    if let thumbnail = thumbnailCache.object(forKey: key) {
                        cell.thumbnail = thumbnail
                    } else {
                        downloadQueue.async {
                            let thumbnail = page.thumbnail(of: CGSize(width: 40, height: 60), for: .cropBox)
                            self.thumbnailCache.setObject(thumbnail, forKey: key)
                            if cell.url == key {
                                DispatchQueue.main.async {
                                    cell.thumbnail = thumbnail
                                }
                            }
                        }
                    }
                }
            }
        }
        return cell
    }

    private func refreshData() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let contents = try! fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        documents = contents.flatMap { PDFDocument(url: $0) }

        tableView.reloadData()
    }

    @objc func documentDirectoryDidChange(_ notification: Notification) {
        refreshData()
    }
}
