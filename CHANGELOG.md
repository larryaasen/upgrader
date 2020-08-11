## 2.4.1

* Fixed issue with default country code

## 2.4.0

* Added new language translations for French ('fr') and Portuguese ('pt').
* Updated the Appcast class to support a newer version of the Xml package.

## 2.3.0

* Enhanced to prevent the dialog and card from being closed when in a blocked state, either with a critical update, or when the minimum app version is enforced.

## 2.2.1

* Added support for mocking the Appcast.

## 2.2.0

* Added support for Arabic language localization.

## 2.1.0

* Added support for an optional minimum app version. If the installed version is below the minimum app version,
the ignore and later buttons will be hidden. This is similar to the critical update attribute for Appcast.
* The iOS App Store query will now default to the country code of the system locale,
instead of `US`. This will help suggest upgrades to users from countries other than
the US. The country code can be overriden with the optional `countryCode` parameter.

## 2.0.0

* Major enhancements!
* This update provides language localization in English and Spanish using the new class UpgraderMessage, with the ability to add additional languages, and customize strings. Support for Spanish is included and will work without code changes.
* A few parameters were removed, and if used, will be a breaking change. Most use of this update will not require code changes.
* Five parameters removed: buttonTitleIgnore, buttonTitleLater, buttonTitleUpdate, prompt, title.
* All parameters that were removed are now contained in the messages parameter.
* The body of the message can now be customized and uses mustache style template variables.
* Bumped version to 2.0.0

## 0.11.2

* Removed the restriction for Flutter SDK <1.18.0

## 0.11.1

* Changed use of TargetPlatform and eliminated some warnings.

## 0.11.0

* Updated Flutter SDK to <1.18.0 in support of Flutter 1.17.0.

## 0.10.4

* Updated dependency xml to ">=3.5.0 <5.0.0" to improve score on pub.dev in the 
Maintenance issues and suggestions section.

## 0.10.3

* Updated depenency flutter_device_locale to 0.4.0, and xml to 3.5.0, to improve score on pub.dev in the 
Maintenance issues and suggestions section.

## 0.10.2

* Prepare for 1.0.0 version of sensors and package_info. ([dart_lsc](https://github.com/amirh/dart_lsc))

## 0.10.1

* Downgraded Flutter to stable channel on Travis CI and CircleCI builds to align with pub.dev health scoring.
* Removed the use of TargetPlatform.macOS since it is only available on Flutter 1.13.0 and above.

## 0.10.0

* Added options to hide ignore and later buttons. (Thanks to Karthik Ponnam)
* Added option to close alert dialog on tap outside of alert dialog. (Thanks to Karthik Ponnam)
* 

## 0.9.0

* Added minimum support for Flutter at version 1.30.0 and above to support TargetPlatform.macOS.

## 0.8.1

* Removed TargetPlatform.macOS since pub.dev does not support it yet.

## 0.8.0

* Added support to ITunesSearchAPI for the country query string parameter. Improved example, and added a few new iTunes tests. Minor updates based on Health suggestions from pub.dev, utilizing pedantic.

## 0.7.0

* Improved error messaging, allowed Appcast OS name (sparkle:os) to be case insensitive, example
defaults to debug logging on, and added command line app to evaluate the iTunes search.

## 0.6.0

* Fixed issue to not use the OS version string (deviceInfo.androidInfo.version.baseOS) when it is not a valid Semantic Version as defined here http://semver.org/.

## 0.5.1+1

* updated the examples with an Appcast for Android.

## 0.5.1

* downgraded the xml package version to 3.4.0 to be compatible with Dart 2.2, and updated the Dart version to 2.2.0

## 0.5.0

* **Breaking change**. Migrate from the deprecated original Android Support Library to AndroidX. This shouldn't result in any functional changes, but it requires any Android apps using this plugin to also migrate if they're using the original support library.

## 0.4.3

* improved README documentation and example code

## 0.4.2

* fixed README file that appears on the Dart Packages website

## 0.4.1

* fixed README file that appears on the Dart Packages website

## 0.4.0

* added Appcast to support Android upgrades

## 0.3.0

* added UpgradeCard class

## 0.2.0

* added many customizations to the widget including callbacks for onIgnore, onLater, and onUpdate
* updated the README screenshot
* updated tests, improved README
* broke out widget into new file 

## 0.1.0

* Initial Open Source release.
