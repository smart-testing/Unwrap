import Foundation
import XCTest

extension XCUIElement {
    func forceTapElement() {
        if !self.exists {
            return
        }
        if !self.isEnabled {
            return
        }
        if self.isHittable {
            self.tap()
        } else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
            coordinate.tap()
        }
    }
}

public class Testopithecus: XCTestCase {

    private let iterations: Int = 30
    private let serverURL: String = "http://0.0.0.0:8080/generate-action"

    private struct UIElement {
        var id: String
        let isEnabled: Bool
        let isHittable: Bool
        let isSelected: Bool
        let x: Double
        let y: Double
        let name: String
        let possibleActions: [String]
    }

    private static let blacklistedIdentifiers = ["URL"]
    private static let blacklistedLabels = ["attachments share", "News", "Challenges"]

    private let types = [
        XCUIElement.ElementType.button,
        XCUIElement.ElementType.textField,
        XCUIElement.ElementType.staticText
    ]

    private func getAllIdentifiers() -> [XCUIElement] {
        let start = CFAbsoluteTimeGetCurrent()
        var result: [XCUIElement] = []
        let application = XCUIApplication()
        for type in self.types {
            for e in application.descendants(matching: type).allElementsBoundByIndex {
                result.append(e)
            }
        }
        print("Elapsed \(CFAbsoluteTimeGetCurrent() - start)")
        return result
    }

    private func getAllElements(type: XCUIElement.ElementType) -> [XCUIElement] {
        return XCUIApplication().descendants(matching: type).allElementsBoundByIndex
    }

    @discardableResult
    private func go(element: XCUIElement) -> Bool {
        if !element.exists {
            return false
        }
        if Testopithecus.blacklistedIdentifiers.contains(element.identifier) {
            return false
        }
        if Testopithecus.blacklistedLabels.contains(element.label) {
            return false
        }
        element.forceTapElement()
        return true
    }

    func randomClick() {
        let type = self.types[Int.random(in: 0..<self.types.count)]
        print("Selected \(type.rawValue)")
        let currentElements = getAllElements(type: type)
        if currentElements.isEmpty {
            return
        }
        let i = Int.random(in: 0..<currentElements.count)
        let _ = currentElements[i].waitForExistence(timeout: 10)
        let element = currentElements[i]
        print("Selected \(i)/\(currentElements.count)")
        go(element: element)
    }

    private func uiElementToJSON(element: UIElement) -> [String: Any] {
        return [
            "id": element.id,
            "name": element.name,
            "attributes": [
                "isSelected": element.isSelected,
                "isHittable": element.isHittable,
                "isEnabled": element.isEnabled,
                "center": [
                    "x": element.x,
                    "y": element.y
                ]
            ],
            "possibleActions": [
                //ToDo
                "TAP"
            ]
        ]
    }

    private func makeInputJSON(list: [UIElement]) -> [String: Any] {
        let dictList = list.map {
            uiElementToJSON(element: $0)
        }
        return [
            "elements": dictList,
            //ToDo
            "global": [
                "screenSize": "",
                "screenshot": "",
                "possibleActions": ""
            ]
        ]
    }

    private func prepareRequest(jsonData: Data) -> URLRequest {
        let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!
        print(jsonString)
        let url = URL(string: serverURL)!
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        return request
    }

    public func testTestopithecus() {
        XCUIApplication().launch()
        var jsonData: Data
        var currentElements: [XCUIElement] = []
        for type in types {
            currentElements += getAllElements(type: type)
        }
        if currentElements.isEmpty {
            return
        }
        var list = currentElements.map {
            UIElement(id: $0.identifier, isEnabled: $0.isEnabled, isHittable: $0.isHittable, isSelected: $0.isSelected,
                    x: $0.frame.origin.x.native, y: $0.frame.origin.y.native, name: $0.label, possibleActions: ["TAP"])
        }
        for i in 0...(list.count - 1) {
            list[i].id = String(i)
        }
        print(currentElements)
        for _ in 0...iterations {
            do {
                jsonData = try JSONSerialization.data(withJSONObject: makeInputJSON(list: list))
                let request = prepareRequest(jsonData: jsonData)
                var responseJSON: Any?
                let expectation = XCTestExpectation(description: "Get JSON")
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    XCTAssertNotNil(data, "No data was downloaded.")
                    responseJSON = try? JSONSerialization.jsonObject(with: data!, options: [])
                    expectation.fulfill()
                }
                task.resume()
                wait(for: [expectation], timeout: 10.0)
                if let responseJSON = responseJSON as? [String: Any] {
                    print(responseJSON.keys.contains("id"))
                    if responseJSON.keys.contains("id") {
                        let localId: Int = Int(responseJSON["id"] as! String)!
                        if (responseJSON["action"] as! String) == "TAP" {
                            go(element: currentElements[localId])
                        }
                    } else {
                        print("No Action Required")
                    }
                    print(responseJSON)
                }
            } catch {
                print("Problem..")
            }
        }
    }
}
