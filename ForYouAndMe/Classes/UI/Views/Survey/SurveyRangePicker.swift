//
//  SurveyRangePicker.swift
//  ForYouAndMe
//
//  Created by Giuseppe Lapenta on 29/09/2020.
//

class SurveyRangePicker: UIView {
    
    var surveyQuestion: SurveyQuestion
    var minimumLabel: UILabel = UILabel()
    var maximumLabel: UILabel = UILabel()
    var currentValue: UILabel = UILabel()
    var slider: Slider = Slider()
    
    init(surveyQuestion: SurveyQuestion) {
        
        guard let minimum = surveyQuestion.minimum, let maximum = surveyQuestion.maximum else {
            fatalError("Minimum and Maximum are required in Range question")
        }
        self.surveyQuestion = surveyQuestion
        self.minimumLabel.text = surveyQuestion.minimumLabel
        self.maximumLabel.text = surveyQuestion.maximumLabel
        
        super.init(frame: .zero)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        self.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea()
        
        stackView.addBlankSpace(space: 50)

        self.currentValue.text = "\(minimum)"
        self.currentValue.font = FontPalette.fontStyleData(forStyle: .title).font
        self.currentValue.textColor = ColorPalette.color(withType: .primaryText)
        self.currentValue.textAlignment = .center
//        let containerLabel = UIView()
//        containerLabel.addSubview(self.currentValue)
        stackView.addArrangedSubview(self.currentValue)
        self.currentValue.setContentHuggingPriority(UILayoutPriority(251), for: .vertical)
//        self.currentValue.setContentCompressionResistancePriority(UILayoutPriority(100), for: .vertical)
//
        stackView.addBlankSpace(space: 40)
        
        self.slider.addTarget(self, action: #selector(changeValue(_:)), for: .valueChanged)
        self.slider.value = Float(minimum)
        self.slider.minimumValue = Float(minimum)
        self.slider.maximumValue = Float(maximum)
        self.slider.setup()
        stackView.addArrangedSubview(self.slider)
//        self.slider.setContentHuggingPriority(UILayoutPriority(101), for: .vertical)
//        self.slider.setContentCompressionResistancePriority(UILayoutPriority(101), for: .vertical)
        
        stackView.addBlankSpace(space: 20)

        let sliderContainer = UIStackView()
        sliderContainer.axis = .horizontal
        stackView.addArrangedSubview(sliderContainer)
        
        sliderContainer.addLabel(text: surveyQuestion.minimumLabel ?? "\(minimum)",
                                 font: FontPalette.fontStyleData(forStyle: .header3).font,
                                 textColor: ColorPalette.color(withType: .primaryText),
                                 textAlignment: .left)
        
        sliderContainer.addLabel(text: surveyQuestion.maximumLabel ?? "\(maximum)",
                                 font: FontPalette.fontStyleData(forStyle: .header3).font,
                                 textColor: ColorPalette.color(withType: .primaryText),
                                 textAlignment: .right)
        sliderContainer.setContentHuggingPriority(UILayoutPriority(252), for: .vertical)
        
        let dummyView = UIView()
        stackView.addArrangedSubview(dummyView)
        dummyView.setContentHuggingPriority(UILayoutPriority(100), for: .vertical)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func changeValue(_ sender: UISlider) {
//        sliderValueChanges?(Int(sender.value))
        self.currentValue.text = "\(Int(sender.value))"
    }
}
