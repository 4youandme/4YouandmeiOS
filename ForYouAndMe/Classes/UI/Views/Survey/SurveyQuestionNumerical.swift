//
//  SurveyQuestionNumerical.swift
//  ForYouAndMe
//
//  Created by Giuseppe Lapenta on 27/09/2020.
//

class SurveyQuestionNumerical: UIView, SurveyQuestionProtocol, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var surveyQuestion: SurveyQuestion
    
    private let numberOfItems: Int
    private let minumum: Int
    private let maximum: Int
    private var items: [String] = [String]()
    
    init(surveyQuestion: SurveyQuestion) {
        self.surveyQuestion = surveyQuestion
        
        guard let minimum = self.surveyQuestion.minimum, let maximum = self.surveyQuestion.maximum else {
            fatalError("Minimum and Maximum are required in numerical question")
        }
        self.minumum = Int(minimum)
        self.maximum = Int(maximum)
        self.numberOfItems = self.maximum - self.minumum
        super.init(frame: .zero)
        
        self.calculateRange()

        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.backgroundColor = .clear
//        pickerView.tintColor = ColorPalette.color(withType: .primary)
//        pickerView.subviews[1].backgroundColor = ColorPalette.color(withType: .primary)
        
        self.addSubview(pickerView)
        pickerView.autoPinEdgesToSuperviewEdges()
        pickerView.selectRow(Int(self.numberOfItems/2), inComponent: 0, animated: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func calculateRange() {
        for idx in 0...self.numberOfItems {
            self.items.append("\(self.minumum + idx)")
        }
        guard let minimum = self.surveyQuestion.minimumDisplay,
              !(self.surveyQuestion.minimumDisplay ?? "").isEmpty else {
            return
        }
        self.items.insert(minimum, at: 0)
        
        guard let maximum = self.surveyQuestion.maximumDisplay,
              !(self.surveyQuestion.maximumDisplay ?? "").isEmpty else {
            return
        }
        self.items.insert(maximum, at: self.items.count)
    }
    
    // MARK: Picker Datasource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.items.count
    }
    
    // MARK: Picker Delegate
    
//    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
//
//        let color = pickerView.selectedRow(inComponent: component) == row ?
//            ColorPalette.color(withType: .secondaryText) :
//            ColorPalette.color(withType: .primaryText)
//
//        let attributeString = NSAttributedString.create(withText: self.items[row],
//                                                        fontStyle: .header2,
//                                                        color: color)
//
//        return attributeString
//
//    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.items[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 51.0
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let view = pickerView.view(forRow: row, forComponent: component) as? OverlayView
        let attributeString = NSAttributedString.create(withText: self.items[row],
                                                        fontStyle: .header2,
                                                        color: ColorPalette.color(withType: .secondaryText))
        view?.label.attributedText = attributeString
        view?.label.layer.backgroundColor = ColorPalette.color(withType: .primary).cgColor
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        pickerView.subviews[1].isHidden = true
        
        let attributeString = NSAttributedString.create(withText: self.items[row],
                                                        fontStyle: .header2,
                                                        color: ColorPalette.color(withType: .primaryText))
        
        let currentView = (view as? OverlayView) ?? OverlayView(withTitle: attributeString)
        currentView.label.layer.backgroundColor = UIColor.clear.cgColor
        currentView.label.attributedText = attributeString
        return currentView
    }
}

class OverlayView: UIView {
    
    var label: UILabel = UILabel()

    init(withTitle attributedString: NSAttributedString) {
        super.init(frame: .zero)
        self.label.attributedText = attributedString
        self.addSubview(self.label)
        self.label.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        self.label.autoCenterInSuperview()
        self.label.layer.cornerRadius = 24
        self.label.layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}