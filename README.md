# LCYCoreDataHelper
A pure swift light weight core data framework

![Swift 2 compatible](https://img.shields.io/badge/swift2-compatible-4BC51D.svg?style=flat)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)

纯swift的coredata框架，example里有demo，框架正在完善中，欢迎使用和提供建议以及帮助完善。      
This is a pure swift coredata framework. It is developing and improving. The way to use is in the example project. Welcome to give sugestions or help.

如有疑问请邮件我： lichunyu@vip.qq.com     
My email address:  lichunyu@vip.qq.com

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Installing LCYCoreDataHelper

> **LCYCoreDataHelper require a minimum deployment target of iOS 7**,  Now support swift2.3
>
> If you need to support ios 7 ,you can drag the source file into your project. It will work fine. If your project need to support ios8 or later. I recommend you to use Carthage.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build LCYCoreDataHelper 1.6.0+.

To integrate Alamofire into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Your Target Name>' do
pod ‘LCYCoreDataHelper’, :git => ‘https://github.com/leacode/LCYCoreDataHelper.git’
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage


[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Alamofire into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "leacode/LCYCoreDataHelper" ~> 1.6
```

Run `carthage update` to build the framework and drag the built `Alamofire.framework` into your Xcode project.


## License

LCYCoreDataHelper is released under the [MIT License](LICENSE).
