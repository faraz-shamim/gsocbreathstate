// SPDX-License-Identifier: AGPL-3.0-only
export 'webxr_bridge_stub.dart'
    if (dart.library.io) 'webxr_bridge_io.dart'
    if (dart.library.js_interop) 'webxr_bridge_web.dart';
