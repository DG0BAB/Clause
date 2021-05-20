// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Name of this Package
let packageName = "Clause"

// Package creation
let package = Package(name: packageName)

// Products define the executables and libraries produced by a package, and make them visible to other packages.
package.products = [.library(name: packageName, targets: [packageName])]
package.platforms = [.iOS(.v13), .macOS(.v10_15)]

package.dependencies = [
	.package(url: "git@github.com:DG0BAB/PetiteLogger.git", .branch("master"))
]

let targetDependencies: [Target.Dependency] = [
	"PetiteLogger"
]

package.targets = [
	.target(name: packageName,
			dependencies: targetDependencies,
			path: "Sources"),

	.testTarget(name: "\(packageName)Tests",
		dependencies: [Target.Dependency(stringLiteral: packageName)],
		path: "Tests"),
]
