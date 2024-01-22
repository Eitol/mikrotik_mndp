import 'dart:async';
import 'dart:io';
import 'package:mikrotik_mndp/message.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'decoder.dart';

const List<int> requestPackage = [0, 0, 0, 0];
const int mndpPort = 5678;

class MNDPListener {
  late StreamController<MndpMessage> _controller;
  MndpMessageDecoder _decoder;
  RawDatagramSocket? _txUDPIPv4Socket;
  RawDatagramSocket? _rxUDPIPv4Socket;
  RawDatagramSocket? _txUDPIPv6Socket;
  RawDatagramSocket? _rxUDPIPv6Socket;
  Timer? _sendBroadcastIPv4PeriodicTimer;
  Timer? _sendBroadcastIPv6PeriodicTimer;

  MNDPListener(this._decoder) {
    _controller = StreamController<MndpMessage>();
  }

  Stream<MndpMessage> listen() {
    _listenIPv4();
    _listenIPv6();
    return _controller.stream;
  }

  Stream<MndpMessage> _listenIPv4() {
    var ftxUDPSocket = _createNewMNDPIPv4Socket();
    ftxUDPSocket.then((RawDatagramSocket txSocket) async {
      _txUDPIPv4Socket = txSocket;

      _sendBroadcastIPv4PeriodicTimer =
          Timer.periodic(const Duration(seconds: 10), (Timer t)  {
            _sendBroadcastIPv4RequestMsg();
          });

      var frxUDPSocket = _createNewMNDPIPv4Socket();
      frxUDPSocket.then((rxSocket) async {
        _rxUDPIPv4Socket = rxSocket;
        _rxUDPIPv4Socket!.broadcastEnabled = true;
        _rxUDPIPv4Socket!.multicastLoopback = false;
        _rxUDPIPv4Socket!.listen((RawSocketEvent event) async {
          if (event == RawSocketEvent.read) {
            Datagram? datagram = rxSocket.receive();
            if (datagram != null && datagram.data.length > 4) {
              MndpMessage msg = await _decoder.decode(datagram.data);
              _controller.add(msg);
            }
          }
        });
      });
    });
    return _controller.stream;
  }

  Stream<MndpMessage> _listenIPv6() {
    var ftxUDPSocket = _createNewMNDPIPv6Socket();
    ftxUDPSocket.then((RawDatagramSocket txSocket) async {
      _txUDPIPv6Socket = txSocket;

      _sendBroadcastIPv6PeriodicTimer =
          Timer.periodic(const Duration(seconds: 10), (Timer t) async {
            await _sendBroadcastIPv6RequestMsg();
          });

      var frxUDPSocket = _createNewMNDPIPv6Socket();
      frxUDPSocket.then((rxSocket) async {
        _rxUDPIPv6Socket = rxSocket;
        _rxUDPIPv6Socket!.broadcastEnabled = true;
        _rxUDPIPv6Socket!.multicastLoopback = false;
        _rxUDPIPv6Socket!.listen((RawSocketEvent event) async {
          if (event == RawSocketEvent.read) {
            Datagram? datagram = rxSocket.receive();
            if (datagram != null && datagram.data.length > 4) {
              MndpMessage msg = await _decoder.decode(datagram.data);
              _controller.add(msg);
            }
          }
        });
      });
    });
    return _controller.stream;
  }

  Future<void> _sendBroadcastIPv4RequestMsg() async {
    var broadcastAddress = await NetworkInfo().getWifiBroadcast();
    broadcastAddress ??= '192.168.1.255';
    _txUDPIPv4Socket!.broadcastEnabled = true;
    _txUDPIPv4Socket!.multicastHops = 255;
    _txUDPIPv4Socket!.send(
      requestPackage,
      InternetAddress(broadcastAddress, type: InternetAddressType.IPv4),
      mndpPort,
    );
  }

  Future<void> _sendBroadcastIPv6RequestMsg() async {
    _txUDPIPv6Socket!.broadcastEnabled = true;
    _txUDPIPv6Socket!.multicastHops = 255;
    _txUDPIPv6Socket!.send(
      requestPackage,
      InternetAddress('ff02::1', type: InternetAddressType.IPv6),
      mndpPort,
    );
  }

  Future<RawDatagramSocket> _createNewMNDPIPv4Socket() {
    return RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      mndpPort,
      reuseAddress: true,
    );
  }

  Future<RawDatagramSocket> _createNewMNDPIPv6Socket() {
    return RawDatagramSocket.bind(
      InternetAddress.anyIPv6,
      mndpPort,
      reuseAddress: true,
    );
  }

  void stop() {
    _sendBroadcastIPv4PeriodicTimer?.cancel();
    _sendBroadcastIPv6PeriodicTimer?.cancel();

    _txUDPIPv4Socket?.close();
    _rxUDPIPv4Socket?.close();

    _txUDPIPv6Socket?.close();
    _rxUDPIPv6Socket?.close();

    if (!_controller.isClosed) {
      _controller.close();
    }
  }

}
