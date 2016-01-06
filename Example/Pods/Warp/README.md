[![Swift 2.1](https://img.shields.io/badge/Swift-2.1-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms OS X | iOS | tvos](https://img.shields.io/badge/Platforms-OS%20X%20%7C%20iOS-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)


# Warp

Insanely easy-to-use, extremely powerful swift object (+model mapper), that will make the creation of your data models a breeze. 

> Too tired to read? That is understandable. That is why I made this example. You will find it a little bit different from what you usually see - [check it out](https://github.com/JiriTrecak/Warp/tree/master/Example). Just download and run in XCode.



## Do I need it? (most likely)

There is one thing that most applications have in common - they are in **dire need of downloading raw data, and creating objects out of them**. What is NOT that common is that you need the whole database to store them - simply having them as objects in memory would be sufficient.

If you are like 95% people who just want to download and present data, and use them from memory, please continue, and enjoy. 

If you need whole databases with search, fetch control and more, then this is not for you (use Realm, or CD - though protocol support for them is also coming). In the meantime, check out my [other library](https://github.com/JiriTrecak/Laurine "Laurine Generator") - you will use that for sure. 

*Oh and if you liked this library and used it somewhere, drop me a message - what would you do with the time you just saved anyway?*


## Show me the good stuff

Enough talking, let's make our model. You start by extending any class to be child of `WRPObject`:


```swift
class User : WRPObject
```

And.. that is it. Your **User just gained superpowers** - it can **serialize, deserialize**, has the support of remote **properties and relationships and more sweetness**, that you will find below.

Let's imagine you have following object definition:

```swift
class User : WRPObject {

	// Properties
   var name : String!
   var email : String?
   var userId : Int = 0
   var active : Bool = true
   var createdAt : NSDate!
   var latitude : Double = 0
   var longitude : Double = 0
   
   // Relationships
   var messages : [Message] = []
}
```

In order for Warp to know how to get your data, you provide only two methods:

**Map Properties**

Warp can serialize almost any property you throw at it. You provide a description, Warp handles the rest. What Warp does differently than any other mapping system is that the **description covers all common scenarios that you can encounter**, no need for some insane hacks, closures.. And it reads like a book. 

```swift

func propertyMap() -> [WRPProperty] {
     return [
        // Bind remote string "name" to the same local "name", must exist
        WPRProperty(remote: "name", type: .String, optional: false),
        
        // Bind remote string "email_address" to local "email", optional
        WPRProperty(remote: "email_address", bindTo: "email", type: .String),
        
        // Bind remote Bool "active" to local "active"
        WPRProperty(remote: "active", type: .Bool),
        
        // Bind remote NSDate "created_at" to local "createdAt", must exist, specific date format
        WPRProperty(remote: "created_at", bindTo: "createdAt", type: .Date, optional: false, format: "yyyy-MM-dd")
     ]
}

```

This way, you can map all the properties - just combine initializer properies together. Now there are two **specific cases, that are very often needed**:

```swift

func propertyMap() -> [WRPProperty] {
     return [
         ...
         // When the data for objects are deeper than on first level, you can use dot notation to flatten it:
         // { "_geoloc" : { "lat" : 50, "lon" : 50 }} can be mapped as
         WPRProperty(remote: "_geoloc.lat", bindTo: "latitude", type: .Double),
         WPRProperty(remote: "_geoloc.lon", bindTo: "longitude", type: .Double),
         
         // Warp can also bind one property from multiple sources,  which is excellent when you have, for example, 
         // multiple databases, each with different key. Specify primary key
         // if there is chance that more of them can show at once and one has priority:
         WPRProperty(remotes: ["id", "objectId", "object_id"], primaryRemote: "objectId", bindTo: "userId", type: .Int),
     ]
}

``` 

**Map Relationships**

Objects are nice and all, but usually, when you fetch some data from your REST point, you would like to **create whole chain of objects**. 

The user can, for example, have messages that you get in one call. **Warp supports just that**, and as an icing on the cake, it can create relations between objects, even with inverse references:

```swift

func relationMap() -> [WRPRelation] {
     return [
        // We create relationship for messages:
        // Bind remote "messages" to local "messages". Each message has property "user",
        // which we mark as the inverse. We can have multiple messages, therefore .ToMany relationship is used. Each message has only one user,
        // therefore .ToOne is used in inverse.
        WPRRelation(remote: "messages", bindTo: "messages", inverseBindTo: "user", modelClass: Message.self, optional: true, relationType: .ToMany, inverseRelationType: .ToOne)
     ]
}
```

When we declare it like this, we get following chain of objects:

```swift
User {
   Configured properties
   messages : [
      message1 : Message,
      message2 : Message,
      message3 : Message
   ]
}
```

And since everything has inverse relationships, you can access user from message immediately: `user.messages.first().user`. This exactly mirrors relationship-database functionality, but without actual database. Sweet.

You can have an unlimited number of nested objects, with unlimited depth - just provide `relationMap()` for each of them. Then you can easily do something like `user.configuration.colors.first()!.configuration.user`, which is completely pointless, but serves as a good example.


## Usage

Now that you are able to describe any model structure as whole, let's put it to use and see how you can create objects. 

**Object creation**

```swift
// Fetch data from server using Alamofire, AFNetworking, Moya or any other
Alamofire.request(.GET, "/user", parameters: ["id": "my-user-id"])
         .responseJSON { response in

             if let JSON = response.result.value {
                 // This produces FULLY configured user, including messages
                 // print(user.messages.count) > '3'
                 let user = User(fromJSON: JSON)
             }
         }
```
**With just one line of code, everything was configured**. You can use `fromJSON:` or `fromDictionary:`, based on your needs. Support for `fromArray:` for creation of multiple objects at once is coming in the next version.

**Object updating**

Use `updateWithJSONString()` or `updateWithDictionary()` methods to update your already created objects - this will keep the properties that are not mentioned in your update data structure intact - and update the rest, including relationships.

**Serialization**

Sometimes, you would like to serialize your object, for storing or to update information on the server. Use following to achieve that:

```swift
// Create user
let user = User(fromDictionary: dict)

// Serialize it back
let dictionary = user.toDictionary()

// Serialize it, but exclude keys that are not interesting.
// Following with exclude messages on serialization
let dictionary = user.toDictionaryWithout(["messages"])

// You can also ONLY include keys that you want to have
let dictionary = user.toDictionaryWith(["email", "name"])

// You can also use WPRSerializationOption.IncludeNullProperties to serialize <null> where optionals are nil
 
```
Important note: objects are serialized using REMOTE keys, so serialization output will be the same as source data. 

## Installation

For now, please download /source and just append it to your project. I am working on CocoaPods / Carthage / SPM at the moment.

## Supported Features

Warp should suit most of the developers, because it covers all the basic stuff. That being said, there are still things missing to have full coverage. Here is the full list of features that will Warp contain once it is complete:

- [x] Property mapping
- [x] Relationship mapping
- [x] Nesting + dot notation mapping
- [x] Serialization
- [x] Deserialization
- [ ] Debugging
- [ ] 100% test coverage
- [ ] Pre / in / post generation closures
- [ ] Installators (Cocoapods, Carthage, SPM)
- [ ] Protocoled version, so it can be used as mapper for CoreData and Realm
- [ ] Tool for automatic generation of model, including network requests, from .json file

## Contribute
I will gladly accept Pull Requests (and I encourage you to do so). If you encounter any bug or you have an enhancement that you would like to see, please open an issue. Please make sure you target your PR against Development branch.

## Contact me


- [@JiriTrecak](https://twitter.com/@JiriTrecak "My twitter account")
- [jiritrecak@gmail.com](mailto:jiritrecak@gmail.com "My email") 

Or, if you would like to know me better, check out my portfolio.

- [jiritrecak.com](http://jiritrecak.com/ "My personal website") 

##Licence

The MIT License (MIT)

Copyright (c) 2016 Jiří Třečák

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.