//
//  TaskViewController.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 22/07/2020.
//

import UIKit
import RxSwift

class TaskViewController: UIViewController {
    
    private lazy var listManager: FeedListManager = {
        return FeedListManager(repository: self.repository,
                                    navigator: self.navigator,
                                    tableView: self.tableView,
                                    delegate: self,
                                    pullToRefresh: true)
    }()
    
    private lazy var emptyView: TaskEmptyView = {
        let view = TaskEmptyView(buttonCallback: { [weak self] in
            guard let self = self else { return }
            self.navigator.switchToFeedTab(presenter: self)
        })
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tableFooterView = UIView()
        
        // Needed to get rid of the top inset when using grouped style
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: CGFloat.leastNormalMagnitude))
        tableView.contentInsetAdjustmentBehavior = .never
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        
        tableView.contentInset = UIEdgeInsets(top: 16.0, left: 0.0, bottom: 0.0, right: 0.0)
        
        return tableView
    }()
    
    private let navigator: AppNavigator
    private let repository: Repository
    
    init() {
        self.navigator = Services.shared.navigator
        self.repository = Services.shared.repository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = ColorPalette.color(withType: .secondary)
        
        // Header View
        let headerView = SingleTextHeaderView()
        headerView.setTitleText(StringsProvider.string(forKey: .tabTaskTitle))
        
        self.view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        self.view.addSubview(self.tableView)
        self.tableView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        self.tableView.autoPinEdge(.top, to: .bottom, of: headerView)
        
        self.view.addSubview(self.emptyView)
        self.emptyView.autoPinEdge(to: self.tableView)
        self.emptyView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.apply(style: NavigationBarStyleCategory.primary(hidden: true).style)
        
        self.listManager.viewWillAppear()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.listManager.viewDidLayoutSubviews()
    }
}

extension TaskViewController: FeedListManagerDelegate {
    
    var presenter: UIViewController { self }
    
    func handleEmptyList(show: Bool) {
        self.emptyView.isHidden = !show
    }
    
    func getDataProviderSingle(repository: Repository) -> Single<FeedContent> {
        var feeds: [FeedItem] = []
        var date = Date()
        var testFeed = Feed.createTestTaskFeed(title: "Reaction Time Task",
                                               description: "Description",
                                               creationDate: date,
                                               taskType: .reactionTime,
                                               startColor: UIColor(hexRGB: 0x918EF2),
                                               endColor: UIColor(hexRGB: 0x918EF2))
        feeds.append(testFeed)
        date = Date(timeIntervalSinceNow: -60.0 * 60.0 * 12.0)
        testFeed = Feed.createTestTaskFeed(title: "Trail Making Task",
                                           description: "Description",
                                           creationDate: date,
                                           taskType: .trailMaking,
                                           startColor: ColorPalette.color(withType: .primary),
                                           endColor: ColorPalette.color(withType: .gradientPrimaryEnd))
        feeds.append(testFeed)
        date = Date(timeIntervalSinceNow: -60.0 * 60.0 * 24.0)
        testFeed = Feed.createTestTaskFeed(title: "Walk Test",
                                           description: "Complete your 3-Minute Walk Test",
                                           creationDate: date,
                                           taskType: .walk,
                                           startColor: UIColor(hexRGB: 0xFF94C5),
                                           endColor: UIColor(hexRGB: 0xE167AC))
        feeds.append(testFeed)
        date = Date(timeIntervalSinceNow: -60.0 * 60.0 * 36.0)
        testFeed = Feed.createTestTaskFeed(title: "Gait Activity",
                                           description: "Measure your gait and balance as you walk and stand still",
                                           creationDate: date,
                                           taskType: .gait,
                                           startColor: UIColor(hexRGB: 0xFA8886),
                                           endColor: UIColor(hexRGB: 0xF57286))
        feeds.append(testFeed)
        date = Date(timeIntervalSinceNow: -60.0 * 60.0 * 48.0)
        testFeed = Feed.createTestTaskFeed(title: "Tremor Task",
                                           description: "Description",
                                           creationDate: date,
                                           taskType: .tremor,
                                           startColor: UIColor(hexRGB: 0x918EF2),
                                           endColor: UIColor(hexRGB: 0x918EF2))
        feeds.append(testFeed)
        let feedContent = FeedContent(feedItems: feeds)
        return Single.just(feedContent).delaySubscription(.seconds(1), scheduler: MainScheduler.instance)
    }
}

extension Feed {
    static func createTestTaskFeed(title: String,
                                   description: String,
                                   creationDate: Date,
                                   taskType: TaskType,
                                   startColor: UIColor,
                                   endColor: UIColor) -> Feed {
        return Feed(title: title,
                    body: description,
                    image: ImagePalette.image(withName: .fyamLogoSpecific),
                    creationDate: creationDate,
                    buttonText: "START NOW",
                    infoBody: nil,
                    externalLinkUrl: nil,
                    taskId: "test_id",
                    taskType: taskType,
                    startColor: startColor,
                    endColor: endColor)
    }
}
