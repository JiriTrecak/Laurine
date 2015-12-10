//
//  JTDataEnums.swift
//  Laurine Example Project
//
//  Created by Jiří Třečák
//  Copyright © 2015 Jiri Trecak. All rights reserved.
//


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Imports

import UIKit
import Foundation


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Enums

enum VariableDataType {
    case String
    case Number
    case Bool
    case Int
    case Double
    case Float
    case Date
    case Array
    case Dictionary
}

enum VariableAssignement {
    case Int
    case Double
    case Float
    case Any
}

enum RelationshipType {
    case ToOne
    case ToMany
}

enum SerializationOption {
    case None
    case IncludeNullProperties
}

