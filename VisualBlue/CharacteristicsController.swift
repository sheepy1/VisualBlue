//
//  CharacteristicsController.swift
//  VisualBlue
//
//  Created by 杨洋 on 6/6/16.
//  Copyright © 2016 Sheepy. All rights reserved.
//

import UIKit
import CoreBluetooth
import RxBluetoothKit
import RxSwift
import RxCocoa

class CharacteristicsController: UIViewController {

    var peripheral: Peripheral?

    let disposeBag = DisposeBag()
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Characteristic>>()

    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        configTableView()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        peripheral?.cancelConnection()
    }
}

private extension CharacteristicsController {
    func configTableView() {
        tableView.rowHeight = 60

        configDataSource()
        bindDataSource()
        configDelegate()
    }

    func configDataSource() {
        dataSource.configureCell = { _, tableView, _, characteristic in
            let cell = tableView.dequeueReusableCellWithIdentifier(CellId.Characteristic)!
            let properties = self.matchCharacteristicProperties(characteristic.properties)
            cell.textLabel?.text = "UUID: \(characteristic.UUID.UUIDString)"
            cell.detailTextLabel?.numberOfLines = 2
            cell.detailTextLabel?.text = "Belong to service: \(characteristic.service.UUID) \nProperties: \(properties)"
            return cell
        }

        dataSource.titleForHeaderInSection = { dataSource, sectionIndex in
            dataSource.sectionAtIndex(sectionIndex).identity
        }
    }

    func bindDataSource() {
        guard let peripheral = peripheral else { return }
        peripheral.discoverServices(nil)
            .flatMap(discoverCharacteristics)
            .map { [SectionModel(model: "Characteristic", items: $0)] }
            .bindTo(tableView.rx_itemsWithDataSource(dataSource))
            .addDisposableTo(disposeBag)
    }

    func discoverCharacteristics(services: [Service]) -> Observable<[Characteristic]> {
        return services
            .map { $0.discoverCharacteristics(nil) }
            .toObservable()
            .switchLatest()
    }

    func configDelegate() {
        tableView.rx_itemSelected
            .subscribeNext { self.tableView.deselectRowAtIndexPath($0, animated: true) }
            .addDisposableTo(disposeBag)
    }

    func matchCharacteristicProperties(properties: CBCharacteristicProperties) -> String {
        var propertiesString = " "

        if properties.contains(.AuthenticatedSignedWrites) { propertiesString += "AuthenticatedSignedWrites " }
        if properties.contains(.Broadcast) { propertiesString += "Broadcast " }
        if properties.contains(.ExtendedProperties) { propertiesString += "ExtendedProperties " }
        if properties.contains(.Indicate) { propertiesString += "Indicate " }
        if properties.contains(.IndicateEncryptionRequired) { propertiesString += "IndicateEncryptionRequired " }
        if properties.contains(.Notify) { propertiesString += "Notify " }
        if properties.contains(.NotifyEncryptionRequired) { propertiesString += "NotifyEncryptionRequired " }
        if properties.contains(.Read) { propertiesString += "Read " }
        if properties.contains(.Write) { propertiesString += "Write " }
        if properties.contains(.WriteWithoutResponse) { propertiesString += "WriteWithoutResponse " }

        return propertiesString
    }
}
