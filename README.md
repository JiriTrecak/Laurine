# Laurine

**Localization code generator** written (with love) for Swift, **intended to end the constant problems** that localizations present for developers.


## Do I need it? (yes you do)

Laurine is clever Swift script that scans your localization file and generates actual structured code out of it, therefore making the usage of localization strings much easier. 

What is so good about it is that by removing magical strings from your code, compiler can actually tell you that you forgot to make changes (and where), if your localization file changes. It also introduces type checks for strings that contain runtime parameters (`%@`, `%d` etc.).

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
self.labelToLocalize.text = Localizations.ProfileInfo("Jiri", 25, 1.75)
```
Once again, Xcode autocomplete for the win! Insanity.

![Image : XCode help for methods](https://github.com/JiriTrecak/Laurine/blob/master/Help/help-2.png?raw=true "Xcode autocomplete")


## Nested Structures

There is one more problem when it comes strings - especially with larger projects, and that is their length and sheer amount (projects with 1000+ localization strings are not really that uncommon). 

It is good practice to write keys so they are as descriptive as possible. Laurine takes advantage of that and instead of super-lengthy name of the property, it generates nested structures. Following:

```swift
"PROFILE-NAVIGATION_BAR-ITEMS-DONE" = "Done"
```

Is actually converted to:

```swift
self.labelToLocalize.text = Localizations.Profile.NavigationBar.Items.Done
```

This way, you can easily traverse through thousands of strings without even thinking about it (obviously, how you actually group your strings is up to you).

You can use `-d "delimiter"` option to specify which character you would like to use for nesting, defaults to `-` (slash). 

Use `_` (underscore) to make camel case strings (`MY_AWESOME_WORD` to `MyAwesomeKey`), or omit "c" option to disable this feature.


## Usage

Laurine uses script parameters to change the way how output is generated. Currently, following is supported:

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

If you wish to just generate the code once, run following from terminal:

```
$ swift laurine.swift -i "Localizable.strings" -c > "Localizations.swift"
or 
$ swift laurine.swift -i "Localizable.strings" -c -o "Localizations.swift"

```

or, if you are using brew:

```
$ LaurineGenerator.swift -i "Localizable.strings" -c > "Localizations.swift"
or 
$ LaurineGenerator.swift -i "Localizable.strings" -c -o "Localizations.swift"
```

**Build script**

I am working on generic build script for everyone, stay tuned!

## Installation

**Brew**

Laurine does not require installation. For your convenience, you can make it easily accessible from /usr/local/bin by installing Laurine through brew:

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

While the Laurine is still very young project, it should cover most of regular usage. That being said, there are features that are still missing to have full coverage of everything, that localizations offer. Here is full list of features that will Laurine contain once it is complete.

- [x] Basic localization strings to variables
- [x] Complex localization strings to methods
- [x] Multilevel structures (nesting)
- [ ] Generate Swift OR Obj-C version of the code
- [ ] Localization Tables
- [ ] Plural support
- [ ] Gender support
- [ ] More options [disable nesting etc.]

Optional features that I am considering, but have major problems and has to be thought out first, are following:

- [ ] Naming for methods
- [ ] Seamless integration with [Localize-Swift](https://github.com/marmelroy/Localize-Swift)

## Contribute
I will gladly accept Pull Requests that you do, (and I encourage you to do so). If you have any bug or enhnacement that I could do, please open issue and describe it.

I'd also like to round of applause to Marcin Krzyżanowski for his [Natalie Generator](https://github.com/krzyzanowskim/Natalie), which heavily inspired this project by his approach. Here, have a beer!

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