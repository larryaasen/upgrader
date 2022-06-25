## [Unreleased]

Improved the use of shared preferences in unit test.

## [4.2.2]

Fixed an issue on Android when the Webview was opening instead of the Play Store.

## [4.2.2-alpha.1]

Fixed an issue on Android when the Webview was opening instead of the Play Store.

This is a pre-release to allow for testing with a large amount of developers.

## [4.2.1]

- After the latest update to the Play Store, the Android app version was not being
found on the Play Store. This has been resolved.
- Changed the "upgrader: instantiated." message to be behind debugLogging.

## [4.2.1-alpha.2]

Removed noisy exception messages that were logged during Play Store access.

## [4.2.1-alpha.1]

After the latest update to the Play Store, the Android app version was not being
found on the Play Store. This has been resolved.

This is a pre-release to allow for testing with a large amount of developers.

## [4.2.0]

Updated Play Store release notes containing <br> to use newline ('\n') instead.

## 4.1.2

* Fixed Flutter 3 warnings related to `WidgetsBinding.instance`.
* Fixed a typo in the Persian body message.
* Updated xml dependency to ">=5.0.2 <7.0.0".

## 4.1.1

* Fixed error from pub.dev because it used Flutter 2.10.5: "The property 'window' can't be unconditionally accessed because the receiver can be 'null'."

## 4.1.0

* Minor updates after upgrading Flutter to 3.0.0 and Dart to 2.17.0.

## 4.0.0

* [BREAKING] No more singleton. This is a huge update to remove the use of a singleton for Upgrader.
It is now a normal class that is passed to either UpgradeAlert or UpgradeCard.
This makes it easy to subclass Upgrader and change its behavior. The parameters
to UpgradeAlert and UpgradeCard have been removed, and can be set on Upgrader.
See the various examples for more information.

* Changed the callback signature for the willDisplayUpgrade callback to add
minAppVersion, installedVersion, and appStoreVersion parameters.

* Updated url_launcher to version 6.1.0.

* There are no new features, no feature updates, and no bug fixes in this release.

## 4.0.0-alpha.4

[BREAKING]
Changed the callback signature for the willDisplayUpgrade callback to add
minAppVersion, installedVersion, and appStoreVersion parameters.

## 4.0.0-alpha.3

Moved the upgrader parameter for UpgradeCard to a named parameter.

There are no new features, no feature updates, and no bug fixes in this release.

## 4.0.0-alpha.2

The Upgrader class is now used as a shared instance with UpgradeAlert and UpgradeCard.

There are no new features, no feature updates, and no bug fixes in this release.

## 4.0.0-alpha.1

[BREAKING]
No more singleton. This is a huge update to remove the use of a singleton for Upgrader.
It is now a normal class that is passed to either UpgradeAlert or UpgradeCard.
This makes it easy to subclass Upgrader and change its behavior. The parameters
to UpgradeAlert and UpgradeCard have been removed, and can be set on Upgrader.
See the various examples for more information.

Updated url_launcher to version 6.1.0.

There are no new features, no feature updates, and no bug fixes in this release.

## 3.15.0

* Added new language translations for Mongolian ('mn').
* Added new message phrase for 'Release Notes'. All language translations need
to be updated to include a translation. The English and Spanish translations are
included.
* Updated url_launcher to version 6.1.0, and fixed two deprecations from that upgrade.

## 3.14.0

* BREAKING (Minor): Changed the parameter name `debugAlwaysUpgrade` to `debugDisplayAlways`
in `UpgradeAlert` and `UpgradeCard` to be consistent with the rest of the code
and with the README.
* Added new language translation for Dutch ('nl').
* Added new language translation for Khmer ('km').
* Added new language translation for Haitian Creole ('ht').
* Added new language translation for Japanese ('ja').
* Added new callback: `willDisplayUpgrade`: called when `upgrader` determines that
an upgrade may or may not be displayed, defaults to ```null```. The `value`
parameter will be true when it should be displayed, and false when it should not
be displayed. One good use for this callback is logging metrics for your app.

## 3.13.0

* Added new language translation for Swedish ('sv').

## 3.12.1

* Removed the use of dart:io from the package to allow for compatibility on web.
Added use of pacakge os_detect instead. Testing still uses dart:io.

## 3.12.0

* Updated to device_info_plus.
* Changed from using pedantic to flutter_lints. Now using the rules from
flutter_lints/flutter.yaml.
* Now using const instead of final on many variables.
* Resolved linting issues. Used typed over untyped uninitialized variables.

## 3.11.1

* Fixed exception while running in the browser. Added example support for web.

## 3.11.0

* Added new language translations for Greek ('el').

## 3.10.0

* Added new language translations for Lithuanian ('lt').

## 3.9.0

* Added support for minimum app version in the app store description field. See
README for more details.

## 3.8.0

* Added new language translations for Norwegian ('nb').

## 3.7.0

* Migrated from the deprecated package_info plugin to package_info_plus.

## 3.6.0

* Fixed exception for Android release notes when there was no WHAT'S NEW section
on Google Play. Now, the main app description will be used for release notes.

## 3.5.1

* Fixed issue with large text on a small device. Now, the content will scroll.

## 3.5.0

* Added support for Android using the Google Play Store. Now, by default on
Android, the version of the app on the Google Play Store will be used, and there
is no need to setup the Appcast. You can continue using the Appcast on Android,
but it is no longer needed when the app is in the Google Play Store.
* Added a cache buster to the iTunes API URL to break the HTTP caching.

## 3.4.1

* Fixed issue with Appcast where the upgrade message was not displayed.

## 3.4.0

* Added new language translations for Tamil ('ta'), Kazakh ('kk'), Bengali ('bn'), Ukrainian ('uk').

## 3.3.1

* Fixed the parsing of the Appcast body to handle UTF-8 correctly.

## 3.3.0

* When using the ```UpgradeAlert``` widget, the Android back button will not
dismiss the alert dialog by default anymore. To allow the back button to dismiss
the dialog, use ```shouldPopScope``` and return true.

## 3.2.1

* Resolved issue where release notes for the iOS App Store always displayed Minor updates and improvements.

## 3.2.0

* Resolved issue where the country code used by the iTunes Search API should have been upper case.

## 3.1.0

* Added release notes. On iOS the release notes are automatically displayed. For Appcast the description will be used for release notes.
* Added new language translations for Filipino ('fil') and Persian ('fa').

## 3.0.0

* Moved to Flutter 2.0.0 stable.

## 3.0.0-nullsafety.2

* Resolved issues with unit tests so all are passing now. Minor package upgrades.

## 3.0.0-nullsafety.1

* BREAKING CHANGE - Migrated to null safety.
* Upgraded these packages to null safety: device_info, http, package_info, shared_preferences, url_launcher, xml, mockito, pedantic, version.
* Removed reference to unused package flutter_device_locale.
* Skipped many of the unit tests because they could not be quickly resolved of failures. Will send a pre-release version out quickly before testing is completed so that others can use this, and then continue working on the failed tests before release.

## 2.8.2

* Fixed issue with language code that was not supported. It now defaults to 'en' English.
* Added Codemagic CI configuration file.

## 2.8.1

* Improved error checking on UpgraderMessages language code.
* Added extra debug logging.

## 2.8.0

* Changed the parameter daysUntilAlertAgain to durationUntilAlertAgain which is
a breaking change. Thanks to [José](https://github.com/nwparker) for his contribution.
* Updated the Android example to AndroidX.
* Added extra debug logging for language code.
* Moved classes AlertStyleWidget, UpgradeBase, and UpgradeCard into their own Dart files.
* Added Cupertino style alert test.

## 2.7.3

* Added a property to the Upgrader class to allow mocking out Appcast for testing. Thanks
to [Jonah Walker](https://github.com/supposedlysam-bb) for the update.

## 2.7.2

* Added a wider version range for package device_info, up to <1.1.0.

## 2.7.1

* Added extra debug logging.

## 2.7.0

* Added support for a Cupertino style dialog for UpgradeAlert.

## 2.6.2

* Added new language translations for Vietnamese ('vi'), Russian ('ru), Hungarian ('hu'), Turkish ('tr), Indonesian ('id).

## 2.6.1

* Fixed Portuguese and Korean body messages that were reversed. Thanks to Clare Kang for the fix.

## 2.6.0

* Added new language translations for German ('de') and Italian ('it').

## 2.5.2

* Fixed potential crash when the app name is null.

## 2.5.1

* Fixed a bug on Android where the alert was displayed without using an Appcast.

## 2.5.0

* Added new language translations for Polish ('pl') and Korean ('ko').

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
