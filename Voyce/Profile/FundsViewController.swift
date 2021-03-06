//
//  TransferFunds.swift
//  Voyce
//
//  Created by Aron Vischjager on 3/29/20.
//  Copyright © 2020 QEDev. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class FundsViewController: UIViewController, UITextFieldDelegate
{
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var accountNumber: UITextField!
    @IBOutlet weak var routingNumber: UITextField!
    @IBOutlet weak var infoSection: UIStackView!
    @IBOutlet weak var messageTextField: UITextView!
    
    // Please don't remove the functions variable
    lazy var functions = Functions.functions()
    
    // Pops view controller off the view controller stack
    func removeViewController()
    {
         navigationController?.popViewController(animated: true)
    }
    
    // Checks if all field have content
    // returns false if any field is empty
    func getInfo() -> DwollaUser?
    {
        guard let firstName = firstName.text else
        {
            return nil
        }
        guard let lastName = lastName.text else
        {
            return nil
        }
        guard let email = email.text else
        {
            return nil
        }
        guard let accountNumber = accountNumber.text else
        {
            return nil
        }
        guard let routingNumber = routingNumber.text else
        {
            return nil
        }
        if firstName.isEmpty || lastName.isEmpty || email.isEmpty || accountNumber.isEmpty || routingNumber.isEmpty
        {
            messageTextField.text = "Please enter valid information in all text fields."
            self.messageTextField.setNeedsDisplay()
            return nil
        }
        return DwollaUser(firstName, lastName, email, accountNumber, routingNumber)
    }
    
    // Sends user info to Dwolla and transfers funds
    // Assumes $ currency and a minimum transfer value of $0.5
    // Does not consider Dwolla transfer fees
    func sendData(user: DwollaUser)
    {
        var dataString = ""
        let vibeConverter = VibeConverter()
        let dollarValue = vibeConverter.getMoney()
        // Initializes the transfer if the value is $0.50 or more
        if dollarValue >= 0.5
        {
            if userHasFundingSource()
            {
                let fundingSource = getFundingSource()
                dataString = "\(fundingSource), \(dollarValue)"
            }
            else
            {
                dataString = "\(user.firstName), \(user.lastName), \(user.email), \(user.accountNumber), \(user.routingNumber), \(dollarValue)"
            }
            functions.httpsCallable("initTransfer").call(["text": dataString])
            {(result, error) in
                // Handles any errors in the communication
                if let error = error as NSError?
                {
                    if error.domain == FunctionsErrorDomain
                    {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                        self.messageTextField.text = message
                        self.messageTextField.setNeedsDisplay()
                    }
                }
                // Handles the responses from the server
                if let text = (result?.data as? [String: Any])?["text"] as? String
                {
                    self.messageTextField.text = text
                    self.messageTextField.setNeedsDisplay()
                    self.updateFundingSource()
                    let seconds = 4.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                         self.removeViewController()
                    }
                }
            }
        }
        else
        {
            self.messageTextField.text = "Earned vibes have insufficient dollar value to initialize transfer."
            self.messageTextField.setNeedsDisplay()
        }
    }
    
    // Returns true if the user already has a funding source
    func userHasFundingSource() -> Bool
    {
        return DatabaseManager.shared.sharedUser.hasFundingSource()
    }
    
    // Returns the funding source string from the user
    func getFundingSource() -> String
    {
        return DatabaseManager.shared.sharedUser.fundingSource
    }
    
    // Updates the funding source in the user class
    func updateFundingSource()
    {
        DatabaseManager.shared.sharedUser.updateFundingSource()
    }
    
    // Call the methods to transfer funds to bank account
    @IBAction func transferFunds(_ sender: UIButton)
    {
        if !userHasFundingSource()
        {
            guard let dwollaUser = getInfo() else
            {
                return
            }
            sendData(user: dwollaUser)
        }
        // No info needed from user since we have funding source
        else
        {
            sendData(user: DwollaUser("","","","",""))
        }
    }
    
    override func viewDidLoad() {
        firstName.becomeFirstResponder()
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        switch textField{
        case firstName:
            firstName.resignFirstResponder()
            lastName.becomeFirstResponder()
        case lastName:
            lastName.resignFirstResponder()
            email.becomeFirstResponder()
        case email:
            email.resignFirstResponder()
            accountNumber.becomeFirstResponder()
        case accountNumber:
            accountNumber.resignFirstResponder()
            routingNumber.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return false
    }
    
    @IBAction func removeKeyboard(_ sender: UIButton)
    {
        if firstName.isFirstResponder
        {
            firstName.resignFirstResponder()
        }
        else if lastName.isFirstResponder
        {
            lastName.resignFirstResponder()
        }
        else if email.isFirstResponder
        {
            email.resignFirstResponder()
        }
        else if accountNumber.isFirstResponder
        {
            accountNumber.resignFirstResponder()
        }
        else
        {
            routingNumber.resignFirstResponder()
        }
    }
    
    
    // Reloads any methods when the view appears
    override func viewWillAppear(_ animated: Bool)
    {
        DatabaseManager.shared.setVibeConversionRate()
        DatabaseManager.shared.sharedUser.updateEarnedVibes()
        if userHasFundingSource()
        {
            infoSection.removeFromSuperview()
        }
        messageTextField.isEditable = false
    }
}
