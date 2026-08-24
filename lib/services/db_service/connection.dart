// SPDX-License-Identifier: AGPL-3.0-only
export 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';