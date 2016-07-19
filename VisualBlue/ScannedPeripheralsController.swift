//
//  ScannedPeripheralsController.swift
//  VisualBlue
//
//  Created by 杨洋 on 6/4/16.
//  Copyright © 2016 Sheepy. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import RxCocoa

class ScannedPeripheralsController: UIViewController {

    @IBOutlet var tableView: UITableView!

    var scannedPeripherals: [ScannedPeripheral] = []

    let manager = BluetoothManager()
    let disposeBag = DisposeBag()
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ScannedPeripheral>>()

    override func viewDidLoad() {
        super.viewDidLoad()

        configTableView()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let controller = segue.destinationViewController as? CharacteristicsController,
            peripheral = sender as? Peripheral else { return }

        controller.peripheral = peripheral
    }
}

private extension ScannedPeripheralsController {

    func configTableView() {
        tableView.rowHeight = 250
        tableView.tableFooterView = UIView()

        configDataSource()
        bindDataSource()
        configDelegate()
    }

    func configDataSource() {
        dataSource.configureCell = { _, tableView, _, scannedPeripheral in
            let cell = tableView.dequeueReusableCellWithIdentifier(CellId.ScannedPeripheral)!
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "Name: \(scannedPeripheral.advertisementData.localName ?? "Unknown") \nUUID: \(scannedPeripheral.peripheral.identifier.UUIDString) \n"
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = "Advertisement Data: \n \(scannedPeripheral.advertisementData.advertisementData)"
            cell.imageView?.image = self.iconForRSSI(scannedPeripheral.RSSI)
            return cell
        }

        dataSource.titleForHeaderInSection = { dataSource, sectionIndex in
            let section = dataSource.sectionAtIndex(sectionIndex)
            return section.items.count > 0 ? "Peripherals: \(section.items.count)" : "No peripheral found"
        }
    }

    func bindDataSource() {
        manager.rx_state
            .filter { $0 == .PoweredOn }
            .take(1)
            .flatMap { _ in self.manager.scanForPeripherals(nil) }
            .filter(isNewPeripheral)
            .map { self.scannedPeripherals.append($0) }
            .map { [SectionModel(model: "Peripheral", items: self.scannedPeripherals)] }
            .bindTo(tableView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)
    }

    func configDelegate() {
        tableView.rx_itemSelected
            .subscribeNext { self.tableView.deselectRowAtIndexPath($0, animated: true) }
            .addDisposableTo(disposeBag)

        tableView.rx_modelSelected(ScannedPeripheral.self)
            .asObservable()
            .flatMap { $0.peripheral.connect() }
            .subscribe(handleEvent)
            .addDisposableTo(disposeBag)
    }

    func isNewPeripheral(scannedPeripheral: ScannedPeripheral) -> Bool {
        return !scannedPeripherals.contains{ $0.peripheral == scannedPeripheral.peripheral }
    }

    func iconForRSSI(RSSI: NSNumber) -> UIImage? {
        let level: Int
        switch RSSI.integerValue {
        case RSSILevel.WeakMinValue ..< RSSILevel.MediumMinValue:
            level = 1
        case RSSILevel.MediumMinValue ..< RSSILevel.StrongMinValue:
            level = 2
        case RSSILevel.StrongMinValue ..< RSSILevel.ValidMinValue:
            level = 3
        default:
            level = 0
        }
        let imageName = "RSSI_\(level)"
        return UIImage(named: imageName)
    }

    func handleEvent(event: Event<Peripheral>) {
        switch event {
        case .Next(let peripheral):
            self.performSegueWithIdentifier(SegueId.ShowCharacteristics, sender: peripheral)
        case .Error(let error):
            let alertController = UIAlertController(title: "Connect Failed", message: "Error: \(error)", preferredStyle: .Alert)
            self.presentViewController(alertController, animated: true, completion: nil)
        case .Completed:
            print("Completed")
        }
    }
}
