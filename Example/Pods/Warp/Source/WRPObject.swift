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

public class WRPObject : NSObject {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Setup
    
    override public init() {
        
        super.init()
        // No initialization required - nothing to fill object with
    }
    
    
    convenience public init(fromJSON : String) {
        
        if let jsonData : NSData = fromJSON.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            do {
                let jsonObject : AnyObject? = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments)
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
    
    public func propertyMap() -> [WRPProperty] {
        
        return []
    }
    
    
    public func relationMap() -> [WRPRelation] {
        
        return []
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Private
    
    private func fillValues(parameters : NSDictionary) {
        
        for element : WRPProperty in self.propertyMap() {
            
            // Dot convention
            self.assignValueForElement(element, parameters: parameters)
        }
    }
    
    
    private func processClosestRelationships(parameters : NSDictionary) {
        
        self.processClosestRelationships(parameters, parentObject: nil)
    }
    
    
    private func processClosestRelationships(parameters : NSDictionary, parentObject : WRPObject?) {
        
        for element in self.relationMap() {
            self.assignDataObjectForElement(element, parameters: parameters, parentObject: parentObject)
        }
    }
    
    
    private func assignValueForElement(element : WRPProperty, parameters : NSDictionary) {
        
        switch element.elementDataType {
            
            // Handle string data type
        case .String:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Any, value: self.stringFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle boolean data type
        case .Bool:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Any, value: self.boolFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle double data type
        case .Double:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Double, value: self.doubleFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle float data type
        case .Float:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Float, value: self.floatFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle int data type
        case .Int:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Int, value: self.intFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle int data type
        case .Number:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Any, value: self.numberFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle date data type
        case .Date:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Any, value: self.dateFromParameters(parameters, key: elementRemoteName, format: element.format),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle array data type
        case .Array:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Any, value: self.arrayFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
            
            // Handle dictionary data type
        case .Dictionary:
            for elementRemoteName in element.remoteNames {
                if (self.setValue(.Any, value: self.dictionaryFromParameters(parameters, key: elementRemoteName),
                    forKey: element.localName, optional: element.optional, temporaryOptional: element.remoteNames.count > 1)) { break }
            }
        }
    }
    
    
    private func assignDataObjectForElement(element : WRPRelation, parameters : NSDictionary, parentObject : WRPObject?) -> WRPObject? {
        
        switch element.relationshipType {
        case .ToOne:
            return self.handleToOneRelationshipWithElement(element, parameters : parameters, parentObject: parentObject)
        case .ToMany:
            self.handleToManyRelationshipWithElement(element, parameters : parameters, parentObject: parentObject)
        }
        
        return nil
    }
    
    
    private func handleToOneRelationshipWithElement(element : WRPRelation, parameters : NSDictionary, parentObject : WRPObject?) -> WRPObject? {
        
        if let objectData : AnyObject? = parameters.objectForKey(element.remoteName) {
            
            if objectData is NSDictionary {
                
                // Create object
                let dataObject = self.dataObjectFromParameters(objectData as! NSDictionary, objectType: element.className, parentObject: parentObject)
                
                // Set child object to self.property
                self.setValue(.Any, value: dataObject, forKey: element.localName, optional: element.optional, temporaryOptional: false)
                
                // Set inverse relationship
                if (element.inverseRelationshipType == .ToOne) {
                    dataObject.setValue(.Any, value: self, forKey: element.inverseName, optional: true, temporaryOptional: true)
                    
                    // If the relationship is to .ToMany, then create data pack for that
                } else {
                    var objects : [WRPObject]? = [WRPObject]()
                    objects?.append(self)
                    dataObject.setValue(.Any, value: objects, forKey: element.inverseName, optional: true, temporaryOptional: true)
                }
                
                return dataObject
            } else if objectData is NSNull {
                
                // Set empty object to self.property
                self.setValue(.Any, value: nil, forKey: element.localName, optional: element.optional, temporaryOptional: false)
                return nil
            }
        }
        
        return nil
    }
    
    
    private func handleToManyRelationshipWithElement(element : WRPRelation, parameters: NSDictionary, parentObject : WRPObject?) {
        
        if let objectDataPack : AnyObject? = parameters.objectForKey(element.remoteName) {
            
            // While the relationship is .ToMany, we can actually add it from single entry
            if objectDataPack is NSDictionary {
                
                // Always override local property, there is no inserting allowed
                var objects : [WRPObject]? = [WRPObject]()
                self.setValue(objects, forKey: element.localName)
                
                // Create object
                let dataObject = self.dataObjectFromParameters(objectDataPack as! NSDictionary, objectType: element.className, parentObject: parentObject)
                
                // Set inverse relationship
                if (element.inverseRelationshipType == .ToOne) {
                    dataObject.setValue(.Any, value: self, forKey: element.inverseName, optional: true, temporaryOptional: true)
                    
                    // If the relationship is to .ToMany, then create data pack for that
                } else {
                    var objects : [WRPObject]? = [WRPObject]()
                    objects?.append(self)
                    dataObject.setValue(.Any, value: objects, forKey: element.inverseName, optional: true, temporaryOptional: true)
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
                    if (element.inverseRelationshipType == .ToOne) {
                        dataObject.setValue(.Any, value: self, forKey: element.inverseName, optional: true, temporaryOptional: true)
                        
                        // If the relationship is to .ToMany, then create data pack for that
                    } else {
                        var objects : [WRPObject]? = [WRPObject]()
                        objects?.append(self)
                        dataObject.setValue(.Any, value: objects, forKey: element.inverseName, optional: true, temporaryOptional: true)
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
    
    
    private func setValue(type: WRPPropertyAssignement, value : AnyObject?, forKey key: String, optional: Bool, temporaryOptional: Bool) -> Bool {
        
        if ((optional || temporaryOptional) && value == nil) {
            return false
        }
        
        if type == .Any {
            self.setValue(value, forKey: key)
        } else if type == .Double {
            if value is Double {
                self.setValue(value as! NSNumber, forKey: key)
            } else if value is NSNumber {
                self.setValue(value?.doubleValue, forKey: key)
            } else {
                self.setValue(nil, forKey: key)
            }
        } else if type == .Int {
            if value is Int {
                self.setValue(value as! NSNumber, forKey: key)
            } else if value is NSNumber {
                self.setValue(value?.integerValue, forKey: key)
            } else {
                self.setValue(nil, forKey: key)
            }
        } else if type == .Float {
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
    
    
    private func setDictionary(value : Dictionary<AnyKey, AnyKey>?, forKey: String, optional: Bool, temporaryOptional: Bool) -> Bool {
        
        if ((optional || temporaryOptional) && value == nil) {
            return false
        }
        
        self.setValue((value as! AnyObject), forKey: forKey)
        return true
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Variable creation
    
    private func stringFromParameters(parameters : NSDictionary, key : String) -> String? {
        
        if let value : NSString = parameters.valueForKeyPath(key) as? NSString {
            return value as String
        }
        
        return nil
    }
    
    private func numberFromParameters(parameters : NSDictionary, key : String) -> NSNumber? {
        
        if let value : NSNumber = parameters.valueForKeyPath(key) as? NSNumber {
            return value as NSNumber
        }
        
        return nil
    }
    
    
    private func intFromParameters(parameters : NSDictionary, key : String) -> Int? {
        
        if let value : NSNumber = parameters.valueForKeyPath(key) as? NSNumber {
            
            return Int(value)
        }
        
        return nil
    }
    
    
    private func doubleFromParameters(parameters : NSDictionary, key : String) -> Double? {
        
        if let value : NSNumber = parameters.valueForKeyPath(key) as? NSNumber {
            return Double(value)
        }
        
        return nil
    }
    
    
    private func floatFromParameters(parameters : NSDictionary, key : String) -> Float? {
        
        if let value : NSNumber = parameters.valueForKeyPath(key) as? NSNumber {
            return Float(value)
        }
        
        return nil
    }
    
    
    private func boolFromParameters(parameters : NSDictionary, key : String) -> Bool? {
        
        if let value : NSNumber = parameters.valueForKeyPath(key) as? NSNumber {
            return Bool(value)
        }
        
        return nil
    }
    
    
    private func dateFromParameters(parameters : NSDictionary, key : String, format : String?) -> NSDate? {
        
        if let value : String = parameters.valueForKeyPath(key) as? String {
            
            // Create date formatter
            let dateFormatter : NSDateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = format
            
            return dateFormatter.dateFromString(value)
        }
        
        return nil
    }
    
    
    private func arrayFromParameters(parameters : NSDictionary, key : String) -> Array<AnyObject>? {
        
        if let value : Array = parameters.valueForKeyPath(key) as? Array<AnyObject> {
            return value
        }
        
        return nil
    }
    
    
    private func dictionaryFromParameters(parameters : NSDictionary, key : String) -> NSDictionary? {
        
        if let value : NSDictionary = parameters.valueForKeyPath(key) as? NSDictionary {
            return value
        }
        
        return nil
    }
    
    
    private func dataObjectFromParameters(parameters: NSDictionary, objectType : WRPObject.Type, parentObject: WRPObject?) -> WRPObject {
        
        let dataObject : WRPObject = objectType.init(parameters: parameters, parentObject: parentObject)
        return dataObject
    }
    
    
    private func valueForKey(key: String, optional : Bool) -> AnyObject? {
        
        return nil
    }
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Object serialization
    
    public func toDictionary() -> NSDictionary {
        
        return self.toDictionaryWithSerializationOption(.None, without: [])
    }
    
    
    public func toDictionaryWithout(exclude : [String]) -> NSDictionary {
        
        return self.toDictionaryWithSerializationOption(.None, without: exclude)
    }
    
    
    public func toDictionaryWithOnly(include : [String]) -> NSDictionary {
        
        print("toDictionaryWithOnly(:) is not yet supported. Expected version: 0.2")
        return NSDictionary()
        // return self.toDictionaryWithSerializationOption(.None, with: include)
    }
    
    
    public func toDictionaryWithSerializationOption(option : WRPSerializationOption) -> NSDictionary {
        
        return self.toDictionaryWithSerializationOption(option, without: [])
    }
    
    
    public func toDictionaryWithSerializationOption(option: WRPSerializationOption, without : [String]) -> NSDictionary {
        
        // Create output
        let outputParams : NSMutableDictionary = NSMutableDictionary()
        
        // Get mapping parameters, go through all of them and serialize them into output
        for element : WRPProperty in self.propertyMap() {
            
            // Skip element if it should be excluded
            if self.keyPathShouldBeExcluded(element.masterRemoteName, exclusionArray: without) {
                continue
            }
            
            // Get actual value of property
            let actualValue : AnyObject? = self.valueForKey(element.localName)
            
            // Check for nil, if it is nil, we add <NSNull> object instead of value
            if (actualValue == nil) {
                if (option == WRPSerializationOption.IncludeNullProperties) {
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
            
            if (element.relationshipType == .ToMany) {
                
                // Get data pack
                if let actualValues = self.valueForKey(element.localName) as? [WRPObject] {
                    
                    // Create data pack if exists, get all values, serialize those, and assign all of them
                    var outputArray = [NSDictionary]()
                    for actualValue : WRPObject in actualValues {
                        outputArray.append(actualValue.toDictionaryWithSerializationOption(option, without: self.keyPathForChildWithElement(element, parentRules: without)))
                    }
                    
                    // Add all intros back
                    outputParams.setObject(outputArray, forKeyPath: element.remoteName)
                } else {
                    
                    // Add null value for relationship if needed
                    if (option == WRPSerializationOption.IncludeNullProperties) {
                        outputParams.setObject(NSNull(), forKey: element.remoteName)
                    }
                }
            } else {
                
                // Get actual value of property
                let actualValue : WRPObject? = self.valueForKey(element.localName) as? WRPObject
                
                // Check for nil, if it is nil, we add <NSNull> object instead of value
                if (actualValue == nil) {
                    if (option == WRPSerializationOption.IncludeNullProperties) {
                        outputParams.setObject(NSNull(), forKey: element.remoteName)
                    }
                } else {
                    // Otherwise add value itself
                    outputParams.setObject(actualValue!.toDictionaryWithSerializationOption(option, without: self.keyPathForChildWithElement(element, parentRules: without)), forKey: element.remoteName)
                }
            }
        }
        
        return outputParams
    }
    
    
    private func keyPathForChildWithElement(element : WRPRelation, parentRules : [String]) -> [String] {
        
        if (parentRules.count > 0) {
            
            var newExlusionRules = [String]()
            
            for parentRule : String in parentRules {
                
                let objcString: NSString = parentRule as NSString
                let range : NSRange = objcString.rangeOfString(String(format: "%@.", element.remoteName))
                if range.location != NSNotFound && range.location == 0 {
                    let newPath = objcString.stringByReplacingCharactersInRange(range, withString: "")
                    newExlusionRules.append(newPath as String)
                }
            }
            return newExlusionRules
        } else {
            return []
        }
    }
    
    
    private func keyPathShouldBeExcluded(valueKeyPath : String, exclusionArray : [String]) -> Bool {
        
        let objcString: NSString = valueKeyPath as NSString
        
        for exclustionKeyPath : String in exclusionArray {
            let range : NSRange = objcString.rangeOfString(exclustionKeyPath)
            if range.location != NSNotFound && range.location == 0 {
                return true
            }
        }
        
        return false
    }
    
    
    private func valueOfElement(element: WRPProperty, value: AnyObject) -> AnyObject {
        
        switch element.elementDataType {
        case .Int:
            return NSNumber(integer: value as! Int)
        case .Float:
            return NSNumber(float: value as! Float)
        case .Double:
            return NSNumber(double: value as! Double)
        case .Bool:
            return NSNumber(bool: value as! Bool)
        case .Date:
            let formatter : NSDateFormatter = NSDateFormatter()
            formatter.dateFormat = element.format!
            return formatter.stringFromDate(value as! NSDate)
        default:
            return value
        }
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Convenience
    
    public func updateWithJSONString(jsonString : String) -> Bool {
        
        // Try to parse json data
        if let jsonData : NSData = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            
            // If it worked, update data of current object (dictionary is expected on root level)
            do {
                let jsonObject : AnyObject? = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments)
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
    
    
    public func updateWithDictionary(objectData : NSDictionary) -> Bool {
        
        // Update data of current object
        self.fillValues(objectData)
        self.processClosestRelationships(objectData)
        
        return true
    }
    
    
    public func excludeOnSerialization() -> [String] {
        
        return []
    }
    
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Debug
    
    public func debugInstantiate() -> Bool {
        
        return false
    }
}













