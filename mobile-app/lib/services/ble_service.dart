import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ecu_data.dart';

const _kServiceUuid    = '12345678-1234-1234-1234-123456789abc';
const _kRealtimeUuid   = '12345678-1234-1234-1234-123456789ab1';
const _kCommandUuid    = '12345678-1234-1234-1234-123456789ab2';
const _kDeviceName     = 'F650GS-ECU';

enum BleStatus { idle, scanning, connecting, connected, error }

class BleService extends ChangeNotifier {
  BleStatus _status = BleStatus.idle;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _realtimeChar;
  BluetoothCharacteristic? _commandChar;
  EcuData _data = const EcuData();
  String _errorMsg = '';

  StreamSubscription? _scanSub;
  StreamSubscription? _notifySub;

  BleStatus get status => _status;
  EcuData   get data   => _data;
  String    get errorMsg => _errorMsg;
  bool      get isConnected => _status == BleStatus.connected;

  Future<void> startScan() async {
    if (_status == BleStatus.scanning || _status == BleStatus.connecting) return;

    _setStatus(BleStatus.scanning);

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withNames: [_kDeviceName],
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == _kDeviceName) {
          FlutterBluePlus.stopScan();
          _connect(r.device);
          break;
        }
      }
    });

    FlutterBluePlus.isScanning.where((s) => !s).first.then((_) {
      if (_status == BleStatus.scanning) {
        _setStatus(BleStatus.idle);
        _setError('Dispositivo não encontrado');
      }
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    _setStatus(BleStatus.connecting);
    _device = device;

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      await _discoverServices(device);
      _setStatus(BleStatus.connected);
    } catch (e) {
      _setError('Falha na conexão: $e');
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final svc in services) {
      if (svc.uuid.toString().toLowerCase() == _kServiceUuid) {
        for (final char in svc.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid == _kRealtimeUuid) {
            _realtimeChar = char;
            await char.setNotifyValue(true);
            _notifySub = char.onValueReceived.listen(_onRealtimeData);
          } else if (uuid == _kCommandUuid) {
            _commandChar = char;
          }
        }
        break;
      }
    }

    if (_realtimeChar == null) {
      throw Exception('Serviço ECU não encontrado no dispositivo');
    }
  }

  void _onRealtimeData(List<int> bytes) {
    final raw = Uint8List.fromList(bytes);
    _data = EcuData.fromBytes(raw);
    notifyListeners();
  }

  void _onDisconnected() {
    _realtimeChar = null;
    _commandChar  = null;
    _notifySub?.cancel();
    _setStatus(BleStatus.idle);
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _onDisconnected();
  }

  Future<void> sendCommand(int cmd) async {
    if (_commandChar == null) return;
    await _commandChar!.write([cmd], withoutResponse: true);
  }

  // Envia comando com payload adicional (ex: CMD_FUEL_SET_L + litros×10)
  Future<void> sendCommandBytes(List<int> bytes) async {
    if (_commandChar == null) return;
    await _commandChar!.write(bytes, withoutResponse: true);
  }

  void _setStatus(BleStatus s) {
    _status = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMsg = msg;
    _setStatus(BleStatus.error);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _notifySub?.cancel();
    super.dispose();
  }
}
