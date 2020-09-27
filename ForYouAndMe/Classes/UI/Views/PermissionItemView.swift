//
//  PermissionItemView.swift
//  ForYouAndMe
//
//  Created by Giuseppe Lapenta on 14/09/2020.
//

typealias PermissionItemViewCallback = () -> Void

class PermissionItemView: UIView {

    private var gestureCallback: PermissionItemViewCallback?
    
    init(withTitle title: String,
         permission: Permission,
         iconName: ImageName,
         gestureCallback: @escaping PermissionItemViewCallback) {
        
        super.init(frame: .zero)
        
        self.gestureCallback = gestureCallback
        self.backgroundColor = ColorPalette.color(withType: .primary)
        self.layer.cornerRadius = 8
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        self.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 20.0))
        
        stackView.addImage(withImage: ImagePalette.image(withName: iconName) ?? UIImage(),
                           color: ColorPalette.color(withType: .secondary),
                           sizeDimension: 32)
        
        stackView.addLineSeparator(lineColor: ColorPalette.color(withType: .secondary),
                                   inset: 0,
                                   isVertical: true)
        
        //Title
        var attributedString = NSAttributedString.create(withText: title,
                                                         fontStyle: .paragraph,
                                                         colorType: .secondaryText,
                                                         textAlignment: .left,
                                                         underlined: false)
        let label = UILabel()
        label.attributedText = attributedString
        label.numberOfLines = 0
        label.setContentHuggingPriority(UILayoutPriority(100), for: .horizontal)
        stackView.addArrangedSubview(label, horizontalInset: 0, verticalInset: 14)
        
        //Allow
        attributedString = NSAttributedString.create(withText: (permission.isAuthorized) ? "Allowed" : "Allow",
                                                     fontStyle: .paragraph,
                                                     colorType: (permission.isAuthorized) ? .gradientPrimaryEnd : .secondaryText,
                                                     textAlignment: .left,
                                                     underlined: true)
        let allowLabel = UILabel()
        allowLabel.attributedText = attributedString
        allowLabel.numberOfLines = 1
        allowLabel.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        stackView.addArrangedSubview(allowLabel, horizontalInset: 8)
        
        if permission.isAuthorized == false {
            let tap = UITapGestureRecognizer(target: self, action: #selector(viewDidPressed))
            self.addGestureRecognizer(tap)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func viewDidPressed() {
        UIView.animate(withDuration: 0.1, delay: 0.0,
                       options: [.curveLinear],
                       animations: {
                        self.backgroundColor = .white
                        self.backgroundColor = ColorPalette.color(withType: .primary)
        }, completion: nil)
        self.gestureCallback?()
    }
}
