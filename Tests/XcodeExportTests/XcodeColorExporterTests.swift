import XCTest
import FigmaExportCore
@testable import XcodeExport
import CustomDump

final class XcodeColorExporterTests: XCTestCase {
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private var colorsFile: URL!
    private var colorsAssetCatalog: URL!
    
    private let colorPair1 = AssetPair<Color>(
        light: Color(name: "colorPair1", red: 1, green: 1, blue: 1, alpha: 1),
        dark: Color(name: "colorPair1", red: 0, green: 0, blue: 0, alpha: 1))
    
    private let colorPair2 = AssetPair<Color>(
        light: Color(name: "colorPair2", red: 119.0/255.0, green: 3.0/255.0, blue: 1.0, alpha: 0.5),
        dark: nil)
    
    private lazy var color3: Color = {
        var color = Color(name: "background/primary", red: 119.0/255.0, green: 3.0/255.0, blue: 1.0, alpha: 0.5)
        color.name = "backgroundPrimary"
        return color
    }()
    
    private lazy var colorPair3 = AssetPair<Color>(
        light: color3,
        dark: nil)
    
    private let colorWithKeyword = AssetPair<Color>(light: Color(name: "class", platform: .ios, red: 1, green: 1, blue: 1, alpha: 1), dark: nil)
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        colorsFile = fileManager.temporaryDirectory.appendingPathComponent("Colors.swift")
        colorsAssetCatalog = fileManager.temporaryDirectory.appendingPathComponent("Assets.xcassets/Colors")
    }
    
    // MARK: - Tests
    
    func testExport_without_assets() {
        let output = XcodeColorsOutput(assetsColorsURL: nil, assetsInMainBundle: true, colorSwiftURL: colorsFile)
        let exporter = XcodeColorExporter(output: output)
        
        let result = exporter.export(colorPairs: [colorPair1, colorPair2])
        XCTAssertEqual(result.count, 1)
        
        let content = result[0].data
        XCTAssertNotNil(content)
        
        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        public extension UIColor {
            static var colorPair1: UIColor {
                if #available(iOS 13.0, *) {
                    return UIColor { traitCollection -> UIColor in
                        if traitCollection.userInterfaceStyle == .dark {
                            return UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)
                        } else {
                            return UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
                        }
                    }
                } else {
                    return UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
                }
            }
            static var colorPair2: UIColor {
                return UIColor(red: 0.467, green: 0.012, blue: 1.000, alpha: 0.500)
            }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }
    
    func testExport_with_assets() {
        let output = XcodeColorsOutput(assetsColorsURL: colorsAssetCatalog, assetsInMainBundle: true, colorSwiftURL: colorsFile)
        let exporter = XcodeColorExporter(output: output)
        let result = exporter.export(colorPairs: [colorPair1, colorPair2])
        
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Colors.swift"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("Assets.xcassets/Colors/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("colorPair1.colorset/Contents.json"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("colorPair2.colorset/Contents.json"))
        
        let content = result[0].data
        XCTAssertNotNil(content)
        
        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        public extension UIColor {
            static var colorPair1: UIColor { UIColor(named: #function)! }
            static var colorPair2: UIColor { UIColor(named: #function)! }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }

    func testExport_with_objc() {
        let output = XcodeColorsOutput(
            assetsColorsURL: colorsAssetCatalog,
            assetsInMainBundle: true,
            addObjcAttribute: true,
            colorSwiftURL: colorsFile
        )
        let exporter = XcodeColorExporter(output: output)
        let result = exporter.export(colorPairs: [colorPair1, colorPair2])

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Colors.swift"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("Assets.xcassets/Colors/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("colorPair1.colorset/Contents.json"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("colorPair2.colorset/Contents.json"))

        let content = result[0].data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        public extension UIColor {
            @objc static var colorPair1: UIColor { UIColor(named: #function)! }
            @objc static var colorPair2: UIColor { UIColor(named: #function)! }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }
    
    func testExport_with_assets_in_separate_bundle() {
        let output = XcodeColorsOutput(assetsColorsURL: colorsAssetCatalog, assetsInMainBundle: false, colorSwiftURL: colorsFile)
        let exporter = XcodeColorExporter(output: output)
        let result = exporter.export(colorPairs: [colorPair1, colorPair2])
        
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Colors.swift"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("Assets.xcassets/Colors/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("colorPair1.colorset/Contents.json"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("colorPair2.colorset/Contents.json"))
        
        let content = result[0].data
        XCTAssertNotNil(content)
        
        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIColor {
            static var colorPair1: UIColor { UIColor(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
            static var colorPair2: UIColor { UIColor(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }

    func testExport_with_assets_in_swift_package() {
        let output = XcodeColorsOutput(assetsColorsURL: colorsAssetCatalog, assetsInMainBundle: false, assetsInSwiftPackage: true, colorSwiftURL: colorsFile)
        let exporter = XcodeColorExporter(output: output)
        let result = exporter.export(colorPairs: [colorPair1, colorPair2])

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Colors.swift"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("Assets.xcassets/Colors/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("colorPair1.colorset/Contents.json"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("colorPair2.colorset/Contents.json"))

        let content = result[0].data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle.module
        }

        public extension UIColor {
            static var colorPair1: UIColor { UIColor(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
            static var colorPair2: UIColor { UIColor(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }
    
    func testExport_swiftui() {
        let output = XcodeColorsOutput(assetsColorsURL: colorsAssetCatalog, assetsInMainBundle: true, colorSwiftURL: nil, swiftuiColorSwiftURL: colorsFile)
        let exporter = XcodeColorExporter(output: output)
        let result = exporter.export(colorPairs: [colorPair1, colorPair2])
        
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Colors.swift"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("Assets.xcassets/Colors/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("colorPair1.colorset/Contents.json"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("colorPair2.colorset/Contents.json"))
        
        let content = result[0].data
        XCTAssertNotNil(content)
        
        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import SwiftUI

        public extension Color {
            static var colorPair1: Color { Color(#function) }
            static var colorPair2: Color { Color(#function) }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }
    
    func testExport_withProvidesNamespace() {
        let output = XcodeColorsOutput(
            assetsColorsURL: colorsAssetCatalog,
            assetsInMainBundle: true,
            colorSwiftURL: colorsFile,
            groupUsingNamespace: true
        )
        let exporter = XcodeColorExporter(output: output)
        let result = exporter.export(colorPairs: [colorPair3])
        
        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Colors.swift"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("Assets.xcassets/Colors/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("background/Contents.json"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("primary.colorset/Contents.json"))
        
        let content = result[0].data
        XCTAssertNotNil(content)
        
        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        public extension UIColor {
            static var backgroundPrimary: UIColor { UIColor(named: "background/primary")! }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }
    
    func testExportWhenNameIsSwiftKeyword() {
        let output = XcodeColorsOutput(assetsColorsURL: nil, assetsInMainBundle: true, colorSwiftURL: colorsFile)
        let exporter = XcodeColorExporter(output: output)
        
        let result = exporter.export(colorPairs: [colorWithKeyword])
        XCTAssertEqual(result.count, 1)
        
        let content = result[0].data
        XCTAssertNotNil(content)
        
        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        public extension UIColor {
            static var `class`: UIColor {
                return UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
            }
        }

        """
        XCTAssertNoDifference(generatedCode, referenceCode)
    }
}
