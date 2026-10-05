import Foundation
import Network
import Core

/// Discovers HDHomeRun tuners via SSDP/Bonjour.
///
/// Uses `NWBrowser` to find `_hdhomerun._tcp` services on the local network.
/// For each discovered service, fetches `device.xml` to extract device details.
public struct SSDPDiscoverer: Sendable {

    public init() {}

    /// Discover HDHomeRun tuners on the local network.
    /// - Returns: Array of discovered tuners.
    public func discover() async throws -> [Tuner] {
        // Use an actor to safely collect results from concurrent callbacks
        let collector = ResultCollector()

        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: "_hdhomerun._tcp", domain: nil), using: parameters)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                browser.browseResultsChangedHandler = { resultsList, changes in
                    for result in resultsList {
                        if case .service(let name, let type, let domain, let interface) = result.endpoint {
                            self.resolveService(name: name, type: type, domain: domain, interface: interface) { tuner in
                                if let tuner = tuner {
                                    Task { await collector.add(tuner) }
                                }
                            }
                        }
                    }
                }

                browser.stateUpdateHandler = { state in
                    switch state {
                    case .failed(let error):
                        continuation.resume(throwing: error)
                    case .cancelled:
                        Task {
                            let collected = await collector.getAll()
                            continuation.resume(returning: collected)
                        }
                    default:
                        break
                    }
                }

                browser.start(queue: .global())

                // Timeout after 5 seconds
                Task {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                    browser.cancel()
                }
            }
        } onCancel: {
            browser.cancel()
        }
    }

    private func resolveService(name: String, type: String, domain: String, interface: NWInterface?, completion: @escaping @Sendable (Tuner?) -> Void) {
        let endpoint = NWEndpoint.service(name: name, type: type, domain: domain, interface: interface)
        let connection = NWConnection(to: endpoint, using: .tcp)

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.fetchDeviceXML(connection: connection) { tuner in
                    completion(tuner)
                    connection.cancel()
                }
            case .failed(let error):
                print("Connection failed: \(error)")
                completion(nil)
                connection.cancel()
            default:
                break
            }
        }

        connection.start(queue: .global())
    }

    private func fetchDeviceXML(connection: NWConnection, completion: @escaping @Sendable (Tuner?) -> Void) {
        let request = "GET /device.xml HTTP/1.1\r\nHost: \(connection.endpoint)\r\nConnection: close\r\n\r\n"
        let requestData = request.data(using: .utf8)!

        connection.send(content: requestData, completion: .contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
                completion(nil)
                return
            }

            self.receiveResponse(connection: connection) { data in
                guard let data = data,
                      let response = String(data: data, encoding: .utf8),
                      let xmlStart = response.range(of: "<?xml")?.lowerBound else {
                    completion(nil)
                    return
                }

                let xmlString = String(response[xmlStart...])
                let tuner = self.parseDeviceXML(xmlString, connection: connection)
                completion(tuner)
            }
        })
    }

    private func receiveResponse(connection: NWConnection, completion: @escaping @Sendable (Data?) -> Void) {
        var receivedData = Data()

        func receive() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                if let data = data {
                    receivedData.append(data)
                }
                if isComplete || error != nil {
                    completion(receivedData.isEmpty ? nil : receivedData)
                } else {
                    receive()
                }
            }
        }

        receive()
    }

    private func parseDeviceXML(_ xml: String, connection: NWConnection) -> Tuner? {
        let deviceID = extractXMLTag(xml, tag: "serialNumber") ?? extractXMLTag(xml, tag: "UDN")?.replacingOccurrences(of: "uuid:", with: "") ?? "unknown"
        let model = extractXMLTag(xml, tag: "modelNumber") ?? "Unknown"
        let firmware = extractXMLTag(xml, tag: "firmwareVersion") ?? "Unknown"
        let tunerCountStr = extractXMLTag(xml, tag: "tunerCount") ?? "2"
        let tunerCount = Int(tunerCountStr) ?? 2

        let ipAddress = extractIP(from: connection.endpoint)

        return Tuner(
            id: deviceID,
            ipAddress: ipAddress,
            model: model,
            firmwareVersion: firmware,
            tunerCount: tunerCount,
            discoveredAt: Date(),
            manualOverride: false
        )
    }

    private func extractXMLTag(_ xml: String, tag: String) -> String? {
        let startTag = "<\(tag)>"
        let endTag = "</\(tag)>"
        guard let startRange = xml.range(of: startTag),
              let endRange = xml.range(of: endTag, range: startRange.upperBound..<xml.endIndex) else {
            return nil
        }
        return String(xml[startRange.upperBound..<endRange.lowerBound])
    }

    private func extractIP(from endpoint: NWEndpoint) -> String {
        switch endpoint {
        case .hostPort(let host, _):
            return "\(host)"
        case .service(_, _, _, _):
            return "0.0.0.0"
        default:
            return "0.0.0.0"
        }
    }
}

/// Actor to safely collect results from concurrent callbacks.
private actor ResultCollector {
    private var results: [Tuner] = []

    func add(_ tuner: Tuner) {
        results.append(tuner)
    }

    func getAll() -> [Tuner] {
        results
    }
}