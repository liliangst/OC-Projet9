//
//  ConversionViewController.swift
//  LeBaluchon
//
//  Created by Lilian Grasset on 25/05/2023.
//

import UIKit

class ConversionViewController: UIViewController {
    
    @IBOutlet weak var baseCurrencyAmount: UITextField!
    @IBOutlet weak var targetCurrencyAmount: UITextField!
    @IBOutlet weak var baseCurrencyPicker: UIPickerView!
    @IBOutlet weak var targetCurrencyPicker: UIPickerView!
    @IBOutlet weak var convertButton: UIButton! {
        didSet {
            convertButton.isEnabled = false
            convertButton.isHidden = true
            convertButton.layer.opacity = 0.5
        }
    }
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator.isHidden = false
        }
    }
    
    var currencyConverter: CurrencyConverter?
    
    override func viewDidLoad() {
        setupPickerViews()

        baseCurrencyAmount.delegate = self
    
        fetchData()
    }
    
    private func setupPickerViews() {
        baseCurrencyPicker.setValue(UIColor.app_blue, forKeyPath: "textColor")
        baseCurrencyPicker.selectRow(CurrencySymbols.indexOf("EUR") ?? 0, inComponent: 0, animated: false)
        
        targetCurrencyPicker.setValue(UIColor.app_blue, forKeyPath: "textColor")
        targetCurrencyPicker.selectRow(CurrencySymbols.indexOf("USD") ?? 0, inComponent: 0, animated: false)
    }
    
    private func toggleOffActivityIndicator() {
        activityIndicator.isHidden = true
        convertButton.isHidden = false
    }
}

extension ConversionViewController {
    
    private func fetchData() {
        CurrencyService.shared.getCurrencyConverter { result in
            switch result {
            case .success(let converter):
                self.currencyConverter = converter
                self.toggleOffActivityIndicator()
            case .failure(let error):
                self.displayError(error)
            }
        }
    }
    
    @IBAction func convertCurrency() {
        let base = baseCurrencyPicker.selectedRow(inComponent: 0)
        let target = targetCurrencyPicker.selectedRow(inComponent: 0)
        let amountToConvert = Double(baseCurrencyAmount.text!) ?? 0
        let result = currencyConverter?.convert(from: CurrencySymbols.symbols[base], to: CurrencySymbols.symbols[target], amount: amountToConvert)
        targetCurrencyAmount.text = MoneyFormatter.format(result!)
    }

    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        baseCurrencyAmount.resignFirstResponder()
    }
}

extension ConversionViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        CurrencySymbols.symbols.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        CurrencySymbols.symbols[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Go to the next row when selecting the same input as the other picker view
        if pickerView == baseCurrencyPicker && row == targetCurrencyPicker.selectedRow(inComponent: component) {
            let nextIndex = CurrencySymbols.nextIndex(after: row)
            baseCurrencyPicker.selectRow(nextIndex, inComponent: component, animated: true)
        } else if pickerView == targetCurrencyPicker && row == baseCurrencyPicker.selectedRow(inComponent: component) {
            let nextIndex = CurrencySymbols.nextIndex(after: row)
            targetCurrencyPicker.selectRow(nextIndex, inComponent: component, animated: true)
        }
        baseCurrencyPicker.reloadAllComponents()
        targetCurrencyPicker.reloadAllComponents()
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.app_darkgray]
        let title = NSAttributedString(string: CurrencySymbols.symbols[row], attributes: attributes)

        if pickerView == baseCurrencyPicker && row == targetCurrencyPicker.selectedRow(inComponent: component) {
            return title
        } else if pickerView == targetCurrencyPicker && row == baseCurrencyPicker.selectedRow(inComponent: component) {
            return title
        }

        return NSAttributedString(string: CurrencySymbols.symbols[row])
    }
}

extension ConversionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == baseCurrencyAmount, let textFieldText = textField.text else {
            return true
        }
        let text = (textFieldText as NSString).replacingCharacters(in: range, with: string)
        
        if text.isEmpty {
            convertButton.layer.opacity = 0.5
            convertButton.isEnabled = false
            targetCurrencyAmount.text = ""
        } else {
            convertButton.layer.opacity = 1
            convertButton.isEnabled = true
        }
        
        return true
    }
}

extension ConversionViewController {

    func displayError(_ error: CurrencyServiceError) {
        switch error {
        case .noData:
            displayAlert("Il y a eu une erreur lors de la réception des données.")
        case .wrongStatusCode:
            displayAlert("Il y a eu une erreur côté serveur.")
        case .decodingError:
            displayAlert("Il y a eu une erreur lors du décodage des données.")
        }
    }
    
    private func displayAlert(_ text: String) {
        let alertVC = UIAlertController(title: "Oups!",
                                        message: text, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "Réessayer", style: .default, handler: { _ in
            self.fetchData()
        }))
        return self.present(alertVC, animated: true, completion: nil)
    }
}
