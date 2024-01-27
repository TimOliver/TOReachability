<img src="https://github.com/TimOliver/TOReachability/raw/main/screenshot.png" align="right" width="420" />

# TOReachability
	
[![CI](https://github.com/TimOliver/TOReachability/workflows/CI/badge.svg)](https://github.com/TimOliver/TOReachability/actions?query=workflow%3ACI)
[![Version](https://img.shields.io/badge/version-1.2.0-blueviolet?style=flat)](http://cocoadocs.org/docsets/TOReachability)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/TOReachability/master/LICENSE)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M4RKULAVKV7K8)

*A lightweight, unit-tested class that detects network status changes on iOS.*

`TOReachability` is a small Objective-C class that can be used to detect when the current device changes its network status; between Wi-Fi, cellular, or none.

It based on, but is a completely new implementation of Apple's [Reachability](https://github.com/robovm/apple-ios-samples/tree/master/Reachability) class. Compared to Reachability, apart from being properly name-spaced for Objective-C, it has been cleaned up to use modern Objective-C conventions, removes since deprecated features, and removes much of the unnecessary code Apple included.

While `TOReachability` only currently includes the most basic of functionality, it is definitely open to PRs when and if anyone has additional functionality they would like.

## Features
* Fully-unit tested.
* Integrated with CocoaPods and Carthage.
* Reactively executes callback logic whenever the network status of the current status changes.
* Callback choices include blocks, delegates and `NSNotification`.
* For cases where only Wi-Fi is needed, an option may be set to ignore cellular status changes.
* Fully-bridged and tested to work in Swift.

## Minimum Requirements
* iOS 11.0 
* tvOS 11.0 
* macOS 10.13
* Xcode 14.0

## Installation Instructions

<details>
	<summary><strong>CocoaPods</strong></summary>
	<br>
	<pre>pod 'TOReachability'</pre>
</details>

<details>
	<summary><strong>Carthage</strong></summary>
	<br>
	<pre>github "TimOliver/TOReachability"</pre>
</details>

<details>
	<summary><strong>Manual Installation</strong></summary>
	<br>
	Simply move the `TOReachability` folder to your Xcode project and import it.
</details>

## Sample Code

### Objective-C

```objc
TOReachability *reachability = [[TOReachability alloc] init];

reachability.statusChangedHandler = ^(TOReachability *reachability,
					TOReachabilityStatus newStatus,
					TOReachabilityStatus oldStatus) {
        NSLog(@"Network Status Changed!");
};

[reachability start];
```

### Swift

```swift
let reachability = Reachability()

reachability.statusChangedHandler = { reachability, newStatus, oldStatus in
    print("Network Status Changed!")
}

reachability.start()
```

## Credits

Developed by [Tim Oliver](http://twitter.com/TimOliverAU) as a component for [iComics](http://icomics.co).

Device mockup by [Mockups Design](https://mockups-design.com/).

## License

`TOReachability` is licensed under the MIT License, please see the [LICENSE](LICENSE) file.
