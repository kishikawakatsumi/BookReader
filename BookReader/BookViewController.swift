//
//  BookViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit
import MessageUI
import UIKit.UIGestureRecognizerSubclass

class BookViewController: UIViewController, UIPopoverPresentationControllerDelegate, PDFViewDelegate, ActionMenuViewControllerDelegate, SearchViewControllerDelegate, ThumbnailGridViewControllerDelegate, OutlineViewControllerDelegate, BookmarkViewControllerDelegate {
    var pdfDocument: PDFDocument?

    @IBOutlet weak var pdfView: PDFView!

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var thumbnailViewContainer: UIView!
    @IBOutlet weak var thumbnailViewContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pdfThumbnailView: PDFThumbnailView!

    let tableOfContentsToggleSegmentedControl = UISegmentedControl(items: [#imageLiteral(resourceName: "Grid"), #imageLiteral(resourceName: "List"), #imageLiteral(resourceName: "Bookmark-N")])
    @IBOutlet weak var thumbnailGridViewConainer: UIView!
    @IBOutlet weak var outlineViewConainer: UIView!
    @IBOutlet weak var bookmarkViewConainer: UIView!

    var bookmarkButton: UIBarButtonItem!

    var searchNavigationController: UINavigationController?
    let barHideOnTapGestureRecognizer = UITapGestureRecognizer()
    let pdfViewGestureRecognizer = PDFViewGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(pdfViewPageChanged(_:)), name: .PDFViewPageChanged, object: nil)

        barHideOnTapGestureRecognizer.addTarget(self, action: #selector(gestureRecognizedToggleVisibility(_:)))
        view.addGestureRecognizer(barHideOnTapGestureRecognizer)

        tableOfContentsToggleSegmentedControl.selectedSegmentIndex = 0
        tableOfContentsToggleSegmentedControl.addTarget(self, action: #selector(toggleTableOfContentsView(_:)), for: .valueChanged)

        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: [UIPageViewControllerOptionInterPageSpacingKey: 20])

        pdfView.addGestureRecognizer(pdfViewGestureRecognizer)

        pdfView.document = pdfDocument

        pdfThumbnailView.layoutMode = .horizontal
        pdfThumbnailView.pdfView = pdfView

        resume()
    }

    override func viewDidLayoutSubviews() {
        var height = toolbar.frame.height
        if let navigationController = navigationController {
            height = navigationController.toolbar.frame.height
        }
        toolbarHeightConstraint.constant = height
        thumbnailViewContainerHeightConstraint.constant = height
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ThumbnailGridViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        } else if let viewController = segue.destination as? OutlineViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        } else if let viewController = segue.destination as? BookmarkViewController {
            viewController.pdfDocument = pdfDocument
            viewController.delegate = self
        }
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func actionMenuViewControllerShareDocument(_ actionMenuViewController: ActionMenuViewController) {
        let mailComposeViewController = MFMailComposeViewController()
        if let lastPathComponent = pdfDocument?.documentURL?.lastPathComponent,
            let documentAttributes = pdfDocument?.documentAttributes,
            let attachmentData = pdfDocument?.dataRepresentation() {
            if let title = documentAttributes["Title"] as? String {
                mailComposeViewController.setSubject(title)
            }
            mailComposeViewController.addAttachmentData(attachmentData, mimeType: "application/pdf", fileName: lastPathComponent)
        }
    }

    func actionMenuViewControllerPrintDocument(_ actionMenuViewController: ActionMenuViewController) {
        let printInteractionController = UIPrintInteractionController.shared
        printInteractionController.printingItem = pdfDocument?.dataRepresentation()
        printInteractionController.present(animated: true, completionHandler: nil)
    }

    func searchViewController(_ searchViewController: SearchViewController, didSelectSearchResult selection: PDFSelection) {
        selection.color = .yellow
        pdfView.currentSelection = selection
        pdfView.go(to: selection)
        showBars()
    }

    func thumbnailGridViewController(_ thumbnailGridViewController: ThumbnailGridViewController, didSelectPage page: PDFPage) {
        resume()
        pdfView.go(to: page)
    }

    func outlineViewController(_ outlineViewController: OutlineViewController, didSelectOutlineAt destination: PDFDestination) {
        resume()
        pdfView.go(to: destination)
    }

    func bookmarkViewController(_ bookmarkViewController: BookmarkViewController, didSelectPage page: PDFPage) {
        resume()
        pdfView.go(to: page)
    }

    private func resume() {
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Chevron"), style: .plain, target: self, action: #selector(back(_:)))
        let tableOfContentsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "List"), style: .plain, target: self, action: #selector(showTableOfContents(_:)))
        let actionButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showActionMenu(_:)))
        navigationItem.leftBarButtonItems = [backButton, tableOfContentsButton, actionButton]

        let brightnessButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Brightness"), style: .plain, target: self, action: #selector(showAppearanceMenu(_:)))
        let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Search"), style: .plain, target: self, action: #selector(showSearchView(_:)))
        bookmarkButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Bookmark-N"), style: .plain, target: self, action: #selector(addOrRemoveBookmark(_:)))
        navigationItem.rightBarButtonItems = [bookmarkButton, searchButton, brightnessButton]

        toolbar.alpha = 1
        thumbnailViewContainer.alpha = 1

        pdfView.isHidden = false
        thumbnailGridViewConainer.isHidden = true
        outlineViewConainer.isHidden = true

        barHideOnTapGestureRecognizer.isEnabled = true

        updateBookmarkStatus()
    }

    private func showTableOfContents() {
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "Chevron"), style: .plain, target: self, action: #selector(back(_:)))
        let tableOfContentsBarButton = UIBarButtonItem(title: NSLocalizedString("Resume", comment: ""), style: .plain, target: self, action: #selector(resume(_:)))
        navigationItem.leftBarButtonItems = [backButton, tableOfContentsBarButton]
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: tableOfContentsToggleSegmentedControl)]

        toolbar.alpha = 0
        thumbnailViewContainer.alpha = 0

        toggleTableOfContentsView(tableOfContentsToggleSegmentedControl)

        barHideOnTapGestureRecognizer.isEnabled = false
    }

    @objc func resume(_ sender: UIBarButtonItem) {
        resume()
    }

    @objc func back(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    @objc func showTableOfContents(_ sender: UIBarButtonItem) {
        showTableOfContents()
    }

    @objc func showActionMenu(_ sender: UIBarButtonItem) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: String(describing: ActionMenuViewController.self)) as? ActionMenuViewController {
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = CGSize(width: 300, height: 88)
            viewController.popoverPresentationController?.barButtonItem = sender
            viewController.popoverPresentationController?.permittedArrowDirections = .up
            viewController.popoverPresentationController?.delegate = self
            viewController.delegate = self
            present(viewController, animated: true, completion: nil)
        }
    }

    @objc func showAppearanceMenu(_ sender: UIBarButtonItem) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: String(describing: AppearanceViewController.self)) as? AppearanceViewController {
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = CGSize(width: 300, height: 44)
            viewController.popoverPresentationController?.barButtonItem = sender
            viewController.popoverPresentationController?.permittedArrowDirections = .up
            viewController.popoverPresentationController?.delegate = self
            present(viewController, animated: true, completion: nil)
        }
    }

    @objc func showSearchView(_ sender: UIBarButtonItem) {
        if let searchNavigationController = self.searchNavigationController {
            present(searchNavigationController, animated: true, completion: nil)
        } else if let navigationController = storyboard?.instantiateViewController(withIdentifier: String(describing: SearchViewController.self)) as? UINavigationController,
            let searchViewController = navigationController.topViewController as? SearchViewController {
            searchViewController.pdfDocument = pdfDocument
            searchViewController.delegate = self
            present(navigationController, animated: true, completion: nil)

            searchNavigationController = navigationController
        }
    }

    @objc func addOrRemoveBookmark(_ sender: UIBarButtonItem) {
        if let documentURL = pdfDocument?.documentURL?.absoluteString {
            var bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int] ?? [Int]()
            if let currentPage = pdfView.currentPage,
                let pageIndex = pdfDocument?.index(for: currentPage) {
                if let index = bookmarks.index(of: pageIndex) {
                    bookmarks.remove(at: index)
                    UserDefaults.standard.set(bookmarks, forKey: documentURL)
                    bookmarkButton.image = #imageLiteral(resourceName: "Bookmark-N")
                } else {
                    UserDefaults.standard.set((bookmarks + [pageIndex]).sorted(), forKey: documentURL)
                    bookmarkButton.image = #imageLiteral(resourceName: "Bookmark-P")
                }
            }
        }
    }

    @objc func toggleTableOfContentsView(_ sender: UISegmentedControl) {
        pdfView.isHidden = true
        if tableOfContentsToggleSegmentedControl.selectedSegmentIndex == 0 {
            thumbnailGridViewConainer.isHidden = false
            outlineViewConainer.isHidden = true
            bookmarkViewConainer.isHidden = true
        } else if tableOfContentsToggleSegmentedControl.selectedSegmentIndex == 1 {
            thumbnailGridViewConainer.isHidden = true
            outlineViewConainer.isHidden = false
            bookmarkViewConainer.isHidden = true
        } else {
            thumbnailGridViewConainer.isHidden = true
            outlineViewConainer.isHidden = true
            bookmarkViewConainer.isHidden = false
        }
    }

    @objc func pdfViewPageChanged(_ notification: Notification) {
        if pdfViewGestureRecognizer.isTracking {
            hideBars()
        }
        updateBookmarkStatus()
    }

    @objc func gestureRecognizedToggleVisibility(_ gestureRecognizer: UITapGestureRecognizer) {
        if let navigationController = navigationController {
            if navigationController.navigationBar.alpha > 0 {
                hideBars()
            } else {
                showBars()
            }
        }
    }

    private func updateBookmarkStatus() {
        if let documentURL = pdfDocument?.documentURL?.absoluteString,
            let bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int],
            let currentPage = pdfView.currentPage,
            let index = pdfDocument?.index(for: currentPage) {
            bookmarkButton.image = bookmarks.contains(index) ? #imageLiteral(resourceName: "Bookmark-P") : #imageLiteral(resourceName: "Bookmark-N")
        }
    }

    private func showBars() {
        if let navigationController = navigationController {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                navigationController.navigationBar.alpha = 1
                self.toolbar.alpha = 1
                self.thumbnailViewContainer.alpha = 1
            }
        }
    }

    private func hideBars() {
        if let navigationController = navigationController {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                navigationController.navigationBar.alpha = 0
                self.toolbar.alpha = 0
                self.thumbnailViewContainer.alpha = 0
            }
        }
    }
}

class PDFViewGestureRecognizer: UIGestureRecognizer {
    var isTracking = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        isTracking = false
    }
}
