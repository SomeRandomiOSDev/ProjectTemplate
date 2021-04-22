// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "<#TemplateProject#>",

    platforms: [
        .iOS("9.0"),
        .macOS("10.10"),
        .tvOS("9.0"),
        .watchOS("2.0")
    ],

    products: [
        .library(name: "<#TemplateProject#>", targets: ["<#TemplateProject#>"])
    ],

    targets: [
        .target(name: "<#TemplateProject#>"),
        .testTarget(name: "<#TemplateProject#>Tests", dependencies: ["<#TemplateProject#>"])
    ],

    swiftLanguageVersions: [.version("5")]
)
