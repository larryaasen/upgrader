/*
 * Copyright (c) 2026 Larry Aasen. All rights reserved.
 */

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// On the web the operating system is reported as 'browser'.
String get osName => 'browser';

/// On the web the version is the browser's `navigator.appVersion`.
String get osVersion {
  final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
  final appVersion = navigator?.getProperty<JSString?>('appVersion'.toJS);
  return appVersion?.toDart ?? '';
}
