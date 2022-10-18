// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "<#TemplateProject#>",

    platforms: [
        .iOS("11.0"),
        .macOS("10.10"),
        .tvOS("11.0"),
        .watchOS("4.0")
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
