//
//  Broadcaster.swift
//  Bcast6000
//
//  Created by Douglas Adams on 6/8/23.
//

import Combine
import Foundation
import CocoaAsyncSocket

import Vita

public final class Broadcaster: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _cancel: Task<(), Never>?
  private var _cancellables = Set<AnyCancellable>()
  private let _formatter = DateFormatter()
  private var _port: UInt16
  private var _sequenceNumber: UInt8 = 0
  private let _udpQ = DispatchQueue(label: "Broadcaster" + ".udpQ")
  private var _udpSocket: GCDAsyncUdpSocket!
  
  private static var kBroadcastAddress = "255.255.255.255"
  
  private struct Radio {
    var name: String
    var payload: [String]
  }

  private var radioList: [Radio] =
  [
    Radio(name: "Radio1", payload: [
      "discovery_protocol_version=3.0.0.2",
      "model=FLEX-6500",
      "serial=1715-4055-6500-9722",
      "version=3.4.23.15544",
      "nickname=DougsFlex",
      "callsign=K3TZR",
      "ip=192.168.1.220",
      "port=4992",
      "status=Available",
      "inuse_ip=",
      "inuse_host=",
      "max_licensed_version=v3",
      "radio_license_id=00-1C-2D-02-03-BE",
      "requires_additional_license=0",
      "fpc_mac=",
      "wan_connected=1",
      "licensed_clients=2",
      "available_clients=2",
      "max_panadapters=4",
      "available_panadapters=4",
      "max_slices=4",
      "available_slices=4",
      "gui_client_ips=",
      "gui_client_hosts=",
      "gui_client_programs=",
      "gui_client_stations=",
      "gui_client_handles= "
    ]),
    Radio(name: "Radio2", payload: [
      "discovery_protocol_version=3.0.0.2",
      "model=FLEX-6300",
      "serial=1234-5678-6300-1234",
      "version=3.4.23.15544",
      "nickname=Shack",
      "callsign=K3TZR",
      "ip=192.168.1.221",
      "port=4992",
      "status=Available",
      "inuse_ip=",
      "inuse_host=",
      "max_licensed_version=v3",
      "radio_license_id=00-1C-2D-02-03-BE",
      "requires_additional_license=0",
      "fpc_mac=",
      "wan_connected=1",
      "licensed_clients=2",
      "available_clients=2",
      "max_panadapters=4",
      "available_panadapters=4",
      "max_slices=4",
      "available_slices=4",
      "gui_client_ips=",
      "gui_client_hosts=",
      "gui_client_programs=",
      "gui_client_stations=",
      "gui_client_handles="
    ]),
    Radio(name: "Radio3", payload: [
      "discovery_protocol_version=3.0.0.2",
      "model=FLEX-6400",
      "serial=1234-5678-6400-1234",
      "version=3.4.23.15544",
      "nickname=ODU Club",
      "callsign=K3TZR",
      "ip=192.168.1.222",
      "port=4992",
      "status=Available",
      "inuse_ip=",
      "inuse_host=",
      "max_licensed_version=v3",
      "radio_license_id=00-1C-2D-02-03-BE",
      "requires_additional_license=0",
      "fpc_mac=",
      "wan_connected=1",
      "licensed_clients=2",
      "available_clients=2",
      "max_panadapters=4",
      "available_panadapters=4",
      "max_slices=4",
      "available_slices=4",
      "gui_client_ips=",
      "gui_client_hosts=",
      "gui_client_programs=",
      "gui_client_stations=",
      "gui_client_handles="
    ]),
    Radio(name: "Radio4", payload: [
      "discovery_protocol_version=3.0.0.2",
      "model=FLEX-6600",
      "serial=1234-5678-6600-1234",
      "version=3.4.23.15544",
      "nickname=JohnsFlex",
      "callsign=K3TZR",
      "ip=192.168.1.223",
      "port=4992",
      "status=Available",
      "inuse_ip=",
      "inuse_host=",
      "max_licensed_version=v3",
      "radio_license_id=00-1C-2D-02-03-BE",
      "requires_additional_license=0",
      "fpc_mac=",
      "wan_connected=1",
      "licensed_clients=2",
      "available_clients=2",
      "max_panadapters=4",
      "available_panadapters=4",
      "max_slices=4",
      "available_slices=4",
      "gui_client_ips=",
      "gui_client_hosts=",
      "gui_client_programs=",
      "gui_client_stations=",
      "gui_client_handles="
    ]),
    Radio(name: "Radio5", payload: [
      "discovery_protocol_version=3.0.0.2",
      "model=FLEX-6700",
      "serial=1234-5678-6700-1234",
      "version=3.4.23.15544",
      "nickname=Home",
      "callsign=K3TZR",
      "ip=192.168.1.224",
      "port=4992",
      "status=Available",
      "inuse_ip=",
      "inuse_host=",
      "max_licensed_version=v3",
      "radio_license_id=00-1C-2D-02-03-BE",
      "requires_additional_license=0",
      "fpc_mac=",
      "wan_connected=1",
      "licensed_clients=2",
      "available_clients=2",
      "max_panadapters=4",
      "available_panadapters=4",
      "max_slices=4",
      "available_slices=4",
      "gui_client_ips=",
      "gui_client_hosts=",
      "gui_client_programs=",
      "gui_client_stations=",
      "gui_client_handles="
    ])
  ]

  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(port: UInt16) {
    _port = port
    super.init()
    
    _formatter.timeZone = .current
    _formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func start(numberOfRadios: Int, interval: TimeInterval) {
    //    log("Broadcaster: STARTED", .info, #function, #file, #line)
    
    // create a Udp socket and set options
    _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    try! _udpSocket.enableReusePort(true)
    try! _udpSocket.bind(toPort: _port)
    
    try! _udpSocket!.enableBroadcast(true)
    
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: interval, on: .main, in: .default)
      .autoconnect()
      .sink { [self] now in
        _sequenceNumber = (_sequenceNumber + 1) % 16
        
        for i in 0..<numberOfRadios {
          if let discoveryPacket = Vita.discovery(payload: radioList[i].payload, sequenceNumber: _sequenceNumber) {
            sendBroadcast(discoveryPacket, Broadcaster.kBroadcastAddress, _port)
//          sendBroadcast(discoveryPacket, "192.168.1.211", self._port)
            print( hexDump(discoveryPacket) )
          }
        }
      }
      .store(in: &_cancellables)
  }
  
  func stop() {
    _cancellables = Set<AnyCancellable>()
    _udpSocket?.close()
    //    log("Broadcaster: STOPPED", .info, #function, #file, #line)
  }
  
  func sendBroadcast(_ data: Data, _ host: String, _ port: UInt16) {
    _udpSocket.send(data, toHost: host, port: port, withTimeout: -1, tag: 0)
  }
}


extension Broadcaster: GCDAsyncUdpSocketDelegate {
  
}

extension Broadcaster {
  
  /// Create a String representing a Hex Dump of a UInt8 array
  ///
  /// - Parameters:
  ///   - data:           an array of UInt8
  ///   - len:            the number of elements to be processed
  /// - Returns:          a String
  ///
//  public func hexDump(rawData: Data, address: Data, count: Int, data: [UInt8], len: Int) -> String {
  public func hexDump(_ data: Data) -> String {
    let len = data.endIndex
    
    var bytes = [UInt8](repeating: 0x00, count: len)

    (data as NSData).getBytes(&bytes, range: NSMakeRange(0, len))
    
    var string = "  \(String(format: "%3d", len + 1))    00 01 02 03 04 05 06 07   08 09 0A 0B 0C 0D 0E 0F\n"
    string += " bytes    -------------------------------------------------\n\n"
    
    string += "----- HEADER -----\n"
    
    var address = 0
    string += address.toHex() + "   "
    for i in 1...28 {
      string += String(format: "%02X", bytes[i-1]) + " "
      if (i % 8) == 0 { string += "  " }
      if (i % 16) == 0 {
        string += "\n"
        address += 16
        string += address.toHex() + "   "
      }
    }

    string += "\n\n----- PAYLOAD -----\n"
      
    
    string += address.toHex() + "                                         "
    for i in 29...len {
      string += String(format: "%02X", bytes[i-1]) + " "
      if (i % 8) == 0 { string += "  " }
      if (i % 16) == 0 {
        string += "\n"
        address += 16
        string += address.toHex() + "   "
      }
    }

    string += "\n\n----- PAYLOAD -----\n"
      
    address = 16
    string += address.toHex() + "                                         "
    for i in 29...len {
      string += String(decoding: bytes[i-1...i-1], as: UTF8.self) + "  "
      if (i % 8) == 0 { string += "  " }
      if (i % 16) == 0 {
        string += "\n"
        address += 16
        string += address.toHex() + "   "
      }
    }
    
    
    string += "\n\n----- PAYLOAD -----\n"
      

    let payloadBytes = bytes[27...len-1]
    let text = String(decoding: payloadBytes, as: UTF8.self)
    let lines = text.components(separatedBy: " ")
    let newText = lines.reduce("") {$0 + "<\($1)>\n"}
    string += newText
    
    
    string += "\n         -------------------------------------------------\n\n"
    return string
  }
}
