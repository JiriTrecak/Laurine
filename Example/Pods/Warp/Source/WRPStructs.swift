//
// WRPStructs.swift
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
//MARK: - Structures

public struct WRPProperty {
    
    // All remote names that can be used as source of property content
    var remoteNames : [String]
    
    // Remote name that will be used for rebuilding of the value
    var masterRemoteName : String
    
    // Local property name
    var localName : String
    
    // Data type of the property
    var elementDataType : WRPPropertyType
    var optional : Bool = true
    var format : String?
    
    public init(remote : String, bindTo : String, type : WRPPropertyType) {
        
        self.remoteNames = [remote]
        self.masterRemoteName = remote
        self.localName = bindTo
        self.elementDataType = type
    }
    
    public init(remote : String, type : WRPPropertyType) {
        
        self.remoteNames = [remote]
        self.masterRemoteName = remote
        self.localName = remote
        self.elementDataType = type
    }
    
    
    public init(remote : String, type : WRPPropertyType, optional : Bool) {
        
        self.optional = optional
        self.remoteNames = [remote]
        self.masterRemoteName = remote
        self.localName = remote
        self.elementDataType = type
    }
    
    
    public init(remote : String, bindTo : String, type : WRPPropertyType, optional : Bool) {
        
        self.remoteNames = [remote]
        self.masterRemoteName = remote
        self.localName = bindTo
        self.elementDataType = type
        self.optional = optional
        self.format = nil
    }
    
    
    public init(remote : String, bindTo : String, type : WRPPropertyType, optional : Bool, format : String?) {
        
        self.remoteNames = [remote]
        self.masterRemoteName = remote
        self.localName = bindTo
        self.elementDataType = type
        self.optional = optional
        self.format = format
    }
    
    
    public init(remotes : [String], primaryRemote : String, bindTo : String, type : WRPPropertyType) {
        
        self.remoteNames = remotes
        self.masterRemoteName = primaryRemote
        self.localName = bindTo
        self.elementDataType = type
        self.optional = false
        
        // Remote names cannot be null - if there is such case, just force masterRemoteName to be remote name
        if self.remoteNames.count == 0 {
            self.remoteNames.append(self.masterRemoteName)
        }
    }
    
    
    public init(remotes : [String], primaryRemote : String, bindTo : String, type : WRPPropertyType, format : String?) {
        
        self.remoteNames = remotes
        self.masterRemoteName = primaryRemote
        self.localName = bindTo
        self.elementDataType = type
        self.optional = false
        self.format = format
        
        // Remote names cannot be null - if there is such case, just force masterRemoteName to be remote name
        if self.remoteNames.count == 0 {
            self.remoteNames.append(self.masterRemoteName)
        }
    }
}


public struct WRPRelation {
    
    var remoteName : String
    var localName : String
    var className : WRPObject.Type
    var inverseName : String
    var relationshipType : WRPRelationType
    var inverseRelationshipType : WRPRelationType
    var optional : Bool = true
    
    public init(remote : String, bindTo : String, inverseBindTo : String, modelClass : WRPObject.Type, optional : Bool, relationType : WRPRelationType, inverseRelationType : WRPRelationType) {
        
        self.remoteName = remote
        self.localName = bindTo
        self.inverseName = inverseBindTo
        self.className = modelClass
        self.relationshipType = relationType
        self.inverseRelationshipType = inverseRelationType
        self.optional = optional
    }
}


struct AnyKey: Hashable {
    
    fileprivate let underlying: Any
    fileprivate let hashValueFunc: () -> Int
    fileprivate let equalityFunc: (Any) -> Bool
    
    init<T: Hashable>(_ key: T) {
        // Capture the key's hashability and equatability using closures.
        // The Key shares the hash of the underlying value.
        underlying = key
        hashValueFunc = { key.hashValue }
        
        // The Key is equal to a Key of the same underlying type,
        // whose underlying value is "==" to ours.
        equalityFunc = {
            if let other = $0 as? T {
                return key == other
            }
            return false
        }
    }
    
    var hashValue: Int { return hashValueFunc() }
}


func ==(x: AnyKey, y: AnyKey) -> Bool {
    return x.equalityFunc(y.underlying)
}



