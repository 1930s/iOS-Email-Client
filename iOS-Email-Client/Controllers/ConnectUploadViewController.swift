//
//  ConnectUploadViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftWebSocket

class ConnectUploadViewController: UIViewController{
    
    let keyData = AESCipher.generateRandomBytes()
    let ivData = AESCipher.generateRandomBytes()
    let PROGRESS_PREPARING_MAILBOX = 40.0
    let PROGRESS_GET_KEYS = 50.0
    let PROGRESS_UPLOADING_FILE = 90.0
    let PROGRESS_SEND_DATA = 99.0
    let PROGRESS_COMPLETE = 100.0
    
    enum Status {
        case none
        case processing
        case processed
    }
    
    @IBOutlet var connectUIView: ConnectUIView!
    var linkData: LinkData!
    var myAccount: Account!
    var mailboxDelegate: WebSocketManagerDelegate?
    var databasePath : String?
    var keyBundleReady = false
    var scheduleWorker = ScheduleWorker(interval: 5.0, maxRetries: 12)
    var state: ConnectionState = .link
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    internal enum ConnectionState{
        case link
        case creatingDB(Int32)
        case waiting
        case upload(String)
        case sendData
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mailboxDelegate = WebSocketManager.sharedInstance.delegate
        WebSocketManager.sharedInstance.delegate = self
        connectUIView.initialLoad(email: "\(myAccount.username)\(Constants.domain)")
        scheduleWorker.delegate = self
        self.connectUIView.goBackButton.isHidden = true
        self.connectUIView.setDeviceIcons(leftType: Device.Kind.current, rightType: Device.Kind(rawValue: linkData.deviceType)!)
        handleState()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        scheduleWorker.cancel()
        WebSocketManager.sharedInstance.delegate = mailboxDelegate
    }
    
    func handleState(){
        switch(state){
        case .link:
            linkAccept()
        case .creatingDB(let deviceId):
            createDBFile(deviceId: deviceId)
        case .waiting:
            continueUpload()
        case .upload(let path):
            uploadDBFile(path: path)
        case .sendData:
            encryptAndSendKeys()
        }
    }
    
    func linkAccept() {
        APIManager.linkAccept(randomId: linkData.randomId, token: myAccount.jwt) { (responseData) in
            if case .Missing = responseData {
                self.showErrorAlert(message: "Device was already rejected")
                return
            }
            if case .BadRequest = responseData {
                self.showErrorAlert(message: "Device already authorized")
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let deviceId = data["deviceId"] as? Int32 else {
                    self.presentProcessInterrupted()
                    return
            }
            self.connectUIView.progressChange(value: self.PROGRESS_PREPARING_MAILBOX, message: "Preparing Mailbox", completion: {})
            self.linkData.deviceId = deviceId
            self.state = .creatingDB(deviceId)
            self.handleState()
            self.scheduleWorker.start()
        }
        connectUIView.goBack = {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func createDBFile(deviceId: Int32){
        CreateCustomJSONFileAsyncTask().start { (error, url) in
            guard let myUrl = url else {
                self.presentProcessInterrupted()
                return
            }
            guard let compressedPath = try? AESCipher.compressFile(path: myUrl.path, outputName: StaticFile.gzippedDB.name, compress: true),
                let outputPath = AESCipher.streamEncrypt(path: compressedPath, outputName: StaticFile.encryptedDB.name, keyData: self.keyData, ivData: self.ivData, operation: kCCEncrypt) else {
                self.presentProcessInterrupted()
                return
            }
            CriptextFileManager.deleteFile(url: myUrl)
            CriptextFileManager.deleteFile(path: compressedPath)
            self.databasePath = outputPath
            self.state = .waiting
            self.handleState()
        }
    }
    
    func continueUpload(){
        guard let path = self.databasePath,
            keyBundleReady else {
                return
        }
        state = .upload(path)
        handleState()
    }
    
    func uploadDBFile(path: String){
        guard let inputStream = InputStream.init(fileAtPath: path),
            let fileAttributes = try? FileManager.default.attributesOfItem(atPath: path) else {
                self.presentProcessInterrupted()
                return
        }
        let fileSize = Int(truncating: fileAttributes[.size] as! NSNumber)
        APIManager.uploadLinkDBFile(dbFile: inputStream, randomId: linkData.randomId, size: fileSize, token: myAccount.jwt, progressCallback: { (progress) in
            self.connectUIView.progressChange(value: self.PROGRESS_GET_KEYS + (self.PROGRESS_UPLOADING_FILE - self.PROGRESS_GET_KEYS) * progress, message: "Uploading Mailbox", completion: {})
        }) { (responseData) in
            guard case .Success = responseData else {
                self.presentProcessInterrupted()
                return
            }
            CriptextFileManager.deleteFile(path: path)
            self.state = .sendData
            self.handleState()
        }
    }
    
    func encryptAndSendKeys(){
        guard let deviceId = linkData.deviceId else {
            self.presentProcessInterrupted()
            return
        }
        var data: Data?
        tryBlock {
            data = SignalHandler.encryptData(data: self.keyData, deviceId: deviceId, recipientId: self.myAccount.username, account: self.myAccount)
        }
        guard let encryptedData = data else {
            self.presentProcessInterrupted()
            return
        }
        self.sendSuccessData(deviceId: deviceId, encryptedKey: encryptedData.base64EncodedString())
    }
    
    func sendSuccessData(deviceId: Int32, encryptedKey: String){
        let params = [
            "deviceId": deviceId,
            "key": encryptedKey
        ] as [String: Any]
        self.connectUIView.progressChange(value: PROGRESS_SEND_DATA, message: "Uploading Mailbox", completion: {})
        APIManager.linkDataAddress(params: params, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.presentProcessInterrupted()
                return
            }
            self.connectUIView.progressChange(value: self.PROGRESS_COMPLETE, message: "Mailbox Uploaded Successfully", completion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.dismiss(animated: true)
                }
            })
        }
    }
    
    func presentProcessInterrupted(){
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = "Looks like you're having connection issues. Would you like to retry Mailbox Sync"
        retryPopup.initialTitle = "Sync Interrupted"
        retryPopup.leftOption = "Cancel"
        retryPopup.rightOption = "Retry"
        retryPopup.onResponse = { accept in
            guard accept else {
                self.dismiss(animated: true)
                return
            }
            self.handleState()
        }
        self.presentPopover(popover: retryPopup, height: 235)
    }
    
    func showErrorAlert(message: String){
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.dismiss(animated: true)
        })
        self.showAlert("Error Linking Device", message: message, style: .alert, actions: [okAction])
    }
}

extension ConnectUploadViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        guard let deviceId = linkData.deviceId else {
            completion(false)
            return
        }
        if databasePath != nil {
            self.connectUIView.progressChange(value: PROGRESS_GET_KEYS, message: "Getting Keys", cancel: true, completion: {})
        }
        APIManager.getKeybundle(deviceId: deviceId, token: myAccount.jwt) { (responseData) in
            guard case let .SuccessDictionary(keys) = responseData else {
                completion(false)
                return
            }
            let ex = tryBlock {
                SignalHandler.buildSession(recipientId: self.myAccount.username, deviceId: deviceId, keys: keys, account: self.myAccount)
            }
            guard ex == nil else {
                completion(false)
                return
            }
            completion(true)
            self.keyBundleReady = true
            self.continueUpload()
        }
    }
    
    func dangled(){
        guard self.presentedViewController == nil else {
            self.scheduleWorker.start()
            return
        }
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = String.localize("Something has happened that is delaying this process. Do you want to continue waiting?")
        retryPopup.initialTitle = String.localize("Well, that’s odd…")
        retryPopup.onResponse = { accept in
            guard accept else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.scheduleWorker.start()
        }
        self.presentPopover(popover: retryPopup, height: 205)
    }
}

extension ConnectUploadViewController: WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket) {
        guard case let .KeyBundle(deviceId) = result,
            !self.scheduleWorker.isRunning else {
            return
        }
        linkData.deviceId = deviceId
        scheduleWorker.cancel()
        work { (success) in
            guard success else {
                self.scheduleWorker.start()
                return
            }
            self.continueUpload()
        }
    }
}
