//
//  ActionViewController.swift
//  Extension
//
//  Created by Michele Galvagno on 17/04/2019.
//  Copyright © 2019 Michele Galvagno. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {
    // Properties and outlets
    @IBOutlet var script: UITextView!
    
    var pageTitle = ""
    var pageURL = ""
    
    var userDefaults: UserDefaults!
    var savedScripts: [String: String] = [:]
    var keyName = "customJSExtension"

    // View management
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userDefaults = UserDefaults.standard
        savedScripts = userDefaults.dictionary(forKey: keyName) as? [String: String] ?? [:]
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        let chooseButton = UIBarButtonItem(title: "Choose", style: .plain, target: self, action: #selector(chooseScript))
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        let loadButton = UIBarButtonItem(title: "Load", style: .plain, target: self, action: #selector(load))
        navigationItem.leftBarButtonItems = [saveButton, loadButton, chooseButton]
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["url"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                        if let hostName = URL(string: self!.pageURL)?.host! {
                            let hostKey = "[autosaved from] " + hostName
                            let obj = self?.savedScripts[hostKey, default: "[Type your javascript in here]"]
                            
                            if let scriptText = obj {
                                self?.script.text = scriptText
                            }
                        }
                    }
                }
            }
        }
    }

    // Manage the pressing of the Done button in the text view
    @objc func done() {
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text!]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [customJavaScript]
        
        extensionContext?.completeRequest(returningItems: [item])
        
        // save settings if we have a host
        if let hostName = URL(string: pageURL)?.host! {
            let hostKey = "[autosaved from] " + hostName
            savedScripts[hostKey] = script.text
            userDefaults.set(savedScripts, forKey: keyName)
        }
    }
    
    @objc func save() {
        let saveAC = UIAlertController(title: "Name your script", message: nil, preferredStyle: .alert)
        saveAC.addTextField()
        saveAC.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let saveName = saveAC.textFields![0].text {
                self.savedScripts[saveName] = self.script.text
                self.userDefaults.set(self.savedScripts, forKey: self.keyName)
                self.userDefaults.set(self.script.text, forKey: saveName)
            }
        })
        
        present(saveAC, animated: true)
    }
    
    @objc func load() {
        
    }
    
    @objc func chooseScript() {
        let ac = UIAlertController(title: "Choose Script", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Page Title", style: .default, handler: { _ in
            self.script.text = "alert(document.title);"
        }))
        ac.addAction(UIAlertAction(title: "Count Links", style: .default, handler: { _ in
            self.script.text = """
            var links = document.getElementsByTagName("a");
            alert("There are " + links.length + " links on this page.");
            """
        }))
        ac.addAction(UIAlertAction(title: "Just the Headlines", style: .default, handler: { _ in
            self.script.text = """
            for (var k=1; k<7; k++) {
            var headlines = document.getElementsByTagName("h" + k);
            var allHeadlines = ""
            for(var i=0; i<headlines.length; i++) {
            allHeadlines += headlines[i].innerText + " / ";
            }
            if (i>0) {
            alert("There are " + i + " level " + k + " headlines: " + allHeadlines);}
            }
            """
        }))
        ac.addAction(UIAlertAction(title: "Hacked with Swift", style: .default, handler: { _ in
            self.script.text = """
            var level = prompt("Which headlines shall we change (choose from 1 to 6)?")
            var newHeadline = prompt("And what shall we change them to?")
            
            var headlines = document.getElementsByTagName("h" + level);
            
            for(var i=0; i<headlines.length; i++) {
            headlines[i].innerText = newHeadline
            }
            """
        }))
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    // Manage the keyboard state change
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue // tells us the size of the keyboard
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
}
