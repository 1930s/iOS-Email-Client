//
//  EmailDetailFooterCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol EmailDetailFooterDelegate: class {
    func onFooterReplyPress()
    func onFooterReplyAllPress()
    func onFooterForwardPress()
}

class EmailDetailFooterCell: UITableViewHeaderFooterView{
    
    weak var delegate : EmailDetailFooterDelegate?
    
    @IBAction func onPressReply(_ sender: Any) {
        delegate?.onFooterReplyPress()
    }
    
    @IBAction func onPressReplyAll(_ sender: Any) {
        delegate?.onFooterReplyAllPress()
    }
    
    @IBAction func onPressForward(_ sender: Any) {
        delegate?.onFooterForwardPress()
    }
}
