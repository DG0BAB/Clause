//
//  LocalizationSupport.swift
//  Clause
//
//  Created by Joachim Deelen on 04.04.19.
//  Copyright © 2019 micabo software UG. All rights reserved.
//

import Foundation

public protocol TableNameProviding {
	static var tableName: String { get }
}

extension TableNameProviding {
	public static var tableName: String {
		return "Localizable"
	}
}
