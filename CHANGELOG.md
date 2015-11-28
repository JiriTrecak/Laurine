## 0.2.0 [WIP]

Features added:

- ObjC code generation [WIP]
- New option -c --capitalize - enables autocapitalization of the property / method names
- New option -l --language [objc|swift] - decides which language should be generated [WIP]
- New option -v --verbose - when selected, creates generator.log file in the place of the generator, for debugging purposes and statistics
- New option -o - when set, will write output to file (or 2 files if objc is enabled). If ommited, will send output to stdout instead

Bugfixes:

- Properties and methods that start with numbers [0-9] or any other character that qualifies will now get prefixed with "_" instead of completely breaking output :)
- Fixed all problems that prevented scripts from build phase to actually work

## 0.1.0 (2015-11-18)

Initial release

Features added:

- input parameter processing
- translation file processing
- swift code generation
- nested structs
- localize methods and extensions
- static vars for end-level parameters
- special characters parsed as functions