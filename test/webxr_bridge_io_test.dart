// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:breath_state/services/webxr/webxr_bridge_io.dart';

void main() {
  group('Android WebXR asset server', () {
    test('maps only normalized VR paths into bundled assets', () {
      expect(
        WebXRBridge.assetKeyForPath('/vr/webxr_scene.html'),
        'web/vr/webxr_scene.html',
      );
      expect(
        WebXRBridge.assetKeyForPath(
          '/vr/assets/sanctuary_v3/tree/sakura_hero_lod0.glb',
        ),
        'web/vr/assets/sanctuary_v3/tree/sakura_hero_lod0.glb',
      );
      expect(WebXRBridge.assetKeyForPath('/bridge'), isNull);
      expect(WebXRBridge.assetKeyForPath('/vr/../pubspec.yaml'), isNull);
      expect(WebXRBridge.assetKeyForPath('/vr/%2e%2e/pubspec.yaml'), isNull);
      expect(WebXRBridge.assetKeyForPath('/vr/foo\\bar.js'), isNull);
      expect(WebXRBridge.assetKeyForPath('/vr/bad%path.js'), isNull);
    });

    test('serves WebXR runtime formats with explicit MIME types', () {
      expect(
        WebXRBridge.contentTypeForPath('scene.js').mimeType,
        'text/javascript',
      );
      expect(
        WebXRBridge.contentTypeForPath('tree.glb').mimeType,
        'model/gltf-binary',
      );
      expect(
        WebXRBridge.contentTypeForPath('decoder.wasm').mimeType,
        'application/wasm',
      );
      expect(
        WebXRBridge.contentTypeForPath('texture.webp').mimeType,
        'image/webp',
      );
      expect(WebXRBridge.contentTypeForPath('unknown.bin'), ContentType.binary);
    });
  });
}
