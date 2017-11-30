# TOSplitViewController
> A split view controller that can display up to three view controllers on the same screen.

<p align="center">
<img src="https://raw.githubusercontent.com/timoliver/tosplitviewcontroller/master/screenshot.jpg" style="margin:0 auto" />
</p>

`TOSplitViewController` is a very 'light' re-implementation of `UISplitViewController`. It behaves like `UISplitViewController` for the most part, but is capable of showing up to 3 columns on some of the larger screens such as the 12.9" iPad Pro, or a regular iPad in landscape orientation.

# Features
* Can display 1 to 3 view controllers on screen at the same time depending on the size of the device screen at the time.
* Handles dynamically collapsing view controllers in separate columns into each other when the screen size changes.
* Plays an elegant transition animation when device rotations require the number of columns to change.
* Exposes as much functionality as possible through delegate methods, and `UIViewController` categories to allow subclasses to override this behaviour.

# Code
Due to the way split view controllers work, it's necessary to create all view controllers ahead of time since a split view controller can be presented collapsed, but then expand at a later time:

```objc
#import "TOCropViewController.h"

PrimaryViewController *mainController = [[PrimaryViewController alloc] initWithStyle:UITableViewStyleGrouped];
UINavigationController *primaryNavController = [[UINavigationController alloc] initWithRootViewController:mainController];

SecondaryViewController *secondaryController = [[SecondaryViewController alloc] init];
UINavigationController *secondaryNavController = [[UINavigationController alloc] initWithRootViewController:secondaryController];

DetailViewController *detailController = [[DetailViewController alloc] init];
UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:detailController];

NSArray *controllers = @[primaryNavController, secondaryNavController, detailNavController];
TOSplitViewController *splitViewController = [[TOSplitViewController alloc] initWithViewControllers:controllers];
splitViewController.delegate = self;
```

# Installation

## Manual Installation

Download this repository from GitHub and extract the zip file. In the extracted folder, import the folder name `TOSplitViewController` into your Xcode project. Make sure 'Copy items if needed` is checked to ensure it is properly copied to your project.

## CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager that makes it much easier to integrate and subsequently update third party libraries in your app's codebase.

To integrate `TOSplitViewController`, simply add the following to your podfile:

```
pod 'TOSplitViewController'
```

## Carthage

Carthage support isn't offered at this time. Please feel free to file a PR. :)

# Why Build This?

iPad screen sizes drastically increased with the launch of the 12.9" iPad Pro. Apple took advantage of this by adding 3 column modes to some of iOS' system apps, including Mail and Notes, however this API wasn't made public to third party developers.

I have a design need for a three column display in one of my upcoming projects, and so I decided it would be worth the time and development resources to create this library.

It's still very much in its infancy, and the complexity required to managed 3 columns at once means there may still be plenty of bugs in it, so bug reports (And more importantly pull requests) are warmly welcomed. :)

# Credits

`TOSplitViewController` was developed by [Tim Oliver](http://twitter.com/TimOliverAU).

iPad Air 2 perspective mockup by [Pixeden](http://pixeden.com).

# License

`TOSplitViewController` is available under the MIT license. Please see the [LICENSE](LICENSE) file for more information. ![analytics](https://ga-beacon.appspot.com/UA-5643664-16/TOSplitViewController/README.md?pixel)

## Support on Beerpay
Hey dude! Help me out for a couple of :beers:!

[![Beerpay](https://beerpay.io/TimOliver/TOSplitViewController/badge.svg?style=beer-square)](https://beerpay.io/TimOliver/TOSplitViewController)  [![Beerpay](https://beerpay.io/TimOliver/TOSplitViewController/make-wish.svg?style=flat-square)](https://beerpay.io/TimOliver/TOSplitViewController?focus=wish)