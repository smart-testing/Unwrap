//
//  UnwrapUITests.swift
//  Unwrap
//
//  Created by Paul Hudson on 09/08/2018.
//  Copyright © 2018 Hacking with Swift.
//

import Foundation
import XCTest

struct UIElement {
    var id: String
    let isEnabled: Bool
    let isHittable: Bool
    let isSelected: Bool
    let x: Double
    let y: Double
    let name: String
    let possibleActions: [String]
}

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

class ElementsExtractor {
    private static let blacklistedIdentifiers = ["YOAI_FoldersListHeaderAccountSwitcherAddAccount", "URL"]
    private static let blacklistedLabels = ["attachments share", "News"]

    private let types = [
        XCUIElement.ElementType.button,
        XCUIElement.ElementType.textField,
        XCUIElement.ElementType.staticText
    ]

    private var allElements: [XCUIElement] = []

    public func uielementToJSON(element: UIElement) -> [String: Any] {
        return [
            "id": element.id,
            "name": element.name,
//            "position": [
//                "x": 1,
//                "y": 2
//            ],
//            "size": [
//                "x": 1,
//                "y": 2
//            ],
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
                "TAP"
            ]
        ]
    }

    public func makeInputJSON(list: [UIElement]) -> [String: Any] {
        let dictList = list.map {
            uielementToJSON(element: $0)
        }
        return [
            "elements": dictList, //?
            "global": [
                "screenSize": "",
                "screenshot": "",
                "possibleActions": ""
            ]
        ]
    }

    public func getAllIdentifiers() -> [XCUIElement] {
        let start = CFAbsoluteTimeGetCurrent()
        var result: [XCUIElement] = []
        let application = XCUIApplication()
        for type in self.types {
            for e in application.descendants(matching: type).allElementsBoundByIndex {
//                if e.exists && e.isHittable {
                result.append(e)
//                }
            }
        }
        print("Elapsed \(CFAbsoluteTimeGetCurrent() - start)")
        return result
    }

    public func getAllElements(type: XCUIElement.ElementType) -> [XCUIElement] {
        return XCUIApplication().descendants(matching: type).allElementsBoundByIndex
    }

//    public func update() {
//        print("Update")
////        self.allElements = getAllIdentifiers()
//    }

    public func randomClick() {
        let type = self.types[Int.random(in: 0..<self.types.count)]
        print("Selected \(type.rawValue)")
//        let second: Double = 1000000
//        usleep(useconds_t(second))
        let a = getAllElements(type: type)
        if a.isEmpty {
            return
        }
        let i = Int.random(in: 0..<a.count)
        let _ = a[i].waitForExistence(timeout: 10)
//        XCTAssert(elementExists)
        let element = a[i]
        print("Selected \(i)/\(a.count)")
        go(element: element)
    }

    public func scrollDown() {
//        XCUIApplication().
    }

    @discardableResult
    public func go(element: XCUIElement) -> Bool {
        if !element.exists {
            return false
        }

//        for i in 1...10 {
//                print("Test button - \(i)...  exists: \(element.exists), label: \(element.label), identifier: \(element.identifier)")
//        }

        if ElementsExtractor.blacklistedIdentifiers.contains(element.identifier) {
            return false
        }
        if ElementsExtractor.blacklistedLabels.contains(element.label) {
            return false
        }
//        print("Go \(self.toString(element))")
//        if !element.safeTap() {
//            return false
//        }
//        element.tap()
        element.forceTapElement()
        return true
    }

    public func toString(_ element: XCUIElement) -> String {
        return "common=\(element) label=\(element.label) identifier=\(element.identifier) value=\(element.value ?? "") exists=\(element.exists) enabled=\(element.isEnabled) hittable=\(element.isHittable)"
    }
}

class UnwrapUITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHomeViewControllerExists() {
        let app = XCUIApplication()
        let tabBarsQuery = XCUIApplication().tabBars

        tabBarsQuery.buttons["Home"].tap()

        XCTAssertTrue(app.tables.otherElements["Ring progress"].exists)
        XCTAssertTrue(app.tables.cells["Rank"].exists)
        XCTAssertTrue(app.tables.cells["Points"].exists)
        XCTAssertTrue(app.tables.cells["Stat"].exists)
        XCTAssertTrue(app.tables.cells["Streak Reminder"].exists)
        XCTAssertTrue(app.tables.cells["Badges"].exists)
    }

    //Check that trying to share score displays the ActivityView on the HomeViewController
    func testShareScoreShows() {
        let app = XCUIApplication()

        app.tables.cells["Stat"].staticTexts["Share Score"].tap()

        //Delay ActivityViewController to verify the right buttons exist
        let predicate = NSPredicate(format: "exists == 1")
        let query = app.collectionViews.cells.collectionViews.containing(.button, identifier: "More").element

        expectation(for: predicate, evaluatedWith: query, handler: nil)

        waitForExpectations(timeout: 3, handler: nil)
    }

    //Check that tapping Help on the HomeViewController and then Credit show the correct controllers
    func testHelpAndCreditShow() {
        let app = XCUIApplication()
        let tabBarsQuery = XCUIApplication().tabBars

        tabBarsQuery.buttons["Home"].tap()

        XCTAssertTrue(app.buttons["Help"].exists)

        app.buttons["Help"].tap()

        XCTAssertTrue(app.navigationBars["Help"].exists)
        XCTAssertTrue(app.buttons["Credits"].exists)

        app.buttons["Credits"].tap()

        XCTAssert(app.navigationBars["Credits"].exists)
    }

    //Check that Learn activity opens and "Glossary" and "Learn" buttons work
    func testLearnActivity() {
        let app = XCUIApplication()
        let tabBarsQuery = XCUIApplication().tabBars

        XCTAssertTrue(!app.buttons["Glossary"].exists)

        tabBarsQuery.buttons["Learn"].tap()

        XCTAssertTrue(app.buttons["Glossary"].exists)

        app.buttons["Glossary"].tap()

        XCTAssertTrue(app.buttons["Learn"].exists)

        app.buttons["Learn"].firstMatch.tap()

        XCTAssertTrue(app.buttons["Glossary"].exists)
    }

    //Check that practice activity and alerts are working
    func testPracticeActivity() {
        let app = XCUIApplication()
        let tabBarsQuery = XCUIApplication().tabBars

        tabBarsQuery.buttons["Practice"].tap()

        print(app.debugDescription)

        app.staticTexts["Free Coding"].tap()

        XCTAssert(app.alerts["Activity Locked"].exists)

        app.alerts["Activity Locked"].buttons["OK"].tap()

        XCTAssert(!app.alerts["Activity Locked"].exists)
    }

    //Check that Next button works
    func testLearnNext() {
        let app = XCUIApplication()
        let tabBarsQuery = XCUIApplication().tabBars

        tabBarsQuery.buttons["Learn"].tap()

        XCTAssert(app.staticTexts["Simple Types"].exists)
        XCTAssert(app.staticTexts["Variables"].exists)

        app.staticTexts["Variables"].tap()

        XCTAssert(app.navigationBars.firstMatch.exists)
        XCTAssert(app.navigationBars.firstMatch.otherElements["Variables"].exists)

        app.navigationBars.firstMatch.otherElements["Variables"].tap()

        XCTAssert(app.buttons["Next"].exists)
        XCTAssert(!app.staticTexts["Variables"].exists)
        XCTAssert(!app.buttons["OK"].exists)

        app.buttons["Next"].tap()

        XCTAssert(app.staticTexts["Variables"].exists)
        XCTAssert(app.buttons["OK"].exists)

        app.buttons["OK"].tap()
        //Todo Check hint and skip
//        XCTAssert(app.buttons["Hint"].exists)
        print(app.debugDescription)
    }

    func testBuySwiftBooksLink() {
        let app = XCUIApplication()
        let tabBarsQuery = app.tabBars

        tabBarsQuery.buttons["News"].tap()

        XCTAssert(app.buttons["Buy Swift Books"].exists)

        app.buttons["Buy Swift Books"].tap()

        XCTAssert(app.buttons["Done"].exists)

        app.buttons["Done"].tap()

        XCTAssert(app.navigationBars["News"].exists)
    }

    func testRandomClick() {
        let e = ElementsExtractor()
        for i in 1...100 {
            print("Iteration number: \(i) .........")
            XCTAssertNoThrow(e.randomClick())
//            e.randomClick()
        }
    }

    func testHTTP() {
        let e = ElementsExtractor()


        let a = e.getAllElements(type: XCUIElement.ElementType.button)
        if a.isEmpty {
            return
        }

        var list = a.map {
            UIElement(id: $0.identifier, isEnabled: $0.isEnabled, isHittable: $0.isHittable, isSelected: $0.isSelected, x: $0.frame.origin.x.native, y: $0.frame.origin.y.native, name: $0.label, possibleActions: ["click"])
        }
        for i in 0...(list.count - 1) {
            list[i].id = String(i)
        }

        let jsonData: Data
        do {
            var good = false
            jsonData = try JSONSerialization.data(withJSONObject: e.makeInputJSON(list: list))
            let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)!
            print(jsonString)

            let url = URL(string: "http://0.0.0.0:8080/generate-action")!
            var request = URLRequest(url: url)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")  // the request is JSON
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
            request.httpMethod = "POST"

            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    let localId:Int? = Int(responseJSON["id"] as! String)
                    if (responseJSON["action"] as! String) == "TAP" {
                        e.go(element: a[localId!])
                    } else {
                        print("Got bad JSON")
                    }
                    print(responseJSON)
                }
                good = true
            }
            if !good {
                print("Can't establish connection with the server. Abort")
                exit(1)
            }
            task.resume()
        } catch {
            print("Problem..")
        }
    }
}
