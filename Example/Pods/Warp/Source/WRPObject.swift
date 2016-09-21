//
// WRPObject.swift
//
// Copyright (c) 2016 Jiri Trecak (http://jiritrecak.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Imports

import Foundation


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
//MARK: - Definitions


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Extension


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Protocols


// --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
// MARK: - Implementation

open class WRPObject : NSObject {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    override public init() {
        
        super.init()
        // No initialization required - nothing to fill object with
    }
    
    
    convenience public init(fromJSON : String) {
        
        if let jsonData : Data = fromJSON.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            do {
                let jsonObject : Any = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments)
                self.init(parameters: jsonObject as! NSDictionary)
            } catch let error as NSError {
                self.init(parameters: [:])
                print ("Error while parsing a json object: \(error.domain)")
            }
        } else {
            self.init(parameters: NSDictionary())
        }
    }
    
    
    convenience public init(fromDictionary : NSDictionary) {
        
        self.init(parameters: fromDictionary)
    }
    
    
    required public init(parameters : NSDictionary) {
        
        super.init()
        
        if self.debugInstantiate() {
            NSLog("parameters %@", parameters)
        }
        
        self.fillValues(parameters)
        self.processClosestRelationships(parameters)
    }
    
    required public init(parameters: NSDictionary, parentObject: WRPObject?) {
        
        super.init()
        
        if self.debugInstantiate() {
            NSLog("parameters %@", parameters)
        }
        
        self.fillValues(parameters)
        self.processClosestRelationships(parameters, parentObject: parentObject)
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - User overrides for data mapping
    
    open func propertyMap() -> [WRPProperty] {
        
        return []
    }
    
    
    open func relationMap() -> [WRPRelation] {
        
        return []
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    fileprivate func fillValues(_ parameters : NSDictionary) {
        
        for element : WRPProperty in self.propertyMap() {
            
            // Dot convention
            self.assignValueForElement(element, parameters: parameters)
        }
    }
    
    
    fileprivate func processClosestRelationships(_ parameters : NSDictionary) {
        
        self.processClosestRelationships(parameters, parentObject: nil)
    }
    
    
    fileprivate func processClosestRelationships(_ parameters : NSDictionary, parentObject : WRPObject?) {
        
        for element in self.relationMap() {
            self.assignDataObjectForElement(element, parameters: parameters, parentObject: parentObject)
        }
    }
    
    
    fileprivate func assignValueForElement(_ element : WRPProperty, parameters : NSDictionary) {
        
        switch element.elementDataType {
            
            // Handle string data type
        case .string:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.any, value: self.stringFromParameters(parameters, key: elementRemoteName) as AnyObject?,
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle boolean data type
        case .bool:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.any, value: self.boolFromParameters(parameters, key: elementRemoteName) as AnyObject?,
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle double data type
        case .double:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.double, value: self.doubleFromParameters(parameters, key: elementRemoteName) as AnyObject?,
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle float data type
        case .float:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.float, value: self.floatFromParameters(parameters, key: elementRemoteName) as AnyObject?,
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle int data type
        case .int:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.int, value: self.intFromParameters(parameters, key: elementRemoteName) as AnyObject?,
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle int data type
        case .number:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.any, value: self.numberFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle date data type
        case .date:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.any, value: self.dateFromParameters(parameters, key: elementRemoteName, format: element.format) as AnyObject?,
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle array data type
        case .array:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.any, value: self.arrayFromParameters(parameters, key: elementRemoteName) as AnyObject?,
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle dictionary data type
        case .dictionary:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.any, value: self.dictionaryFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
        }
    }
    
    
    fileprivate func assignDataObjectForElement(_ element : WRPRelation, parameters : NSDictionary, parentObject : WRPObject?) -> WRPObject? {
        
        switch element.relationshipType {
        case .toOne:
            return self.handleToOneRelationshipWithElement(element, parameters : parameters, parentObject: parentObject)
        case .toMany:
            self.handleToManyRelationshipWithElement(element, parameters : parameters, parentObject: parentObject)
        }
        
        return nil
    }
    
    
    fileprivate func handleToOneRelationshipWithElement(_ element : WRPRelation, parameters : NSDictionary, parentObject : WRPObject?) -> WRPObject? {
        
        if let objectData : AnyObject? = parameters.object(forKey: element.remoteName) as AnyObject?? {
            
            if objectData is NSDictionary {
                
                // Create object
                let dataObject = self.dataObjectFromParameters(objectData as! NSDictionary, objectType: element.className, parentObject: parentObject)
                
                // Set child object to self.property
                self.setValue(.any, value: dataObject, forKey: element.localName, optional: element.optional, temporaryOptional: false)
                
                // Set inverse relationship
                if (element.inverseRelationshipType == .toOne) {
                    dataObject.setValue(.any, value: self, forKey: element.inverseName, optional: true, temporaryOptional: true)
                    
                    // If the relationship is to .ToMany, then create data pack for that
                } else {
                    var objects : [WRPObject]? = [WRPObject]()
                    objects?.append(self)
                    dataObject.setValue(.any, value: objects as AnyObject?, forKey: element.inverseName, optional: true, temporaryOptional: true)
                }
                
                return dataObject
            } else if objectData is NSNull {
                
                // Set empty object to self.property
                self.setValue(.any, value: nil, forKey: element.localName, optional: element.optional, temporaryOptional: false)
                return nil
            }
        }
        
        return nil
    }
    
    
    fileprivate func handleToManyRelationshipWithElement(_ element : WRPRelation, parameters: NSDictionary, parentObject : WRPObject?) {
        
        if let objectDataPack : AnyObject? = parameters.object(forKey: element.remoteName) as AnyObject?? {
            
            // While the relationship is .ToMany, we can actually add it from single entry
            if objectDataPack is NSDictionary {
                
                // Always override local property, there is no inserting allowed
                var objects : [WRPObject]? = [WRPObject]()
                self.setValue(objects, forKey: element.localName)
                
                // Create object
                let dataObject = self.dataObjectFromParameters(objectDataPack as! NSDictionary, objectType: element.className, parentObject: parentObject)
                
                // Set inverse relationship
                if (element.inverseRelationshipType == .toOne) {
                    dataObject.setValue(.any, value: self, forKey: element.inverseName, optional: true, temporaryOptional: true)
                    
                    // If the relationship is to .ToMany, then create data pack for that
                } else {
                    var objects : [WRPObject]? = [WRPObject]()
                    objects?.append(self)
                    dataObject.setValue(.any, value: objects as AnyObject?, forKey: element.inverseName, optional: true, temporaryOptional: true)
                }
                
                // Append new data object to array
                objects!.append(dataObject)
                
                // Write new objects back
                self.setValue(objects, forKey: element.localName)
                
                // More objects in the same entry
            } else if objectDataPack is NSArray {
                
                // Always override local property, there is no inserting allowed
                var objects : [WRPObject]? = [WRPObject]()
                self.setValue(objects, forKey: element.localName)
                
                // Fill that property with data
                for objectData in (objectDataPack as! NSArray) {
                    
                    // Create object
                    let dataObject = self.dataObjectFromParameters(objectData as! NSDictionary, objectType: element.className, parentObject: parentObject)
                    
                    // Assign inverse relationship
                    if (element.inverseRelationshipType == .toOne) {
                        dataObject.setValue(.any, value: self, forKey: element.inverseName, optional: true, temporaryOptional: true)
                        
                        // If the relationship is to .ToMany, then create data pack for that
                    } else {
                        var objects : [WRPObject]? = [WRPObject]()
                        objects?.append(self)
                        dataObject.setValue(.any, value: objects as AnyObject?, forKey: element.inverseName, optional: true, temporaryOptional: true)
                    }
                    
                    // Append new data
                    objects!.append(dataObject)
                }
                
                // Write new objects back
                self.setValue(objects, forKey: element.localName)
                
                // Null encountered, null the output
            } else if objectDataPack is NSNull {
                
                self.setValue(nil, forKey: element.localName)
            }
        }
    }
    
    
    fileprivate func setValue(_ type: WRPPropertyAssignement, value : AnyObject?, forKey key: String, optional: Bool, temporaryOptional: Bool) -> Bool {
        
        if ((optional || temporaryOptional) && value == nil) {
            return false
        }
        
        if type == .any {
            self.setValue(value, forKey: key)
        } else if type == .double {
            if value is Double {
                self.setValue(value as! NSNumber, forKey: key)
            } else if value is NSNumber {
                self.setValue(value?.doubleValue, forKey: key)
            } else {
                self.setValue(nil, forKey: key)
            }
        } else if type == .int {
            if value is Int {
                self.setValue(value as! NSNumber, forKey: key)
            } else if value is NSNumber {
                self.setValue((value as! NSNumber).intValue, forKey: key)
            } else {
                self.setValue(nil, forKey: key)
            }
        } else if type == .float {
            if value is Float {
                self.setValue(value as! NSNumber, forKey: key)
            } else if value is NSNumber {
                self.setValue(value?.floatValue, forKey: key)
            } else {
                self.setValue(nil, forKey: key)
            }
        }
        return true
    }
    
    
    fileprivate func setDictionary(_ value : Dictionary<AnyKey, AnyKey>?, forKey: String, optional: Bool, temporaryOptional: Bool) -> Bool {
        
        if ((optional || temporaryOptional) && value == nil) {
            return false
        }
        
        self.setValue((value as AnyObject), forKey: forKey)
        return true
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Variable creation
    
    fileprivate func stringFromParameters(_ parameters : NSDictionary, key : String) -> String? {
        
        if let value : NSString = parameters.value(forKeyPath: key) as? NSString {
            return value as String
        }
        
        return nil
    }
    
    fileprivate func numberFromParameters(_ parameters : NSDictionary, key : String) -> NSNumber? {
        
        if let value : NSNumber = parameters.value(forKeyPath: key) as? NSNumber {
            return value as NSNumber
        }
        
        return nil
    }
    
    
    fileprivate func intFromParameters(_ parameters : NSDictionary, key : String) -> Int? {
        
        if let value : NSNumber = parameters.value(forKeyPath: key) as? NSNumber {
            
            return Int(value)
        }
        
        return nil
    }
    
    
    fileprivate func doubleFromParameters(_ parameters : NSDictionary, key : String) -> Double? {
        
        if let value : NSNumber = parameters.value(forKeyPath: key) as? NSNumber {
            return Double(value)
        }
        
        return nil
    }
    
    
    fileprivate func floatFromParameters(_ parameters : NSDictionary, key : String) -> Float? {
        
        if let value : NSNumber = parameters.value(forKeyPath: key) as? NSNumber {
            return Float(value)
        }
        
        return nil
    }
    
    
    fileprivate func boolFromParameters(_ parameters : NSDictionary, key : String) -> Bool? {
        
        if let value : NSNumber = parameters.value(forKeyPath: key) as? NSNumber {
            return Bool(value)
        }
        
        return nil
    }
    
    
    fileprivate func dateFromParameters(_ parameters : NSDictionary, key : String, format : String?) -> Date? {
        
        if let value : String = parameters.value(forKeyPath: key) as? String {
            
            // Create date formatter
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            
            return dateFormatter.date(from: value)
        }
        
        return nil
    }
    
    
    fileprivate func arrayFromParameters(_ parameters : NSDictionary, key : String) -> Array<AnyObject>? {
        
        if let value : Array = parameters.value(forKeyPath: key) as? Array<AnyObject> {
            return value
        }
        
        return nil
    }
    
    
    fileprivate func dictionaryFromParameters(_ parameters : NSDictionary, key : String) -> NSDictionary? {
        
        if let value : NSDictionary = parameters.value(forKeyPath: key) as? NSDictionary {
            return value
        }
        
        return nil
    }
    
    
    fileprivate func dataObjectFromParameters(_ parameters: NSDictionary, objectType : WRPObject.Type, parentObject: WRPObject?) -> WRPObject {
        
        let dataObject : WRPObject = objectType.init(parameters: parameters, parentObject: parentObject)
        return dataObject
    }
    
    
    fileprivate func valueForKey(_ key: String, optional : Bool) -> AnyObject? {
        
        return nil
    }
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Object serialization
    
    open func toDictionary() -> NSDictionary {
        
        return self.toDictionaryWithSerializationOption(.none, without: [])
    }
    
    
    open func toDictionaryWithout(_ exclude : [String]) -> NSDictionary {
        
        return self.toDictionaryWithSerializationOption(.none, without: exclude)
    }
    
    
    open func toDictionaryWithOnly(_ include : [String]) -> NSDictionary {
        
        print("toDictionaryWithOnly(:) is not yet supported. Expected version: 0.2")
        return NSDictionary()
        // return self.toDictionaryWithSerializationOption(.None, with: include)
    }
    
    
    open func toDictionaryWithSerializationOption(_ option : WRPSerializationOption) -> NSDictionary {
        
        return self.toDictionaryWithSerializationOption(option, without: [])
    }
    
    
    open func toDictionaryWithSerializationOption(_ option: WRPSerializationOption, without : [String]) -> NSDictionary {
        
        // Create output
        let outputParams : NSMutableDictionary = NSMutableDictionary()
        
        // Get mapping parameters, go through all of them and serialize them into output
        for element : WRPProperty in self.propertyMap() {
            
            // Skip element if it should be excluded
            if self.keyPathShouldBeExcluded(element.masterRemoteName, exclusionArray: without) {
                continue
            }
            
            // Get actual value of property
            let actualValue : AnyObject? = self.value(forKey: element.localName) as AnyObject?
            
            // Check for nil, if it is nil, we add <NSNull> object instead of value
            if (actualValue == nil) {
                if (option == WRPSerializationOption.includeNullProperties) {
                    outputParams.setObject(NSNull(), forKeyPath: element.remoteNames.first!)
                }
            } else {
                // Otherwise add value itself
                outputParams.setObject(self.valueOfElement(element, value: actualValue!), forKeyPath: element.masterRemoteName)
            }
        }
        
        // Now get all relationships and call .toDictionary above all of them
        for element : WRPRelation in self.relationMap() {
            
            if self.keyPathShouldBeExcluded(element.remoteName, exclusionArray: without) {
                continue
            }
            
            if (element.relationshipType == .toMany) {
                
                // Get data pack
                if let actualValues = self.value(forKey: element.localName) as? [WRPObject] {
                    
                    // Create data pack if exists, get all values, serialize those, and assign all of them
                    var outputArray = [NSDictionary]()
                    for actualValue : WRPObject in actualValues {
                        outputArray.append(actualValue.toDictionaryWithSerializationOption(option, without: self.keyPathForChildWithElement(element, parentRules: without)))
                    }
                    
                    // Add all intros back
                    outputParams.setObject(outputArray as AnyObject!, forKeyPath: element.remoteName)
                } else {
                    
                    // Add null value for relationship if needed
                    if (option == WRPSerializationOption.includeNullProperties) {
                        outputParams.setObject(NSNull(), forKey: element.remoteName as NSCopying)
                    }
                }
            } else {
                
                // Get actual value of property
                let actualValue : WRPObject? = self.value(forKey: element.localName) as? WRPObject
                
                // Check for nil, if it is nil, we add <NSNull> object instead of value
                if (actualValue == nil) {
                    if (option == WRPSerializationOption.includeNullProperties) {
                        outputParams.setObject(NSNull(), forKey: element.remoteName as NSCopying)
                    }
                } else {
                    // Otherwise add value itself
                    outputParams.setObject(actualValue!.toDictionaryWithSerializationOption(option, without: self.keyPathForChildWithElement(element, parentRules: without)), forKey: element.remoteName as NSCopying)
                }
            }
        }
        
        return outputParams
    }
    
    
    fileprivate func keyPathForChildWithElement(_ element : WRPRelation, parentRules : [String]) -> [String] {
        
        if (parentRules.count > 0) {
            
            var newExlusionRules = [String]()
            
            for parentRule : String in parentRules {
                
                let objcString: NSString = parentRule as NSString
                let range : NSRange = objcString.range(of: String(format: "%@.", element.remoteName))
                if range.location != NSNotFound && range.location == 0 {
                    let newPath = objcString.replacingCharacters(in: range, with: "")
                    newExlusionRules.append(newPath as String)
                }
            }
            return newExlusionRules
        } else {
            return []
        }
    }
    
    
    fileprivate func keyPathShouldBeExcluded(_ valueKeyPath : String, exclusionArray : [String]) -> Bool {
        
        let objcString: NSString = valueKeyPath as NSString
        
        for exclustionKeyPath : String in exclusionArray {
            let range : NSRange = objcString.range(of: exclustionKeyPath)
            if range.location != NSNotFound && range.location == 0 {
                return true
            }
        }
        
        return false
    }
    
    
    fileprivate func valueOfElement(_ element: WRPProperty, value: AnyObject) -> AnyObject {
        
        switch element.elementDataType {
        case .int:
            return NSNumber(value: value as! Int as Int)
        case .float:
            return NSNumber(value: value as! Float as Float)
        case .double:
            return NSNumber(value: value as! Double as Double)
        case .bool:
            return NSNumber(value: value as! Bool as Bool)
        case .date:
            let formatter : DateFormatter = DateFormatter()
            formatter.dateFormat = element.format!
            return formatter.string(from: value as! Date) as AnyObject
        default:
            return value
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Convenience
    
    open func updateWithJSONString(_ jsonString : String) -> Bool {
        
        // Try to parse json data
        if let jsonData : Data = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: true) {
            
            // If it worked, update data of current object (dictionary is expected on root level)
            do {
                let jsonObject : Any? = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments)
                self.fillValues(jsonObject as! NSDictionary)
                self.processClosestRelationships(jsonObject as! NSDictionary)
                return true
            } catch let error as NSError {
                print ("Error while parsing a json object: \(error.domain)")
            }
        }
        
        // Could not process json string
        return false
    }
    
    
    open func updateWithDictionary(_ objectData : NSDictionary) -> Bool {
        
        // Update data of current object
        self.fillValues(objectData)
        self.processClosestRelationships(objectData)
        
        return true
    }
    
    
    open func excludeOnSerialization() -> [String] {
        
        return []
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Debug
    
    open func debugInstantiate() -> Bool {
        
        return false
    }
}













