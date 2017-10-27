<p align="center">
<img src="https://raw.githubusercontent.com/onevcat/APNGKit/master/images/logo.png" alt="APNGKit" title="APNGKit" width="1000"/>
</p>

<p align="center">
<a href="https://travis-ci.org/onevcat/APNGKit"><img src="https://img.shields.io/travis/onevcat/APNGKit/master.svg"></a>
<a href="https://github.com/Carthage/Carthage/"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
<a href="http://cocoadocs.org/docsets/APNGKit"><img src="https://img.shields.io/cocoapods/v/APNGKit.svg?style=flat"></a>
<a href="https://raw.githubusercontent.com/onevcat/APNGKit/master/LICENSE"><img src="https://img.shields.io/cocoapods/l/APNGKit.svg?style=flat"></a>
<a href="http://cocoadocs.org/docsets/APNGKit"><img src="https://img.shields.io/cocoapods/p/APNGKit.svg?style=flat"></a>
<img src="https://img.shields.io/badge/made%20with-%3C3-blue.svg">
</p>

APNGKit is a high performance framework for loading and displaying APNG images in iOS and macOS. It's built on top of a [modified version of libpng](https://github.com/onevcat/libpng) with APNG support and written in Swift. High-level abstractions of Cocoa Touch is used for a delightful API. Since be that, you will feel at home and joy when using APNGKit to play with images in APNG format.

## APNG, what and why?

The [Animated Portable Network Graphics (APNG)](https://en.wikipedia.org/wiki/APNG) is a file format extending the well-known PNG format. It allows for animated PNG files that work similarly to animated GIF files, while supporting 24-bit images and 8-bit transparency not available for GIFs. This means much better quality of animation. At the same time, the file size is comparable to or even less than, if created carefully, GIFs.

Talk is cheap; show me the image. You can click on the image to see how it looks like when animating.

<p align="center">
<a href="http://apng.onevcat.com/demo" target="_blank"><img src="https://raw.githubusercontent.com/onevcat/APNGKit/master/images/demo.png" alt="APNGKit Demo" title="APNGKit Demo"/></a>
</p>

That's cool. APNG is much better! But wait...why haven't I heard about APNG before? It is not a popular format, so why should I use it in my next great iOS/macOS app?

Good question! APNG is an excellent extension for regular PNG, and it is also very simple to use and not conflicting with current PNG standard (It consists a standard PNG header, so if your platform does not support APNG, it will be recognized as a normal PNG with its first frame being displayed as a static image). But unfortunately, it is a rebel format so that it is not accepted by the PNG group. However, it is accepted by many vendors and is even mentioned in [W3C Standards](http://www.w3.org/TR/html5/embedded-content-0.html#the-img-element). There is another format called MNG (Multiple-image Network Graphics), which is created by the same team as PNG. It is a comprehensive format, but very very very (重要的事要说三遍) complex. It is so complex that despite being a "standard", it was almost universally rejected. There is only one "popular" browser called [Konqueror](https://konqueror.org)(at least I have used it before when I was in high school) that supports MNG, which is really a sad but reasonable story.

Even though APNG is not accepted currently, we continue to see the widespread implementation of it. Apple recently supported APNG in both [desktop and mobile Safari](http://www.macrumors.com/2014/09/28/ios-8-safari-supports-animated-png-images/). [Microsoft Edge](https://wpdev.uservoice.com/forums/257854-microsoft-edge-developer/suggestions/6513393-apng-animated-png-images-support-firefox-and-sa) and [Chrome](https://code.google.com/p/chromium/issues/detail?id=437662) are also considering adding APNG support since it is already officially added in [WebKit core](https://bugs.webkit.org/show_bug.cgi?id=17022).

APNG is such a nice format to bring users much better experience of animating images. The more APNG is used, the more recognition and support it will get. Not only in the browsers world, but also in the apps we always love. That's why I created this framework.

## Installation

### Requirement

iOS 8.0+ / macOS 10.10+

Although it is written in Swift, the compatibility with Objective-C is also considered.

The latest versions (1.x) supports from Xcode 9 (Swift 3.2 or Swift 4). If you are still using Xcode 8, try [version 0.6.4](https://github.com/onevcat/APNGKit/releases/tag/0.6.4) instead.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.36 adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate APNGKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target 'your_app' do
  pod 'APNGKit', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

You should open the `{Project}.xcworkspace` instead of the `{Project}.xcodeproj` after you installed anything from CocoaPods.

For more information about how to use CocoaPods, I suggest [this tutorial](http://www.raywenderlich.com/64546/introduction-to-cocoapods-2).

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager for Cocoa application. To install the carthage tool, you can use [Homebrew](http://brew.sh).

```bash
$ brew update
$ brew install carthage
```

To integrate APNGKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "onevcat/APNGKit" ~> 1.0
```

Then, run the following command to build the APNGKit framework:

```bash
$ carthage update
```

At last, you need to set up your Xcode project manually to add the APNGKit framework.

On your application targets’ “General” settings tab, in the “Linked Frameworks and Libraries” section, drag and drop each framework you want to use from the Carthage/Build folder on disk.

On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following content:

```bash
/usr/local/bin/carthage copy-frameworks
```

and add the paths to the frameworks you want to use under “Input Files”:

```bash
$(SRCROOT)/Carthage/Build/iOS/APNGKit.framework
```

For more information about how to use Carthage, please see its [project page](https://github.com/Carthage/Carthage).

### Manually

It is not recommended to install the framework manually, but it could let you use APNGKit for a deploy target as low as 7.0. You can just download the latest package from the [release page](https://github.com/onevcat/APNGKit/releases) and drag all things under "APNGKit" folder into your project. Then you need to create a bridging header file and add this into it: 

```c
#import "png.h"
```

You can find more information about how to add a bridging header [here](http://www.learnswiftonline.com/getting-started/adding-swift-bridging-header/).

Then you need to add "libz.tbd" in the "Link Binary With Libraries" section in Build Phases. Now APNGKit should compile without issue with your project.

If you are using Swift, fine, just skip the content below to "Usage". If you want to use APNGKit in Objective-C code, you have to check these settings of your project as well:

* Product Module Name: Should be your app target's name
* Defines Module: YES
* Embedded Content Contains Swift: YES
* Install Objective-C Compatibility Header: YES

At last, import the umbrella header file in the .m files you want to use APNGKit:

```c
#import "{YOUR_APP_MODULE_NAME}-Swift.h"
```

Now you can use APNGKit with Objective-C. Ummm...a bit complicated, isn't it? Life is short, let's Swift!

For more information about working with Swift mixing Objective-C/C or vice versa, you could find some useful information from [Apple's documentation on it](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html).

## Usage

You can find the full API documentation at [CocoaDocs](http://cocoadocs.org/docsets/APNGKit/).

### Basic

Import APNGKit into your source files in which you want to use the framework.

```swift
import APNGKit
```

APNGKit is using the similar APIs as `UIImage` and `UIImageView`. Generally speaking, you can just follow the way you do with images in Cocoa Touch to use this framework. The only difference is the name is changed to `APNGImage` and `APNGImageView`.

#### Load an APNG Image

```swift
// Load an APNG image from file in main bundle
var image = APNGImage(named: "your_image")

// Or
// Load an APNG image from file at specified path
var path = NSBundle.mainBundle().pathForResource("your_image", ofType: "apng")
if let path = path {
  image = APNGImage(contentsOfFile: path)  
}

// Or
// Load an APNG image from data
let data: NSData = ... // From disk or network or anywhere else.
image = APNGImage(data: data)
```

APNGKit will try to load all data in the image by one time, so you could play the animation smoothly later. However, if you are trying to load a large APNG file, you may want to keep the memory footprint as small as possible. For this case, you could use a progressive way to load the image. It will only load the frame needed to be display currently. This would save a lot of memory, but take more performance as a trade-off. To enable the progressive way, just pass in an option to the initializer:

```swift
let image = APNGImage(data: data, progressive: true)
```

#### Display an APNG Image

When you have an `APNGImage` object, you can use it to initialize an image view and display it on screen with `APNGImageView`, which is a subclass of `UIView`:

```swift
let image: APNGImage = ... // You already have an APNG image object.

let imageView = APNGImageView(image: image)
view.addSubview(imageView)
```

And play the animation:

```swift
imageView.startAnimating()
```

If you are an Interface Builder lover, drag a `UIView` (Please note, not a `UIImageView`) to the canvas, and modify its class to `APNGImageView`. Then, you can drag an `IBOutlet` and play with it as usual.

### Caches

APNGKit is using memory cache to improve performance when loading an image. If you use `initWithName:` or `initWithContentsOfFile:saveToCache:` with `true`, the APNGKit will cache the result for later use. Normally, you have no need to take care of the caches. APNGKit will manage it and release the caches when a memory warning is received or your app switched to background.

If you need a huge chunk of memory to do an operation, you can call this to force APNGKit to clear the memory cache:

```swift
APNGCache.defaultCache.clearMemoryCache()
```

It will be useful sometimes since there is a chance that your app will crash before a memory warning could be received when you alloc a huge amount of memory. But it should be rare, so if you are not sure about it, just leave APNGKit to manage the cache itself.

### PNG Compression

Xcode will compress all PNG files in your app bundle when you build the project. Since APNG is an extension format of PNG, Xcode will think there are redundancy data in that file and compress it into a single static image. This is not what you want. You can disable the PNG compression by setting "COMPRESS_PNG_FILES" to NO in the build settings of your app target. However, it will also prevent Xcode to optimize your other regular PNGs. 

A better approach would be renaming your APNG files with an extension besides of "png". If you do so, Xcode will stop recognizing your APNG files as PNG format, and will not apply compression on them. A suggested extension is "apng", which will be detected and handled by APNGKit seamlessly.

## TODO

Currently APNGKit can only load and display APNG files or data. There is a plan to extend this framework to export and write APNG files from separated PNG files as frames.

And maybe some callbacks of APNG animation playing or even more controlling of playing will be added later as well. IBDesignable support is also in plan.

## Acknowledgement

APNGKit is built on top of a [modified version of libpng](https://github.com/onevcat/libpng). The original libpng could be found [here](http://www.libpng.org/pub/png/libpng.html). I patched it for APNG supporting based on code in [this project](http://sourceforge.net/p/libpng-apng/code/ci/master/tree/).

The demo images in README file is stolen from ICS Lab, you can find the original post [here](http://ics-web.jp/lab/archives/2441).

The logo of this APNGKit is designed by [Rain (yuchen liu)](https://dribbble.com/yuchenliu), who is a brilliant designer as well as a skillful coder.

## Reference

If you are interested in APNG, you can know more about it from the links below (some of them are written in Chinese).

* [APNG Specification](https://wiki.mozilla.org/APNG_Specification)
* [APNG - Wikipedia](https://www.google.co.jp/url?sa=t&rct=j&q=&esrc=s&source=web&cd=2&cad=rja&uact=8&ved=0CCkQFjABahUKEwjYxdSQjtrHAhWIn5QKHVDkAHs&url=https%3A%2F%2Fen.wikipedia.org%2Fwiki%2FAPNG&usg=AFQjCNF2CJ-OePHGKIhR14TdrCuEn9nn1A&sig2=188CAiDHZv0FVn7QVnhVVQ)
* [小牛犊 APNG 力挫老古董 MNG](http://blog.wuxinan.net/archives/313)
* [再回眸，丽影如初](http://isux.tencent.com/introduction-of-apng.html)

APNGKit can only load and display APNG image now. The creating feature will be developed later. If you need to create APNG file now, I suggest using [iSparta](http://isparta.github.io) or [apngasm](http://apngasm.sourceforge.net) instead for now.

## License

APNGKit is released under the MIT license. See LICENSE for details.


