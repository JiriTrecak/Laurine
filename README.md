# Laurine

**Localization code generator** written (with love) for Swift, **intended to end the constant problems** that localizations present for developers.


## Do I need it? (yes you do)

Laurine is clever Swift script that scans your localization file and generates actual structured code out of it, therefore making the usage of localization strings much easier. 

What is so good about it is that by removing magical strings from your code, compiler can actually tell you that you forgot to make changes (and where), if your localization file changes. It also introduces type checks for strings that contain runtime parameters (%@, %d etc.).

Laurine requires Swift to run and can be used from command line as well as build script (recommended). Laurine uses [CommandLine](https://github.com/jatoben/CommandLine "CommandLine Swift Tool") to get configuration options from you, and due to current limitations of Swift, its code is embedded within Laurine itself.


## Generated Structures

Once you run Laurine, the output will be one .swift file containing `Localizations` structure. From this single structure, you will get access to all the sweetness:

**Variables**

For each string that does not contain any special characters, static var is generated, containing CamelCase name, actual localization code and base comment that contains base translation, for better orientation. Following:

```swift
"PROFILE_PHONE_NUMBER" = "Your phone number!"
```
can be then used like this:

```swift
self.labelToLocalize.text = Localizations.ProfilePhoneNumber
```
in XCode, autocomplete is actually, for once, really helpful! Madness.

![Image : XCode help for variables](https://github.com/JiriTrecak/Laurine/blob/master/Help/help-1.png?raw=true "Xcode autocomplete")

**Methods**

If your localization string contains runtime variables, it is generated as method instead. Laurine detects its data type and generates proper method header from that definition. There is no limit to how many of them you have. Following:

```swift
"PROFILE_INFO" = "I am %@, I am %d years old and %.2fm in height!"
```
can be then used like this:

```swift
self.labelToLocalize.text = Localizations.ProfilePhoneNumber
```
in XCode, autocomplete is actually, for once, really helpful! Madness.

![Image : XCode help for methods](https://github.com/JiriTrecak/Laurine/blob/master/Help/help-2.png?raw=true "Xcode autocomplete")


## Nested structures
TBD - IMPORTANT!

## Usage
TBD 

## Installation
TBD

## Contribute
I will gladly accept Pull Requests that you do, (and I encourage you to do so). If you have any bug or enhnacement that I could do, please open issue and describe it.

I'd also like to thank you to Marcin Krzyżanowski for his [Natalie Generator](https://github.com/krzyzanowskim/Natalie), which heavily inspired this project.

## Contact Me!

Jiří Třečák

- [@JiriTrecak](https://twitter.com/@JiriTrecak "My twitter account")
- [jiritrecak.com](http://jiritrecak.com/ "My personal website") 

##Licence

The MIT License (MIT)

Copyright (c) 2015 Jiří Třečák

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.