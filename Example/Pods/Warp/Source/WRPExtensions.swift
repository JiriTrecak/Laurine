//
// WRPExtensions.swift
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
// MARK: - Extension - NSDictionary

extension NSMutableDictionary {
    
    
    /**
     *	Set an object for the property identified by a given key path to a given value.
     *
     *	@param	object                  The object for the property identified by _keyPath_.
     *	@param	keyPath                 A key path of the form _relationship.property_ (with one or more relationships): for example “department.name” or “department.manager.lastName.”
     */
    func setObject(_ object : AnyObject!, forKeyPath : String) {
        
        self.setObject(object, onObject : self, forKeyPath: forKeyPath, createIntermediates: true, replaceIntermediates: true);
    }
    
    
    /**
     *	Set an object for the property identified by a given key path to a given value, with optional parameters to control creation and replacement of intermediate objects.
     *
     *	@param	object                  The object for the property identified by _keyPath_.
     *	@param	keyPath                 A key path of the form _relationship.property_ (with one or more relationships): for example “department.name” or “department.manager.lastName.”
     *	@param	createIntermediates     Intermediate dictionaries defined within the key path that do not currently exist in the receiver are created.
     *	@param	replaceIntermediates    Intermediate objects encountered in the key path that are not a direct subclass of `NSDictionary` are replaced.
     */
    func setObject(_ object : AnyObject, onObject : AnyObject, forKeyPath : String, createIntermediates: Bool, replaceIntermediates: Bool) {
        
        // Path delimiter = .
        let pathDelimiter : String = "."
        
        // There is no keypath, just assign object
        if forKeyPath.range(of: pathDelimiter) == nil {
            onObject.set(object, forKey: forKeyPath);
        }
        
        // Create path components separated by delimiter (. by default) and get key for root object
        let pathComponents : Array<String> = forKeyPath.components(separatedBy: pathDelimiter);
        let rootKey : String = pathComponents[0];
        let replacementDictionary : NSMutableDictionary = NSMutableDictionary();
        
        // Store current state for further replacement
        var previousObject : AnyObject? = onObject;
        var previousReplacement : NSMutableDictionary = replacementDictionary;
        var reachedDictionaryLeaf : Bool = false;
        
        // Traverse through path from root to deepest level
        for path : String in pathComponents {
            
            let currentObject : AnyObject? = reachedDictionaryLeaf ? nil : (previousObject?.object(forKey: path) as? AnyObject);
            
            // Check if object already exists. If not, create new level, if allowed, or end
            if currentObject == nil {
                
                reachedDictionaryLeaf = true;
                if createIntermediates {
                    let newNode : NSMutableDictionary = NSMutableDictionary();
                    previousReplacement.setObject(newNode, forKey: path as NSCopying);
                    previousReplacement = newNode;
                } else {
                    return;
                }
                
                // If it does and it is dictionary, create mutable copy and assign new node there
            } else if currentObject is NSDictionary {
                
                let newNode : NSMutableDictionary = NSMutableDictionary(dictionary: currentObject as! [AnyHashable: Any]);
                previousReplacement.setObject(newNode, forKey: path as NSCopying);
                previousReplacement = newNode;
                
                // It exists but it is not NSDictionary, so we replace it, if allowed, or end
            } else {
                
                reachedDictionaryLeaf = true;
                if replaceIntermediates {
                    
                    let newNode : NSMutableDictionary = NSMutableDictionary();
                    previousReplacement.setObject(newNode, forKey: path as NSCopying);
                    previousReplacement = newNode;
                } else {
                    return;
                }
            }
            
            // Replace previous object with the new one
            previousObject = currentObject;
        }
        
        // Replace root object with newly created n-level dictionary
        replacementDictionary.setValue(object, forKeyPath: forKeyPath);
        onObject.set(replacementDictionary.object(forKey: rootKey), forKey: rootKey);
    }
}



extension NSRange {
    
    init(location:Int, length:Int) {
        
        self.location = location
        self.length = length
    }
    
    
    init(_ location:Int, _ length:Int) {
        
        self.location = location
        self.length = length
    }
    
    
    init(range:Range <Int>) {
        
        self.location = range.lowerBound
        self.length = range.upperBound - range.lowerBound
    }
    
    
    init(_ range:Range <Int>) {
        
        self.location = range.lowerBound
        self.length = range.upperBound - range.lowerBound
    }
    
    var startIndex:Int { get { return location } }
    var endIndex:Int { get { return location + length } }
    var asRange:CountableRange<Int> { get { return location..<location + length } }
    var isEmpty:Bool { get { return length == 0 } }
    
    
    func contains(_ index:Int) -> Bool {
        
        return index >= location && index < endIndex
    }
    
    
    func clamp(_ index:Int) -> Int {
        
        return max(self.startIndex, min(self.endIndex - 1, index))
    }
    
    
    func intersects(_ range:NSRange) -> Bool {
        
        return NSIntersectionRange(self, range).isEmpty == false
    }
    
    
    func intersection(_ range:NSRange) -> NSRange {
        
        return NSIntersectionRange(self, range)
    }
    
    
    func union(_ range:NSRange) -> NSRange {
        
        return NSUnionRange(self, range)
    }
    
}




