APNGKit is a high performance framework for loading and displaying APNG images in iOS. It's built on top of a [modified version of libpng](https://github.com/onevcat/libpng) with APNG support and written in Swift. High-level abstractions of Cocoa Touch is used for a delightful API. Since that, you will feel at home when using APNGKit to play with images in APNG format.

## APNG, what and why?

The [Animated Portable Network Graphics (APNG)](https://en.wikipedia.org/wiki/APNG) is a file format extending the well-known PNG format. It allows for animated PNG files that work similarly to animated GIF files, while supporting 24-bit images and 8-bit transparency not available for GIFs, which means much better quality of animation. At the same time, the file size is comparable or even less if created carefully than GIFs.

Talk is cheap, show me the image. You can click on the image to see how it looks like when animating.

<p align="center">
<a href="http://apng.onevcat.com/demo"><img src="https://raw.githubusercontent.com/onevcat/APNGKit/master/images/demo.png" alt="APNGKit Demo" title="APNGKit Demo"/></a>
</p>

That's cool. But wait...why didn't I even not have heard about APNG before? It is not a popular format, why should I use it in my next great iOS app?

Good question! APNG is an excellent extension for regular PNG, and it is also very simple to use and has no conflicting with current PNG standard. But unfortunately, it is a rebel format so that it is not accepted by the PNG group. However, it is accepted by many vendors and is even mentioned in [W3C Standards](http://www.w3.org/TR/html5/embedded-content-0.html#the-img-element). There is another format called MNG (Multiple-image Network Graphics), which is created by the same team as PNG. It is a comprehensive format, and very very very complex. It is so complex that despite being a "standard" it was almost universally rejected. There is only one "popular" browser called [Konqueror](https://konqueror.org) supports MNG, which is really a sad story.

Even APNG is not accepted currently, we continue to see the widespread implementation of it. Apple recently supported APNG in both [desktop and mobile Safari](http://www.macrumors.com/2014/09/28/ios-8-safari-supports-animated-png-images/). [Microsoft Edge](https://wpdev.uservoice.com/forums/257854-microsoft-edge-developer/suggestions/6513393-apng-animated-png-images-support-firefox-and-sa) and [Chrome](https://code.google.com/p/chromium/issues/detail?id=437662) are also considering to add APNG support since it is already officially added in [WebKit core](https://bugs.webkit.org/show_bug.cgi?id=17022).

APNG is such a nice format to bring users much better expericen of animating images. The more APNG is used, the more recognition and support it will get. Not only in the browsers world, but also in the apps we always love. That why I create this framework.

## Installation

This framework requires iOS 7.0 at least. Since it is written in Swift 2, you will need to use Xcode 7 or above to make it work. And if you want to use it as a dynamic framework (install from CocoaPods or Carthage, in other words), you need a deploy target of iOS 8.0 or above.

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

pod 'APNGKit', '~> 0.1'
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
github "onevcat/APNGKit" >= 0.1
```

Then, run the following command to build the APNGKit framework:

```bash
$ carthage update

```

At last, you need to set up your Xcode project manually to add the APNGKit framework.

On your application targets’ “General” settings tab, in the “Linked Frameworks and Libraries” section, drag and drop each framework you want to use from the Carthage/Build folder on disk.

On your application targets’ “Build Phases” settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following content:

```
/usr/local/bin/carthage copy-frameworks
```

and add the paths to the frameworks you want to use under “Input Files”:

```
$(SRCROOT)/Carthage/Build/iOS/APNGKit.framework
```

For more information about how to use Carthage, please see its [project page](https://github.com/Carthage/Carthage).

### Manually

It is not recommended to install the framework manually, but it could let you use APNGKit for a deploy target as low as 7.0. You can just download the latest package from the [release page](https://github.com/onevcat/APNGKit/releases) and drag all things under "APNGKit" folder into your project. Then you need to add `libz.dylib` in your

TODO


## Usage

You can find the full API documentation at [CocoaDocs](http://cocoadocs.org/docsets/APNGKit/).

### Basic

Import APNGKit at first into your source files in which you want to use the framework.

```swift
import APNGKit
```

APNGKit is using the similar APIs as `UIImage` and `UIImageView`. Generally speaking, you can just change the names to `APNGImage` and `APNGImageView` to use this framework.

#### Load an APNG Image

```swift
// Load an APNG image from file in main bundle
var image = APNGImage(named: "your_image")

// Load an APNG image from file at specified path
var path = NSBundle.mainBundle().pathForResource("your_image", ofType: "apng")
if let path = path {
  image = APNGImage(contentsOfFile: path)  
}

// Load an APNG image from data
let data: NSData = ... // From disk or network or anywhere else.
image = APNGImage(data: data)
```

#### Display an APNG Image

Display the image in your screen is very easy:

```swift
let image: APNGImage = ... // You already have an APNG image object.

let imageView = APNGImageView(image: image)
view.addSubview(imageView)
```

You can also use Interface Builder and drag a `UIView` to the canvas, and modify its class to `APNGImageView`. Then, you can drag an `IBOutlet` and play with it as usual.

### Caches

APNGKit is using memory cache to improve performance when loading an image. If you use `initWithName:` or `initWithContentsOfFile:saveToCache:` with true, the APNGKit will cache the result for later use. Normally, you have no need to take care of the caches. APNGKit will manage it and release the caches when a memory warning is received or your app switched to background.

If you need a huge chunk of memory to do an operation, you can call

```swift

```

to force APNGKit to clear the memory cache. It will be useful since the app will crash before a memory warning could be received. But it is rare, so if you are not sure about it, just leave APNGKit to manage the cache itself.

### PNG Compression



## Acknowledgement

APNGKit is built on top of a [modified version of libpng](https://github.com/onevcat/libpng). The original libpng could be found [here](http://www.libpng.org/pub/png/libpng.html). I patched it for APNG supporting based on code in [this project](http://sourceforge.net/p/libpng-apng/code/ci/master/tree/).

The demo images in README file is stolen from ICS Lab, you can find the original post [here](http://ics-web.jp/lab/archives/2441).
