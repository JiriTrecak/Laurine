[![Swift 2.1](https://img.shields.io/badge/Swift-2.1-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms OS X | iOS | tvos](https://img.shields.io/badge/Platforms-OS%20X%20%7C%20iOS-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)

# Laurine

**Localization code generator** written (with love) for Swift, **intended to end the constant problems** that localizations present for developers.


## Do I need it? (yes you do)

Laurine is a clever Swift script that scans your localization file and generates actual structured code out of it (in both ObjC or Swift, your call), thereby making the usage of localization strings much easier. 

The great thing is that by removing magical strings from your code, the compiler can actually tell you when you forget to make changes (and where), if your localization file changes. It also introduces type checking for strings that contain runtime format specifiers (`%@`, `%d` etc.).

Laurine requires Swift to run and can be used from the command line as well as from a build script (recommended). Laurine uses [CommandLine](https://github.com/jatoben/CommandLine "CommandLine Swift Tool") to parse command line arguemnts: no extra configuration is needed.


## Generated Structures

Once you run Laurine, the output will be one .swift or .m file containing a `Localizations` structure / object. From this single access point, you will get access to all the sweetness:

**Variables**

For each string that does not contain any special characters, a property is generated. For example:

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

If your localization string has runtime format specifiers, it is generated as a method instead. Laurine detects the format specifiers and generates a proper method header from that definition. There is no limit to how many of them you have. 

For example:

```swift
"PROFILE_INFO" = "I am %@, I am %d years old and %.2fm in height!"
```
can be then used like this:

```swift
self.labelToLocalize.text = Localizations.ProfileInfo("Jiri", 25, 1.75)
```
Once again, Xcode autocomplete for the win! Insanity.

![Image : XCode help for methods](https://github.com/JiriTrecak/Laurine/blob/master/Help/help-2.png?raw=true "Xcode autocomplete")

**Objective-C support**

Objective-C is now supported. Because of the way the code is generated, you can write just the same code as you would in Swift, using dot notation to access each next element. For example:

```objective-c
NSString *text = Localizations.ProfileInfo("Jiri", 25, 1.75)
```

This produces exactly the same result as you would get in Swift and is recommended. 

## Nested Structures

It is best practice to make the keys as descriptive and structured as possible. Laurine takes advantage of that to generate nested structures rather than overly long key names. For example:

```swift
"PROFILE-NAVIGATION_BAR-ITEMS-DONE" = "Done" // -c -d -
"PROFILE.NAVIGATION_BAR.ITEMS.DONE" = "Done" // -c -d .
```

Is actually converted to:

```swift
self.labelToLocalize.text = Localizations.Profile.NavigationBar.Items.Done
```

This way, you can easily traverse through thousands of strings without even thinking about it (obviously, how you actually group your strings is up to you).

You can use `-d "delimiter"` option to specify which character you would like to use for nesting, defaults to `-` (slash). 

Use `_` (underscore) to make camel case strings (`MY_AWESOME_WORD` to `MyAwesomeKey`), or omit "c" option to disable this feature.


## Usage

Laurine uses script parameters to change the way how output is generated. Currently, the following is supported:

```
  -i, --input:     
      Required | String | Path to the localization file
  -o, --output:    
      Optional | String | Path to output file (.swift or .m, depending on your configuration. If you are using ObjC, header will be created on that location. If ommited, output will be sent to stdout instead.
  -l, --language:  
      Optional | String | [swift | objc] | Specifies language of generated output files | Defaults to [swift]
  -d, --delimiter: 
      Optional | String | String delimiter to separate segments of each string | Defaults to [.]
  -c, --capitalize:
      Optional | Bool | When enabled, name of all structures / methods / properties are automatically CamelCased | Defaults to false
```


**Command line**

If you wish to generate output just once, run following from terminal in the directory where you have the script downloaded:

```
$ swift LaurineGenerator.swift -i Localizable.strings -c -o Localizations.swift
or for ObjC
$ swift LaurineGenerator.swift -i Localizable.strings -c -o Localizations.m -l objc
```

or, alternatively, if you downloaded it through Brew:

```
$ LaurineGenerator.swift -i Localizable.strings -c -o Localizations.swift
or for ObjC
$ LaurineGenerator.swift -i Localizable.strings -c -o Localizations.m -l objc
```


**Build script**

The recommended way to use Laurine is to create a "Run Script" Build Phase (Xcode > Project > Targets > Your build target > Build Phases > New Run Script Phase). This way, Laurine will be executed before each build and will ensure the integrity of your translations. Be sure to put the script before the "Compile Sources" phase, as it has to generate the code first, before it can be used anywhere else. For convenience, you can just copy the following, and change the configuration appropriately.

```sh
set -x
echo "Laurine Generator : Configuration"

# CONFIGURATION
# Get base path to project
BASE_PATH="$PROJECT_DIR/$PROJECT_NAME"

# Configure path to Laurine Generator script
LAURINE_PATH="$BASE_PATH/Generators/LaurineGenerator.swift"

# Configure path to main localization file (usually english).
SOURCE_PATH="$BASE_PATH/Resources/Localizations/en.lproj/Localizable.strings"

# Configure path to output. If you use ObjC version of output, set implementation file (.m), as header will be generated automatically at the same location.
OUTPUT_PATH="$BASE_PATH/Classes/Generated/Localizations.swift"

echo "Laurine Generator : Write"

# Unlock output file for write
/usr/bin/chflags nouchg "$OUTPUT_PATH"

# Add permission to generator for script execution
chmod 755 $LAURINE_PATH

# Actually generate output. Customize parameters to your needs (see documentation)
$LAURINE_PATH -i $SOURCE_PATH -o $OUTPUT_PATH -c
# ! Use this for ObjC code generator instead 
# $LAURINE_PATH -i $SOURCE_PATH -o $OUTPUT_PATH -c -l objc 

# Lock output file for write
/usr/bin/chflags uchg "$OUTPUT_PATH"

echo "Laurine Generator : Finished"
```

## Installation

**Brew**

Laurine does not require installation. For your convenience, you can make it easily accessible from ``/usr/local/bin`` by installing Laurine through brew:

```
$ brew tap jiritrecak/laurine
$ brew install jiritrecak/laurine/laurine
```
Now you can just run it from everywhere:

```
$ LaurineGenerator.swift ...
```

**GIT**

You can also just clone it wherever you desire:

```
$ git clone https://github.com/JiriTrecak/Laurine.git
$ sudo cp laurine.swift /usr/local/bin/laurine.swift
```

**Download!**

Yes, you can just download the script itself from this repository, it does not need anything else.

## Supported Features

Laurine should suit most of developers, because it covers all the basic stuff. That being said, there are still things missing to have full coverage of what localizations have to offer. Here is the full list of features that will Laurine contain once it is complete:

- [x] Basic localization strings to variables
- [x] Complex localization strings to methods
- [x] Multilevel structures (nesting)
- [x] Generate Swift output
- [x] Generate ObjC output
- [ ] Support for all special localization characters
- [ ] Localization Tables
- [ ] Plural support
- [ ] Gender support
- [ ] Tool for automatic replacement of NSLocalizationString in project (thanks [@Vaberer](https://github.com/Vaberer) )


## Contribute
I will gladly accept Pull Requests (and I encourage you to do so). If you encounter any bug or you have enhancement that you would like to see, please open an issue.

I'd also like to make round of applause to Marcin Krzyżanowski for his [Natalie Generator](https://github.com/krzyzanowskim/Natalie), which heavily inspired this project by his approach. Hope we meet for beer one day!

## Contact me


- [@JiriTrecak](https://twitter.com/@JiriTrecak "My twitter account")
- [jiritrecak@gmail.com](mailto:jiritrecak@gmail.com "My email") 

Or, if you would like to know me better, check out my portfolio.

- [jiritrecak.com](http://jiritrecak.com/ "My personal website") 

##Licence

The MIT License (MIT)

Copyright (c) 2015 Jiří Třečák

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.