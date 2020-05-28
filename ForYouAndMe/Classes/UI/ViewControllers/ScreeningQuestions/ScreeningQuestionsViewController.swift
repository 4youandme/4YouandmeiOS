//
//  ScreeningQuestionsViewController.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 22/05/2020.
//  Copyright © 2020 Balzo srl. All rights reserved.
//

import Foundation
import PureLayout
import RxSwift

public class ScreeningQuestionsViewController: UIViewController {
    
    private let navigator: AppNavigator
    private let repository: Repository
    
    lazy private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.registerCellsWithClass(QuestionBinaryTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.estimatedRowHeight = 130.0
        return tableView
    }()
    
    private lazy var confirmButtonView: GenericButtonView = {
        let view = GenericButtonView(withImageStyleCategory: .secondaryBackground)
        view.button.addTarget(self, action: #selector(self.confirmButtonPressed), for: .touchUpInside)
        return view
    }()
    
    private var items: [QuestionBinaryDisplayData] = []
    
    private let disposeBag = DisposeBag()
    
    init() {
        self.navigator = Services.shared.navigator
        self.repository = Services.shared.repository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = ColorPalette.color(withType: .secondary)
        
        self.navigator.pushProgressHUD()
        self.repository.getScreeningSection().subscribe(onSuccess: { screeningSection in
            self.navigator.popProgressHUD()
            self.items = screeningSection.questions.compactMap{ $0.questionBinaryData }
            self.tableView.reloadData()
        }, onError: { error in
            self.navigator.popProgressHUD()
            self.navigator.handleError(error: error, presenter: self)
        }).disposed(by: self.disposeBag)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        self.view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewSafeArea()
        
        stackView.addArrangedSubview(self.tableView)
        stackView.addArrangedSubview(self.confirmButtonView)
        
        self.tableView.reloadData()
        self.updateConfirmButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.apply(style: NavigationBarStyles.secondaryStyle)
        self.addCustomBackButton()
        self.addOnboardingAbortButton(withColor: ColorPalette.color(withType: .primary))
    }
    
    // MARK: Actions
    
    @objc private func confirmButtonPressed() {
        if self.validateAnswers() {
            // TODO: Navigate to success view
            print("TODO: Navigate to success view")
        } else {
            // TODO: Navigate to failure view
            print("TODO: Navigate to failure view")
        }
    }
    
    // MARK: Private Methods
    
    private func updateItem(identifier: String, answerA: Bool) {
        guard let itemIndex = self.items.firstIndex(where: { $0.identifier == identifier }) else {
            assertionFailure("Cannot find item with id: '\(identifier)'")
            return
        }
        var item = self.items[itemIndex]
        item.answerAisActive = answerA
        self.items[itemIndex] = item
        self.tableView.reloadData()
        self.updateConfirmButton()
    }
    
    private func updateConfirmButton() {
        let buttonEnabled = self.items.allSatisfy({ $0.answerAisActive != nil })
        self.confirmButtonView.button.isEnabled = buttonEnabled
    }
    
    private func validateAnswers() -> Bool {
        return self.items.allSatisfy { question in
            if let correctAnswerA = question.correctAnswerA {
                return question.answerAisActive == correctAnswerA
            } else {
                return true
            }
        }
    }
}

extension ScreeningQuestionsViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellOfType(type: QuestionBinaryTableViewCell.self, forIndexPath: indexPath) else {
            assertionFailure("Missing expected cell")
            return UITableViewCell()
        }
        guard indexPath.row < self.items.count else {
            assertionFailure("Unexpected row")
            return UITableViewCell()
        }
        let item = self.items[indexPath.row]
        cell.display(data: item,
                     answerPressedCallback: { [weak self] answerA in
                        self?.updateItem(identifier: item.identifier,
                                         answerA: answerA)
        })
        return cell
    }
}

fileprivate extension Question {
    var questionBinaryData: QuestionBinaryDisplayData? {
        guard self.possibleAnswers.count >= 2 else {
            return nil
        }
        let answerA = self.possibleAnswers[0]
        let answerB = self.possibleAnswers[1]
        return QuestionBinaryDisplayData(identifier: self.id,
                                         question: self.text,
                                         answerA: answerA.text,
                                         answerB: answerB.text,
                                         correctAnswerA: answerA.correct,
                                         answerAisActive: nil)
    }
}
