                                        

import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

                                                                     

@JS('navigator.bluetooth.requestDevice')
external JSPromise<JSObject> _requestDevice(JSObject options);

@JS('navigator.bluetooth')
external JSObject? get _bluetooth;

extension type BluetoothDevice._(JSObject _) implements JSObject {
  external String get id;
  external String get name;
  external BluetoothRemoteGATTServer get gatt;
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type BluetoothRemoteGATTServer._(JSObject _) implements JSObject {
  external bool get connected;
  external JSPromise<BluetoothRemoteGATTServer> connect();
  external void disconnect();
  external JSPromise<BluetoothRemoteGATTService> getPrimaryService(
    String serviceUUID,
  );
}

extension type BluetoothRemoteGATTService._(JSObject _) implements JSObject {
  external JSPromise<BluetoothRemoteGATTCharacteristic> getCharacteristic(
    String characteristicUUID,
  );
}

extension type BluetoothRemoteGATTCharacteristic._(JSObject _)
    implements JSObject {
  external JSPromise<JSDataView> readValue();
  external JSPromise<JSAny?> writeValue(JSArrayBuffer value);
  external JSPromise<JSAny?> writeValueWithResponse(JSArrayBuffer value);
  external JSPromise<BluetoothRemoteGATTCharacteristic> startNotifications();
  external JSPromise<BluetoothRemoteGATTCharacteristic> stopNotifications();
  external set oncharacteristicvaluechanged(JSFunction? handler);
  external JSDataView? get value;
}

                                                                     

bool get isWebBluetoothSupported {
  if (!kIsWeb) return false;
  return _bluetooth != null;
}

class WebBleDevice {
  final String id;
  final String name;
  final BluetoothDevice _jsDevice;

  WebBleDevice._(this._jsDevice) : id = _jsDevice.id, name = _jsDevice.name;

  BluetoothRemoteGATTServer get gatt => _jsDevice.gatt;
}

Future<WebBleDevice?> requestWebBleDevice({
  required List<String> serviceUuids,
  String? namePrefix,
}) async {
  try {
    final filters = <JSObject>[];

    if (namePrefix != null && namePrefix.isNotEmpty) {
      final filter =
          <String, dynamic>{'namePrefix': namePrefix}.jsify() as JSObject;
      filters.add(filter);
    }

    for (final uuid in serviceUuids) {
      final filter =
          <String, dynamic>{
                'services': [uuid].jsify(),
              }.jsify()
              as JSObject;
      filters.add(filter);
    }

    final JSObject options;
    if (filters.isEmpty) {
      options =
          <String, dynamic>{
                'acceptAllDevices': true,
                'optionalServices': serviceUuids.jsify(),
              }.jsify()
              as JSObject;
    } else {
      options =
          <String, dynamic>{
                'filters': filters.jsify(),
                'optionalServices': serviceUuids.jsify(),
              }.jsify()
              as JSObject;
    }

    final jsDevice = await _requestDevice(options).toDart;
    return WebBleDevice._(BluetoothDevice._(jsDevice));
  } catch (e) {
    debugPrint('Web BLE requestDevice failed: $e');
    return null;
  }
}

Future<bool> connectGatt(WebBleDevice device) async {
  try {
    await device.gatt.connect().toDart;
    return device.gatt.connected;
  } catch (e) {
    debugPrint('Web BLE GATT connect failed: $e');
    return false;
  }
}

void disconnectGatt(WebBleDevice device) {
  try {
    device.gatt.disconnect();
  } catch (e) {
    debugPrint('Web BLE disconnect error: $e');
  }
}

JSFunction addGattDisconnectedListener(
  WebBleDevice device,
  void Function() onDisconnected,
) {
  final listener = ((web.Event _) => onDisconnected()).toJS;
  device._jsDevice.addEventListener('gattserverdisconnected', listener);
  return listener;
}

void removeGattDisconnectedListener(WebBleDevice device, JSFunction listener) {
  try {
    device._jsDevice.removeEventListener('gattserverdisconnected', listener);
  } catch (e) {
    debugPrint('Web BLE remove disconnect listener error: $e');
  }
}

Future<BluetoothRemoteGATTService?> getService(
  WebBleDevice device,
  String serviceUuid,
) async {
  try {
    final service = await device.gatt.getPrimaryService(serviceUuid).toDart;
    return service;
  } catch (e) {
    debugPrint('Web BLE getService($serviceUuid) failed: $e');
    return null;
  }
}

Future<BluetoothRemoteGATTCharacteristic?> getCharacteristic(
  BluetoothRemoteGATTService service,
  String charUuid,
) async {
  try {
    return await service.getCharacteristic(charUuid).toDart;
  } catch (e) {
    debugPrint('Web BLE getCharacteristic($charUuid) failed: $e');
    return null;
  }
}

Future<void> writeCharacteristic(
  BluetoothRemoteGATTCharacteristic char,
  Uint8List data,
) async {
  await char.writeValueWithResponse(data.buffer.toJS).toDart;
}

StreamController<List<int>> _notificationController(
  BluetoothRemoteGATTCharacteristic char,
) {
  final controller = StreamController<List<int>>.broadcast();

                                                                      
                                                   
  char.oncharacteristicvaluechanged =
      ((web.Event _) {
        try {
          final dataView = char.value;
          if (dataView != null) {
            final bd = dataView.toDart;
            final bytes = Uint8List.view(
              bd.buffer,
              bd.offsetInBytes,
              bd.lengthInBytes,
            );
            controller.add(bytes.toList());
          }
        } catch (e) {
          debugPrint('Web BLE notification parse error: $e');
        }
      }).toJS;

  controller.onCancel = () {
    try {
      char.oncharacteristicvaluechanged = null;
      char.stopNotifications().toDart.catchError((dynamic _) => char);
    } catch (_) {}
  };

  return controller;
}

Stream<List<int>> startNotifications(BluetoothRemoteGATTCharacteristic char) {
  final controller = _notificationController(char);

  char
      .startNotifications()
      .toDart
      .then((_) {
        debugPrint('Web BLE notifications started');
        return char;
      })
      .catchError((dynamic e) {
        debugPrint('Web BLE startNotifications failed: $e');
        if (!controller.isClosed) controller.addError(e);
        return char;
      });

  return controller.stream;
}

Future<Stream<List<int>>> startNotificationsReady(
  BluetoothRemoteGATTCharacteristic char,
) async {
  final controller = _notificationController(char);

  try {
    await char.startNotifications().toDart;
    debugPrint('Web BLE notifications started');
    return controller.stream;
  } catch (e) {
    debugPrint('Web BLE startNotifications failed: $e');
    if (!controller.isClosed) {
      controller.addError(e);
      await controller.close();
    }
    rethrow;
  }
}

Future<Uint8List?> readCharacteristic(
  BluetoothRemoteGATTCharacteristic char,
) async {
  try {
    final dataView = await char.readValue().toDart;
    final bd = dataView.toDart;
    return Uint8List.view(bd.buffer, bd.offsetInBytes, bd.lengthInBytes);
  } catch (e) {
    debugPrint('Web BLE read failed: $e');
    return null;
  }
}
