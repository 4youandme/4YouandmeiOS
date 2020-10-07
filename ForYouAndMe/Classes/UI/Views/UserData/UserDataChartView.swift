//
//  UserDataChartView.swift
//  ForYouAndMe
//
//  Created by Leonardo Passeri on 04/09/2020.
//

import UIKit
import PureLayout
import Charts

enum StudyPeriod: Int, CaseIterable {
    case week
    case month
    case year
    
    var title: String {
        switch self {
        case .week: return StringsProvider.string(forKey: .tabUserDataPeriodWeek)
        case .month: return StringsProvider.string(forKey: .tabUserDataPeriodMonth)
        case .year: return StringsProvider.string(forKey: .tabUserDataPeriodYear)
        }
    }
    
    func getPeriodString(fromDateStrings dateStrings: [String]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.dateDecodeFormat
        guard let startDate = self.getStartDate(fromDateStrings: dateStrings),
              let endDate = self.getEndDate(fromDateStrings: dateStrings) else {
            return ""
        }
        return self.getPeriodString(fromStartDate: startDate, endDate: endDate)
    }
    
    func getStartDate(fromDateStrings dateStrings: [String]) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.dateDecodeFormat
        guard let startDateStr = dateStrings.first else {
            return nil
        }
        return dateFormatter.date(from: startDateStr)
    }
    
    func getEndDate(fromDateStrings dateStrings: [String]) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.dateDecodeFormat
        guard let endDateStr = dateStrings.last else {
            return nil
        }
        return dateFormatter.date(from: endDateStr)
    }
    
    var dateDecodeFormat: String {
        switch self {
        case .week: return "dd-MM-yyyy"
        case .month: return "dd-MM-yyyy"
        case .year: return "MM-yyyy"
        }
    }
    
    var periodDisplayFormat: String {
        switch self {
        case .week: return "MMM dd, yyyy"
        case .month: return "MMMM yyyy"
        case .year: return "MMMM yyyy"
        }
    }
    
    func getPeriodString(fromStartDate startDate: Date, endDate: Date) -> String {
        let startDateStr = startDate.string(withFormat: self.periodDisplayFormat)
        let endDateStr = endDate.string(withFormat: self.periodDisplayFormat)
        switch self {
        case .week, .month, .year:
            return "\(startDateStr)" + " - " + "\(endDateStr)"

        }
    }
    
    func getStartAndEndData() -> (startDate: Date, endDate: Date) {
        var startDate = Date()
        
        switch self {
        case .month:
            startDate = startDate.getDate(for: -30)
        case .week:
            startDate = startDate.getDate(for: -7)
        case .year:
            startDate = startDate.getDate(for: -364)
        }
        return (startDate: startDate, endDate: Date().getDate(for: -1))
    }
    
    func getInterval() -> Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .year:
            return 12
        }
    }
    
    func getXAxisRangeValues(startDate: Date) -> [String] {
//        let dates = self.getStartAndEndData()
//        let startDate = dates.startDate
        
        switch self {
        case .week:
            return startDate.getDates(for: 1, interval: self.getInterval(), format: dayShort)
        case .month:
            return startDate.getDates(for: 7, interval: self.getInterval(), format: monthShort)
        case .year:
            return startDate.getDates(for: 30, interval: self.getInterval(), format: yearShortDate)
        }
    }
}

class UserDataChartView: UIView {
    
    private static let chartBackgroundHeight: CGFloat = 280.0
    private var plotColor: UIColor
    private var xLabels: [String]
    private var yLabels: [String]
    private var data: [Double?]
    private var studyPeriod: StudyPeriod
    
    private let chartView: LineChartView = {
        let chartView = LineChartView()
        return chartView
    }()
    
    init(title: String,
         plotColor: UIColor,
         data: [Double?],
         xLabels: [String],
         yLabels: [String],
         studyPeriod: StudyPeriod) {
        
        self.plotColor = plotColor
        self.xLabels = xLabels
        self.yLabels = yLabels
        self.data = data
        self.studyPeriod = studyPeriod
        
        super.init(frame: .zero)
        
        let stackView = UIStackView.create(withAxis: .vertical, spacing: 30.0)
        self.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        
        stackView.addLabel(withText: title, fontStyle: .paragraph, colorType: .primaryText, textAlignment: .left)
        
        let chartBackground = UIView()
        chartBackground.backgroundColor = ColorPalette.color(withType: .secondary)
        chartBackground.round(radius: 4.0)
        chartBackground.autoSetDimension(.height, toSize: Self.chartBackgroundHeight)
        chartBackground.addShadowCell()
        
        chartBackground.addSubview(self.chartView)
        self.chartView.autoPinEdgesToSuperviewEdges()
        
        stackView.addArrangedSubview(chartBackground)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        //General Settings
        self.chartView.chartDescription?.enabled = false
        self.chartView.dragEnabled = false
        self.chartView.setScaleEnabled(false)
        self.chartView.pinchZoomEnabled = false
        self.chartView.rightAxis.enabled = true
        self.chartView.leftAxis.enabled = false
        self.chartView.leftAxis.drawGridLinesEnabled = false
        self.chartView.drawGridBackgroundEnabled = false
        self.chartView.extraBottomOffset = 20
        self.chartView.extraLeftOffset = 25
        self.chartView.extraTopOffset = 20
        self.chartView.clipsToBounds = false
    
        //Legend
        self.chartView.legend.form = .line
        self.chartView.legend.textColor = self.plotColor
        self.chartView.legend.font = FontPalette.fontStyleData(forStyle: .paragraph).font
        self.chartView.legend.xOffset = -10

        //Axis
        self.configureXAxis()
        self.configureYAxis()
        
        //X-Axis Formatter
        if let endDate = self.studyPeriod.getEndDate(fromDateStrings: self.xLabels) {
            let xAxisFormatter = XAxisValueFormatter(studyPeriod: self.studyPeriod, xLabels: self.xLabels)
            self.chartView.xAxis.valueFormatter = xAxisFormatter
        }
        
        //Y-Axis Formatter
        let yAxisFormatter = YAxisValueFormatter(yLabels: self.yLabels)
        self.chartView.rightAxis.valueFormatter = yAxisFormatter
        
        // Y-Axis limit line
        let ll1 = ChartLimitLine(limit: 70, label: "")
        ll1.lineWidth = 2
        ll1.lineDashLengths = [10, 10]
        ll1.lineColor = ColorPalette.color(withType: .inactive)
        
        let rightAxis = chartView.rightAxis
        rightAxis.removeAllLimitLines()
        rightAxis.addLimitLine(ll1)
        if self.yLabels.count > 0 {
            rightAxis.axisMaximum = Double(self.yLabels.count - 1)
            rightAxis.axisMinimum = 0
        } else {
            rightAxis.axisMaximum = (data.compactMap { $0 }.max() ?? 0) + 10.0
            rightAxis.axisMinimum = (data.compactMap { $0 }.min() ?? 0) - 10.0
        }
        rightAxis.drawLimitLinesBehindDataEnabled = true
        
        //Values
        let values = self.getDataEntries()
        let periodString = studyPeriod.getPeriodString(fromDateStrings: self.xLabels)
        let set1 = LineChartDataSet(entries: values, label: periodString)
        set1.drawIconsEnabled = false
        set1.drawValuesEnabled = false
        set1.drawCirclesEnabled = true
        set1.drawCircleHoleEnabled = true
        set1.highlightLineDashLengths = [5, 2.5]
        
        set1.setColor(self.plotColor)
        set1.setCircleColor(self.plotColor)
        set1.lineWidth = 2
        set1.circleRadius = 6
        set1.circleHoleColor = .white
        set1.valueFont = .systemFont(ofSize: 9)
        
        let data = LineChartData(dataSet: set1)
        self.chartView.data = data
    }
    
    fileprivate func configureXAxis() {
        self.chartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        self.chartView.xAxis.drawGridLinesEnabled = false
        self.chartView.xAxis.forceLabelsEnabled = true
        self.chartView.xAxis.axisLineColor = ColorPalette.color(withType: .primaryText)
        self.chartView.xAxis.labelTextColor = ColorPalette.color(withType: .primaryText)
        self.chartView.xAxis.labelFont = FontPalette.fontStyleData(forStyle: .header3).font
        self.chartView.xAxis.wordWrapEnabled = false
        self.chartView.xAxis.yOffset = 0
        
        if self.studyPeriod == .week {
            let range = self.getXAxisRange(periodType: self.studyPeriod)
            self.chartView.xAxis.labelCount = range.interval
            self.chartView.xAxis.axisMinimum = range.min
            self.chartView.xAxis.axisMaximum = range.max
        }
    }
    
    fileprivate func configureYAxis() {
        let rightAxis = chartView.rightAxis
        rightAxis.removeAllLimitLines()
        rightAxis.centerAxisLabelsEnabled = false
        rightAxis.forceLabelsEnabled = true
        rightAxis.axisLineColor = ColorPalette.color(withType: .primaryText)
        rightAxis.labelTextColor = ColorPalette.color(withType: .primaryText)
        rightAxis.labelFont = FontPalette.fontStyleData(forStyle: .header3).font
        rightAxis.drawGridLinesEnabled = false
        rightAxis.drawLimitLinesBehindDataEnabled = true
        rightAxis.drawZeroLineEnabled = true
    }
    
    fileprivate func getXAxisRange(periodType: StudyPeriod) -> (min: Double, max: Double, interval: Int) {
        var value: (min: Double, max: Double, interval: Int)!
        if periodType == .week {
            value = (min: 0, max: 6, interval: 6)
        } else {
            value = (min: 0, max: 3, interval: 3)
        }
        return value
    }
    
    private func getDataEntries() -> [ChartDataEntry] {
        var dataEntries: [ChartDataEntry] = []
        self.xLabels.enumerated().forEach { (index, _) in
            if index < self.data.count {
                dataEntries.append(ChartDataEntry(x: Double(index),
                                                  y: self.data[index] ?? 0.0,
                                                  icon: ImagePalette.image(withName: .circular)))
            }
        }
        return dataEntries
    }
}

/// Customised x-axis formmater to render the x-axis strings with format based on the study type and period type.
class XAxisValueFormatter: NSObject, IAxisValueFormatter {
    private let studyPeriod: StudyPeriod
    private let xLabels: [String]
    
    init(studyPeriod: StudyPeriod, xLabels: [String]) {
        self.studyPeriod = studyPeriod
        self.xLabels = xLabels
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        
        let currentDateString = self.xLabels[index]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = studyPeriod.dateDecodeFormat
        guard let currentDate = dateFormatter.date(from: currentDateString) else { return "\(value)"}
        
        switch self.studyPeriod {
        case .week:
            return currentDate.string(withFormat: dayShort)
        case .year:
            return currentDate.string(withFormat: yearShortDate)
        case .month:
            return currentDate.string(withFormat: monthShort)
//            if index >= 0, index < self.studyPeriod.getXAxisRangeValues(startDate: self.endDate).count {
//                return self.studyPeriod.getXAxisRangeValues(startDate: self.endDate)[index]
//            } else {
//                return "\(value)"
//            }
        }
    }
}

class YAxisValueFormatter: NSObject, IAxisValueFormatter {
    private let yLabels: [String]
    
    init(yLabels: [String]) {
        self.yLabels = yLabels
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        guard index >= 0, index < self.yLabels.count else {
            return "\(Int(value))"
        }
        let label = self.yLabels[index]
        return label.replacingOccurrences(of: " ", with: "\n")
    }
}
