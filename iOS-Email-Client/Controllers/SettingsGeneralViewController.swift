//
//  SettingsGeneralViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import SafariServices
import PasscodeLock

class SettingsGeneralViewController: UITableViewController{
    
    internal enum Section {
        case account
        case about
        case version
        
        var name: String {
            switch(self){
            case .account:
                return String.localize("ACCOUNT")
            case .about:
                return String.localize("ABOUT")
            case .version:
                return String.localize("VERSION")
            }
        }
        
        enum SubSection {
            case profile
            case signature
            case changePassword
            case twoFactor
            case recovery
            case syncContact
            case deleteAccount
            
            case privacy
            case terms
            case openSource
            case logout
            
            case privacySecurity
            
            case version
            
            var name: String {
                switch(self){
                case .syncContact:
                    return String.localize("Sync Phonebook Contacts")
                case .profile:
                    return String.localize("Profile")
                case .signature:
                    return String.localize("Signature")
                case .changePassword:
                    return String.localize("Change Password")
                case .deleteAccount:
                    return String.localize("DELETE_ACCOUNT")
                case .twoFactor:
                    return String.localize("Two-Factor Authentication")
                case .recovery:
                    return String.localize("Recovery Email")
                case .privacy:
                    return String.localize("Privacy Policy")
                case .terms:
                    return String.localize("Terms of Service")
                case .openSource:
                    return String.localize("Open Source Libraries")
                case .logout:
                    return String.localize("Sign out")
                case .privacySecurity:
                    return String.localize("Privacy and Security")
                case .version:
                    return String.localize("Version")
                }
            }
        }
    }
    
    let SECTION_VERSION = 3
    let ROW_HEIGHT: CGFloat = 40.0
    let sections = [.account, .about, .version] as [Section]
    let menus = [
        .account: [.profile, .signature, .changePassword, .recovery, .twoFactor, .privacySecurity, .syncContact],
        .about: [.privacy, .terms, .openSource, .logout, .deleteAccount],
        .version : [.version]] as [Section: [Section.SubSection]
    ]
    var generalData: GeneralSettingsData!
    var myAccount : Account!
    
    override func viewDidLoad() {
        let attributedTitle = NSAttributedString(string: String.localize("GENERAL"), attributes: [.font: Font.semibold.size(16.0)!])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        tabItem.setTabItemColor(.black, for: .normal)
        tabItem.setTabItemColor(.mainUI, for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menus[sections[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let subsection = menus[sections[indexPath.section]]![indexPath.row]
        switch(sections[indexPath.section]){
        case .account:
            return renderAccountCells(subsection: subsection)
        case .about:
            return renderAboutCells(subsection: subsection)
        default:
            return renderVersionCells()
        }
    }
    
    func renderAccountCells(subsection: Section.SubSection) -> UITableViewCell {
        switch(subsection){
        case .recovery:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.text = subsection.name
            cell.messageLabel.text = generalData.recoveryEmailStatus.description
            cell.messageLabel.textColor = generalData.recoveryEmailStatus.color
            guard generalData.recoveryEmail != nil else {
                cell.loader.startAnimating()
                cell.loader.isHidden = false
                cell.goImageView.isHidden = true
                return cell
            }
            cell.loader.stopAnimating()
            cell.loader.isHidden = true
            cell.goImageView.isHidden = false
            return cell
        case .twoFactor:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralSwitch") as! GeneralSwitchTableViewCell
            cell.optionLabel.text = subsection.name
            cell.availableSwitch.isOn = generalData.isTwoFactor
            cell.switchToggle = { isOn in
                self.setTwoFactor(enable: isOn)
            }
            return cell
        case .syncContact:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.text = subsection.name
            cell.messageLabel.text = ""
            switch(generalData.syncStatus){
            case .fail, .success:
                cell.loader.isHidden = true
                cell.loader.stopAnimating()
                cell.goImageView.isHidden = false
                cell.goImageView.image = generalData.syncStatus.image
            case .none:
                cell.optionLabel.text = subsection.name
                cell.goImageView.isHidden = true
                cell.loader.stopAnimating()
                cell.loader.isHidden = true
            case .syncing:
                cell.goImageView.isHidden = true
                cell.loader.isHidden = false
                cell.loader.startAnimating()
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
            cell.optionLabel.text = subsection.name
            cell.goImageView.isHidden = false
            cell.messageLabel.text = ""
            cell.loader.stopAnimating()
            cell.loader.isHidden = true
            return cell
        }
    }
    
    func renderAboutCells(subsection: Section.SubSection) -> GeneralTapTableCellView {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralTap") as! GeneralTapTableCellView
        cell.messageLabel.text = ""
        cell.loader.isHidden = true
        cell.goImageView.isHidden = subsection == .deleteAccount || subsection == .logout
        cell.optionLabel.text = subsection.name
        return cell
    }
    
    func renderVersionCells() -> GeneralVersionTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralVersion") as! GeneralVersionTableViewCell
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        cell.versionLabel.text = "v.\(appVersionString)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != SECTION_VERSION else {
            return nil
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsGeneralHeader") as! GeneralHeaderTableViewCell
        cell.titleLabel.text = sections[section].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section != SECTION_VERSION ? ROW_HEIGHT : 0.0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let subsection = menus[sections[indexPath.section]]![indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch(subsection){
        case .profile:
            presentNamePopover()
        case .changePassword:
            goToChangePassword()
        case .signature:
            goToSignature()
        case .privacy:
            goToUrl(url: "https://criptext.com/privacy")
        case .terms:
            goToUrl(url: "https://criptext.com/terms")
        case .openSource:
            goToUrl(url: "https://criptext.com/open-source-ios")
        case .logout:
            guard let customTabsVC = self.tabsController as? CustomTabsController,
                customTabsVC.devicesData.devices.count <= 1 && generalData.isTwoFactor else {
                showLogout()
                return
            }
            showWarningLogout()
        case .deleteAccount:
            showDeleteAccount()
        case .recovery:
            goToRecoveryEmail()
        case .privacySecurity:
            goToPrivacyAndSecurity()
        case .syncContact:
            guard generalData.syncStatus != .syncing else {
                break
            }
            syncContacts(indexPath: indexPath)
        default:
            break
        }
        
    }
    
    func syncContacts(indexPath: IndexPath){
        generalData.syncStatus = .syncing
        tableView.reloadData()
        let syncContactsTask = RetrieveContactsTask()
        syncContactsTask.start { [weak self] (success) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.generalData.syncStatus = success ? .success : .fail
            weakSelf.tableView.reloadData()
        }
    }
    
    func showLogout(){
        let logoutPopover = GenericDualAnswerUIPopover()
        logoutPopover.initialTitle = String.localize("SIGNOUT")
        logoutPopover.initialMessage = String.localize("Q_SURE_LOGOUT")
        logoutPopover.leftOption = String.localize("CANCEL")
        logoutPopover.rightOption = String.localize("YES")
        logoutPopover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 175)
    }
    
    func showDeleteAccount(){
        let passwordPopover = PasswordUIPopover()
        passwordPopover.answerShouldDismiss = false
        passwordPopover.initialTitle = String.localize("DELETE_ACCOUNT")
        let attrRegularText = NSMutableAttributedString(string: String.localize("DELETING_ACCOUNT"), attributes: [NSAttributedString.Key.font: Font.regular.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        let attrBoldText = NSMutableAttributedString(string: String.localize("DELETE_WILL_ERASE"), attributes: [NSAttributedString.Key.font: Font.bold.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        let attrRegularText2 = NSMutableAttributedString(string: String.localize("DELETE_NO_LONGER"), attributes: [NSAttributedString.Key.font: Font.regular.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        attrRegularText.append(attrBoldText)
        attrRegularText.append(attrRegularText2)
        passwordPopover.initialAttrMessage = attrRegularText
        passwordPopover.onOkPress = { [weak self] pass in
            guard let weakSelf = self else {
                return
            }
            weakSelf.deleteAccount(password: pass)
        }
        self.presentPopover(popover: passwordPopover, height: 260)
    }
    
    func deleteAccount(password: String){
        APIManager.deleteAccount(password: password.sha256()!, token: self.myAccount.jwt, completion: { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            if case .BadRequest = responseData {
                if let popover = weakSelf.presentedViewController as? PasswordUIPopover {
                    popover.dismiss(animated: false, completion: nil)
                }
                weakSelf.showAlert("Delete Account Failed", message: "Wrong Password. Please try again", style: .alert)
                return
            }
            guard case .Success = responseData,
                let delegate = UIApplication.shared.delegate as? AppDelegate else {
                    if let popover = weakSelf.presentedViewController as? PasswordUIPopover {
                        popover.dismiss(animated: false, completion: nil)
                    }
                    weakSelf.showAlert("Delete Account Failed", message: "Something went wrong while deleting your account. Please try again", style: .alert)
                return
            }
            delegate.logout(manually: false, message: String.localize("DELETE_ACCOUNT_SUCCESS"))
        })
    }
    
    func showWarningLogout() {
        let logoutPopover = GenericDualAnswerUIPopover()
        logoutPopover.initialTitle = String.localize("WARNING")
        logoutPopover.initialMessage = String.localize("Q_SIGNOUT_2FA")
        logoutPopover.leftOption = String.localize("CANCEL")
        logoutPopover.rightOption = String.localize("YES")
        logoutPopover.onResponse = { accept in
            guard accept else {
                return
            }
            self.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 223)
    }
    
    func confirmLogout(){
        APIManager.logout(token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("Sign out error"), message: String.localize("Unable to sign out. Please try again"), style: .alert)
                return
            }
            self.logout(manually: true)
        }
    }
    
    func goToRecoveryEmail(){
        guard generalData.recoveryEmail != nil else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let recoveryVC = storyboard.instantiateViewController(withIdentifier: "recoveryEmailViewController") as! RecoveryEmailViewController
        recoveryVC.generalData = self.generalData
        recoveryVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(recoveryVC, animated: true)
    }
    
    func goToChangePassword(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let changePassVC = storyboard.instantiateViewController(withIdentifier: "changePassViewController") as! ChangePassViewController
        changePassVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(changePassVC, animated: true)
    }
    
    func goToPrivacyAndSecurity(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let securityVC = storyboard.instantiateViewController(withIdentifier: "securityPrivacyViewController") as! SecurityPrivacyViewController
        securityVC.generalData = self.generalData
        securityVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(securityVC, animated: true)
    }
    
    func goToSignature(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signatureVC = storyboard.instantiateViewController(withIdentifier: "signatureEditorViewController") as! SignatureEditorViewController
        signatureVC.myAccount = myAccount
        self.navigationController?.pushViewController(signatureVC, animated: true)
    }
    
    func presentNamePopover(){
        let changeNamePopover = SingleTextInputViewController()
        changeNamePopover.myTitle = String.localize("Change Name")
        changeNamePopover.initInputText = self.myAccount.name
        changeNamePopover.onOk = { text in
            self.changeProfileName(name: text)
        }
        self.presentPopover(popover: changeNamePopover, height: Constants.singleTextPopoverHeight)
    }
    
    func goToUrl(url: String){
        let svc = SFSafariViewController(url: URL(string: url)!)
        self.present(svc, animated: true, completion: nil)
    }
    
    func changeProfileName(name: String){
        let params = EventData.Peer.NameChanged(name: name)
        APIManager.updateName(name: name, token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("Something went wrong"), message: String.localize("Unable to update Profile Name. Please try again"), style: .alert)
                return
            }
            DBManager.update(account: self.myAccount, name: name)
            DBManager.createQueueItem(params: ["cmd": Event.Peer.changeName.rawValue, "params": params.asDictionary()])
        }
    }
    
    func setTwoFactor(enable: Bool){
        guard !enable || generalData.recoveryEmailStatus == .verified else {
            presentRecoveryPopover()
            self.reloadView()
            return
        }
        let initialValue = self.generalData.isTwoFactor
        self.generalData.isTwoFactor = enable
        APIManager.setTwoFactor(isOn: enable, token: myAccount.jwt) { (responseData) in
            if case .Conflicts = responseData {
                self.presentRecoveryPopover()
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("Something went wrong"), message: "\(String.localize("Unable to")) \(enable ? String.localize("enable") : String.localize("disable")) \(String.localize("two pass. Please try again"))", style: .alert)
                self.generalData.isTwoFactor = initialValue
                self.reloadView()
                return
            }
            if (self.generalData.isTwoFactor) {
                self.presentTwoFactorPopover()
            }
        }
    }
    
    func presentRecoveryPopover() {
        let popover = GenericAlertUIPopover()
        let attributedRegular = NSMutableAttributedString(string: String.localize("To enable Two-Factor Authentication you must set and verify a recovery email on your account"), attributes: [NSAttributedStringKey.font: Font.regular.size(15)!])
        let attributedSemibold = NSAttributedString(string: String.localize("\n\nPlease go to Settings > Recovery Email to complete this step."), attributes: [NSAttributedStringKey.font: Font.semibold.size(15)!])
        attributedRegular.append(attributedSemibold)
        popover.myTitle = String.localize("Recovery Email Not Set")
        popover.myAttributedMessage = attributedRegular
        popover.myButton = String.localize("Got it!")
        self.presentPopover(popover: popover, height: 310)
    }
    
    func presentTwoFactorPopover() {
        let popover = GenericAlertUIPopover()
        popover.myTitle = String.localize("2FA Enabled!")
        popover.myMessage = String.localize("Next time you sign into your account on another device you'll have to enter your password and then validate the sign in from an existing device.")
        popover.myButton = String.localize("Got it!")
        self.presentPopover(popover: popover, height: 263)
    }
}

extension SettingsGeneralViewController: CustomTabsChildController {
    func reloadView() {
        tableView.reloadData()
    }
}
