// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:typed_data';

import 'package:breath_state/services/go_direct/go_direct_constants.dart';
import 'package:breath_state/services/go_direct/go_direct_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Go Direct packet builder', () {
    test('builds Vernier commands with the official header and counter', () {
      final builder = GoDirectPacketBuilder();

      final init = builder.buildInit();
      expect(init.length, 25);
      expect(init.sublist(0, 3), [0x58, 25, 0xFE]);
      expect(init[4], GoDirectCommands.init);
      expect(_checksumValid(init), isTrue);

      final status = builder.buildGetBatteryStatus();
      expect(status.sublist(0, 3), [0x58, 5, 0xFD]);
      expect(status[4], GoDirectCommands.getStatus);
      expect(_checksumValid(status), isTrue);

      final disconnect = builder.buildDisconnect();
      expect(disconnect.sublist(0, 3), [0x58, 5, 0xFC]);
      expect(disconnect[4], GoDirectCommands.disconnect);
      expect(_checksumValid(disconnect), isTrue);
    });

    test(
      'INIT with counter 0xFE produces the exact Vernier reference packet',
      () {
        final builder = GoDirectPacketBuilder();
        final init = builder.buildInit();

        expect(
          init,
          orderedEquals(<int>[
            0x58,
            0x19,
            0xFE,
            0x3F,
            0x1A,
            0xA5,
            0x4A,
            0x06,
            0x49,
            0x07,
            0x48,
            0x08,
            0x47,
            0x09,
            0x46,
            0x0A,
            0x45,
            0x0B,
            0x44,
            0x0C,
            0x43,
            0x0D,
            0x42,
            0x0E,
            0x41,
          ]),
        );
      },
    );

    test('checksum is correct for several known commands', () {
      final builder = GoDirectPacketBuilder();
      final init = builder.buildInit();
      expect(_checksumValid(init), isTrue);

      final status = builder.buildGetBatteryStatus();
      expect(_checksumValid(status), isTrue);

      final info = builder.buildGetDeviceInfo();
      expect(_checksumValid(info), isTrue);

      final period = builder.buildSetMeasurementPeriod(100000);
      expect(_checksumValid(period), isTrue);

      final start = builder.buildStartMeasurements(0x02);
      expect(_checksumValid(start), isTrue);

      final stop = builder.buildStopMeasurements();
      expect(_checksumValid(stop), isTrue);

      final disconnect = builder.buildDisconnect();
      expect(_checksumValid(disconnect), isTrue);
    });

    test('encodes the measurement period as a little-endian period', () {
      final packet = GoDirectPacketBuilder().buildSetMeasurementPeriod(100000);

      expect(packet.length, 15);
      expect(packet.sublist(4), [
        GoDirectCommands.setMeasurementPeriod,
        0xFF,
        0x00,
        0xA0,
        0x86,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
      expect(_checksumValid(packet), isTrue);
    });

    test('25-byte INIT command fragments into 20 + 5 byte BLE writes', () {
      final builder = GoDirectPacketBuilder();
      final packet = builder.buildInit();
      expect(packet.length, 25);

      final chunks = splitGoDirectBlePacket(packet);

      expect(chunks, hasLength(2));
      expect(chunks[0].length, 20);
      expect(chunks[1].length, 5);
      expect([...chunks[0], ...chunks[1]], orderedEquals(packet));
    });

    test('all command layouts match Vernier command IDs and lengths', () {
      final builder = GoDirectPacketBuilder();
      final packets = <(Uint8List, int, int)>[
        (builder.buildInit(), GoDirectCommands.init, 25),
        (builder.buildGetBatteryStatus(), GoDirectCommands.getStatus, 5),
        (builder.buildGetDeviceInfo(), GoDirectCommands.getDeviceInfo, 5),
        (
          builder.buildGetDefaultSensorsMask(),
          GoDirectCommands.getDefaultSensorsMask,
          5,
        ),
        (
          builder.buildGetAvailableSensors(),
          GoDirectCommands.getAvailableSensors,
          5,
        ),
        (builder.buildGetSensorInfo(2), GoDirectCommands.getSensorInfo, 6),
        (
          builder.buildSetMeasurementPeriod(100000),
          GoDirectCommands.setMeasurementPeriod,
          15,
        ),
        (
          builder.buildStartMeasurements(0x06),
          GoDirectCommands.startMeasurements,
          19,
        ),
        (
          builder.buildStopMeasurements(),
          GoDirectCommands.stopMeasurements,
          11,
        ),
        (builder.buildDisconnect(), GoDirectCommands.disconnect, 5),
      ];

      for (final (packet, commandId, length) in packets) {
        expect(packet[0], GoDirectProtocol.commandHeader);
        expect(packet[1], length);
        expect(packet[4], commandId);
        expect(_checksumValid(packet), isTrue);
      }
    });
  });

  group('Go Direct BLE transport', () {
    test('prefers write without response when both modes are available', () {
      expect(
        selectGoDirectWriteMode(
          supportsWrite: true,
          supportsWriteWithoutResponse: true,
        ),
        GoDirectWriteMode.withoutResponse,
      );
      expect(
        selectGoDirectWriteMode(
          supportsWrite: true,
          supportsWriteWithoutResponse: false,
        ),
        GoDirectWriteMode.withResponse,
      );
    });

    test('mock writer receives sequential without-response chunks', () async {
      final writes = <({int index, int count, int length, bool without})>[];
      var activeWrites = 0;

      await writeGoDirectBlePacket(
        packet: GoDirectPacketBuilder().buildInit(),
        mode: GoDirectWriteMode.withoutResponse,
        writeChunk: (chunk, index, count, withoutResponse) async {
          activeWrites++;
          expect(activeWrites, 1, reason: 'writes must never overlap');
          await Future<void>.delayed(Duration.zero);
          writes.add((
            index: index,
            count: count,
            length: chunk.length,
            without: withoutResponse,
          ));
          activeWrites--;
        },
      );

      expect(writes.map((write) => write.index), [0, 1]);
      expect(writes.map((write) => write.count), [2, 2]);
      expect(writes.map((write) => write.length), [20, 5]);
      expect(writes.every((write) => write.without), isTrue);
    });

    test('fragmentation is independent of negotiated ATT MTU', () {
      final packet = GoDirectPacketBuilder().buildInit();

      for (final mtu in [23, 185, 247, 517]) {
        final chunks = splitGoDirectBlePacket(packet);
        expect(
          chunks.every((chunk) => chunk.length <= goDirectBleChunkSize),
          isTrue,
          reason: 'MTU $mtu must not change Go Direct framing',
        );
        expect(chunks.map((chunk) => chunk.length), [20, 5]);
      }
    });

    test('INIT cannot run before notification setup completes', () async {
      final notificationSetup = Completer<bool>();
      var notificationsEnabled = false;
      var initSent = false;

      final initialization = runGoDirectAfterNotificationSetup<void>(
        enableNotifications: () => notificationSetup.future,
        notificationsAreEnabled: () => notificationsEnabled,
        runWhenReady: () async {
          initSent = true;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(initSent, isFalse);

      notificationsEnabled = true;
      notificationSetup.complete(true);
      await initialization;

      expect(initSent, isTrue);
    });
  });

  test(
    'serializes operations and continues after an earlier failure',
    () async {
      final queue = GoDirectSerialQueue();
      final order = <int>[];

      final first = queue.enqueue<void>(() async {
        order.add(1);
        throw StateError('first operation failed');
      });
      final second = queue.enqueue<String>(() async {
        order.add(2);
        return 'completed';
      });

      await expectLater(first, throwsA(isA<StateError>()));
      expect(await second, 'completed');
      expect(order, [1, 2]);
    },
  );

  group('Go Direct response parser', () {
    test('parses a real simulator INIT response (0x58 header)', () {
      final parser = GoDirectResponseParser();
      const packet = [0x58, 0x07, 0x00, 0x89, 0x1A, 0xFE, 0x00];

      final responses = parser.feed(packet);

      expect(responses, hasLength(1));
      final rsp = responses.single;
      expect(rsp.isMeasurement, isFalse);
      expect(rsp.commandId, 0x1A);
      expect(rsp.counter, 0xFE);
      expect(rsp.payload, [0x00]);
    });

    test('response matching requires both command ID and rolling counter', () {
      const pendingCommandId = 0x1A;
      const pendingCounter = 0xFE;

      final parser = GoDirectResponseParser();
      final responses = parser.feed([0x58, 0x07, 0x00, 0x89, 0x1A, 0xFE, 0x00]);

      expect(responses, hasLength(1));
      final rsp = responses.single;
      expect(
        goDirectResponseMatches(
          rsp,
          commandId: pendingCommandId,
          counter: pendingCounter,
        ),
        isTrue,
      );
    });

    test(
      'response with wrong rolling counter does not match pending command',
      () {
        const pendingCommandId = 0x1A;
        const pendingCounter = 0xFE;

        final parser = GoDirectResponseParser();
        final responses = parser.feed([
          0x58,
          0x07,
          0x00,
          0x00,
          0x1A,
          0xFD,
          0x00,
        ]);

        expect(responses, hasLength(1));
        final rsp = responses.single;
        expect(rsp.commandId == pendingCommandId, isTrue);
        expect(rsp.counter == pendingCounter, isFalse);
        expect(
          goDirectResponseMatches(
            rsp,
            commandId: pendingCommandId,
            counter: pendingCounter,
          ),
          isFalse,
        );
      },
    );

    test(
      'reassembles a command response received across multiple BLE notifications',
      () {
        final parser = GoDirectResponseParser();

        const full = [0x58, 0x07, 0x00, 0x89, 0x1A, 0xFE, 0x00];

        expect(parser.feed(full.sublist(0, 4)), isEmpty);
        final responses = parser.feed(full.sublist(4));

        expect(responses, hasLength(1));
        expect(responses.single.commandId, 0x1A);
        expect(responses.single.counter, 0xFE);
        expect(responses.single.payload, [0x00]);
      },
    );

    test(
      'extracts multiple complete packets from a single notification buffer',
      () {
        final parser = GoDirectResponseParser();

        const response1 = [0x58, 0x07, 0x00, 0x89, 0x1A, 0xFE, 0x00];
        const response2 = [0x58, 0x06, 0x00, 0x00, 0x10, 0xFD];

        final responses = parser.feed([...response1, ...response2]);

        expect(responses, hasLength(2));
        expect(responses[0].commandId, 0x1A);
        expect(responses[0].counter, 0xFE);
        expect(responses[1].commandId, 0x10);
        expect(responses[1].counter, 0xFD);
      },
    );

    test(
      '0x20 packets are parsed as measurements and not as command responses',
      () {
        final parser = GoDirectResponseParser();

        final value = ByteData(4)..setFloat32(0, 1.25, Endian.little);
        final packet = <int>[
          GoDirectProtocol.measurementResponse,
          13,
          0x00,
          0x00,
          GoDirectMeasurementType.normalReal32,
          0x02,
          0x00,
          1,
          0x00,
          ...value.buffer.asUint8List(),
        ];

        final response = parser.feed(packet).single;
        final measurements = parseMeasurementData(response.packet, [1]);

        expect(response.isMeasurement, isTrue);
        expect(response.commandId, -1);
        expect(measurements[1], hasLength(1));
        expect(measurements[1]!.single, closeTo(1.25, 0.00001));
      },
    );

    test('does not require a universal 0x58 command-response header', () {
      final response =
          GoDirectResponseParser().feed([
            0x5C,
            0x07,
            0x00,
            0x00,
            0x1A,
            0xFE,
            0x00,
          ]).single;

      expect(response.isMeasurement, isFalse);
      expect(response.commandId, GoDirectCommands.init);
      expect(response.counter, 0xFE);
    });

    test('reset clears fragmented data from a prior connection', () {
      final parser = GoDirectResponseParser();
      parser.feed([0x58, 0x07, 0x00]);
      expect(parser.bufferedByteCount, 3);

      parser.reset();

      expect(parser.bufferedByteCount, 0);
      final response =
          parser.feed([0x58, 0x07, 0x00, 0x89, 0x1A, 0xFE, 0x00]).single;
      expect(response.counter, 0xFE);
    });

    test('reassembles long sensor info over many notifications', () {
      final parser = GoDirectResponseParser();
      final payload = List<int>.generate(148, (index) => index & 0xFF);
      final packet = <int>[
        0x58,
        154,
        0x00,
        0x00,
        GoDirectCommands.getSensorInfo,
        0xFA,
        ...payload,
      ];
      final responses = <GoDirectResponse>[];

      for (var offset = 0; offset < packet.length; offset += 20) {
        responses.addAll(
          parser.feed(
            packet.sublist(
              offset,
              (offset + 20).clamp(0, packet.length).toInt(),
            ),
          ),
        );
      }

      expect(responses, hasLength(1));
      expect(responses.single.commandId, GoDirectCommands.getSensorInfo);
      expect(responses.single.counter, 0xFA);
      expect(responses.single.payload, payload);
    });

    test('malformed leading bytes cannot permanently poison reassembly', () {
      final parser = GoDirectResponseParser();
      final responses = parser.feed([
        0x99,
        0xFA,
        0x01,
        0x02,
        0x58,
        0x07,
        0x00,
        0x89,
        0x1A,
        0xFE,
        0x00,
      ]);

      expect(responses, hasLength(1));
      expect(responses.single.commandId, GoDirectCommands.init);
      expect(parser.bufferedByteCount, 0);
    });

    test('fresh protocol session always restarts INIT at counter FE', () {
      final builder = GoDirectPacketBuilder();
      builder.buildInit();
      builder.buildGetBatteryStatus();

      builder.reset();

      expect(builder.buildInit()[2], 0xFE);
    });
  });

  group('Go Direct sensor payloads', () {
    test('decodes the available-sensor bitmask', () {
      const payload = [0x02, 0x00, 0x00, 0x00];

      expect(parseSensorMask(payload), 2);
      expect(parseDefaultSensorsMask(payload), 2);
      expect(parseSensorIds(payload), [1]);
    });

    test('decodes the fixed-width sensor info response', () {
      final payload = List<int>.filled(148, 0);
      payload[0] = 1;
      payload[2] = 0x34;
      payload[3] = 0x12;
      _writeCString(payload, 14, 60, 'Respiration Force');
      _writeCString(payload, 74, 32, 'N');
      _writeUint32(payload, 124, 10000);
      _writeUint32(payload, 136, 100000);
      payload[144] = 0x02;

      final info = parseSensorInfo(payload);

      expect(info, isNotNull);
      expect(info!.sensorNumber, 1);
      expect(info.sensorId, 0x1234);
      expect(info.description, 'Respiration Force');
      expect(info.units, 'N');
      expect(info.minimumPeriodMs, 10);
      expect(info.typicalPeriodMs, 100);
      expect(info.mutualExclusionMask, 2);
    });
  });

  group('Go Direct respiration belt discovery', () {
    test('matches belt advertisements without matching other GDX sensors', () {
      expect(isGoDirectDeviceName('GDX-RB 123456'), isTrue);
      expect(isGoDirectRespirationBeltName(' gdx-rb 123456 '), isTrue);
      expect(isGoDirectRespirationBeltName('GDX-HD 123456'), isFalse);
      expect(isGoDirectRespirationBeltName('Polar H10'), isFalse);
    });

    test(
      'accepts devices by GDX name prefix or advertised Go Direct service UUID',
      () {
        expect(
          isGoDirectCandidate(name: 'GDX-RB 0K1012B4', serviceUuids: []),
          isTrue,
        );

        expect(
          isGoDirectCandidate(
            name: 'DESKTOP-S5JUIAG',
            serviceUuids: [GoDirectUuids.primaryService],
          ),
          isTrue,
        );

        expect(
          isGoDirectCandidate(
            name: '',
            serviceUuids: [GoDirectUuids.primaryService],
          ),
          isTrue,
        );

        expect(
          isGoDirectCandidate(name: 'DESKTOP-S5JUIAG', serviceUuids: []),
          isFalse,
        );
        expect(
          isGoDirectCandidate(name: 'Polar H10', serviceUuids: []),
          isFalse,
        );
      },
    );

    test('provides all documented GDX-RB channels as a fallback', () {
      final channels = knownGoDirectDevices['GDX-RB']!;

      expect(channels.map((sensor) => sensor.sensorNumber), [1, 2, 3, 4]);
      expect(channels.map((sensor) => sensor.description), [
        'Force',
        'Respiration Rate',
        'Steps',
        'Step Rate',
      ]);
    });
  });
}

bool _checksumValid(Uint8List packet) {
  final saved = packet[3];
  final copy = Uint8List.fromList(packet);
  copy[3] = 0;
  return calculateGoDirectChecksum(copy) == saved;
}

void _writeCString(List<int> target, int start, int width, String value) {
  final bytes = value.codeUnits;
  for (var index = 0; index < bytes.length && index < width; index++) {
    target[start + index] = bytes[index];
  }
}

void _writeUint32(List<int> target, int offset, int value) {
  final bytes = ByteData(4)..setUint32(0, value, Endian.little);
  target.setRange(offset, offset + 4, bytes.buffer.asUint8List());
}
