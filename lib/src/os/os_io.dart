/*
 * Copyright (c) 2026 Larry Aasen. All rights reserved.
 */

import 'dart:io' show Platform;

/// The operating system name, such as 'android', 'ios', 'macos'.
String get osName => Platform.operatingSystem;

/// The operating system version string.
String get osVersion => Platform.operatingSystemVersion;
