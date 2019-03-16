<img src="https://github.com/TimOliver/TOReachability/raw/master/screenshot.jpg" align="right" width="400" />

# TOReachability
	
[![Build Status](https://badge.buildkite.com/16dbb7e654c24edd77dff09019e0f515b98810d7eec6cbfa68.svg?branch=master)](https://buildkite.com/xd-ci/toreachability-run-ci)
[![Version](https://img.shields.io/cocoapods/v/TOReachability.svg?style=flat)](http://cocoadocs.org/docsets/TOReachability)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/TOReachability/master/LICENSE)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M4RKULAVKV7K8)
[![Twitch](https://img.shields.io/badge/twitch-timXD-6441a5.svg)](http://twitch.tv/timXD)

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

## Requirements
* iOS 9.0 
* Xcode 10.0 or higher

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
TOReachability *reachability = [TOReachability reachabilityForInternetConnection];

reachability.statusChangedHandler = ^(TOReachabilityStatus newStatus) {
        NSLog(@"Network Status Changed!");
};

[reachability start];
```

### Swift

```swift
let reachability = Reachability.forInternetConnection()

reachability.statusChangedHandler = { newStatus in
    print("Network Status Changed!")
}

reachability.start()
```

## Credits

Developed by [Tim Oliver](http://twitter.com/TimOliverAU) as a component for [iComics](http://icomics.co).

Device mockup by [Pixeden](http://pixeden.com)

**App Icons**
* [Four Bars](https://thenounproject.com/icon/2191085/) icon by Zach Bogart, US.
* [WiFi](https://thenounproject.com/icon/1831138/) icon by Untashable, US.
* [Disconnected](https://thenounproject.com/icon/683381/) icon by naim, MX.

## License

`TOReachability` is licensed under the MIT License, please see the [LICENSE](LICENSE) file.