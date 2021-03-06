//
//  UIStackView+Internal.swift
//  ForYouAndMe
//
//  Created by Giuseppe Lapenta on 02/10/2020.
//

extension UIStackView {
    
    func addHTMLTextView(withText text: String,
                         fontStyle: FontStyle,
                         colorType: ColorType,
                         textAlignment: NSTextAlignment = .center,
                         horizontalInset: CGFloat = 0) {
        
        let fontStyleData = FontPalette.fontStyleData(forStyle: fontStyle)
        let modifiedFont = String(format: """
                                    <span style=\"font-family: \(fontStyleData.font.fontName);\
                                    table, th, td {\
                                    border: 1px solid black;\
                                    };\
                                    font-size: \(fontStyleData.font.pointSize)\">%@</span>
                                    """, text) as String

        guard let htmlString = modifiedFont.htmlToAttributedString else {
            self.addLabel(withText: text, fontStyle: fontStyle, colorType: colorType)
            fatalError("error parsing HTML text")
        }

        let attributedString = NSMutableAttributedString(attributedString: htmlString)
        
        self.addHTMLTextView(attributedString: attributedString,
                             horizontalInset: horizontalInset)
    }
    
    func addHTMLTextView(attributedString: NSAttributedString, horizontalInset: CGFloat = 0) {
        let label = self.getHTMLTextView(attributedString: attributedString)
        self.addArrangedSubview(label, horizontalInset: horizontalInset)
    }
    
    private func getHTMLTextView(attributedString: NSAttributedString) -> UITextView {
        let label = UITextView()
        label.attributedText = attributedString
        label.isEditable = false
        label.isUserInteractionEnabled = true
        label.isScrollEnabled = false
        label.dataDetectorTypes = [.all]
        label.backgroundColor = .clear
        return label
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
