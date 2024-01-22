import 'dart:async';
import 'dart:io';
import 'package:mikrotik_mndp/message.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'decoder.dart';

const List<int> requestPackage = [0, 0, 0, 0];
const int mndpPort = 5678;

class MNDPListener {
  late StreamController<MndpMessage> controller;
  MndpMessageDecoder decoder;
  RawDatagramSocket? txUDPIPv4Socket;
  RawDatagramSocket? rxUDPIPv4Socket;
  RawDatagramSocket? txUDPIPv6Socket;
  RawDatagramSocket? rxUDPIPv6Socket;
  Timer? sendBroadcastIPv4PeriodicTimer;
  Timer? sendBroadcastIPv6PeriodicTimer;

  MNDPListener(this.decoder) {
    controller = StreamController<MndpMessage>();
  }

  Stream<MndpMessage> listen() {
    listenIPv4();
    listenIPv6();
    return controller.stream;
  }

  Stream<MndpMessage> listenIPv4() {
    var ftxUDPSocket = createNewMNDPIPv4Socket();
    ftxUDPSocket.then((RawDatagramSocket txSocket) async {
      txUDPIPv4Socket = txSocket;

      sendBroadcastIPv4PeriodicTimer =
          Timer.periodic(const Duration(seconds: 10), (Timer t)  {
            sendBroadcastIPv4RequestMsg();
          });

      var frxUDPSocket = createNewMNDPIPv4Socket();
      frxUDPSocket.then((rxSocket) async {
        rxUDPIPv4Socket = rxSocket;
        rxUDPIPv4Socket!.broadcastEnabled = true;
        rxUDPIPv4Socket!.multicastLoopback = false;
        rxUDPIPv4Socket!.listen((RawSocketEvent event) async {
          if (event == RawSocketEvent.read) {
            Datagram? datagram = rxSocket.receive();
            if (datagram != null && datagram.data.length > 4) {
              MndpMessage msg = await decoder.decode(datagram.data);
              controller.add(msg);
            }
          }
        });
      });
    });
    return controller.stream;
  }

  Stream<MndpMessage> listenIPv6() {
    var ftxUDPSocket = createNewMNDPIPv6Socket();
    ftxUDPSocket.then((RawDatagramSocket txSocket) async {
      txUDPIPv6Socket = txSocket;

      sendBroadcastIPv6PeriodicTimer =
          Timer.periodic(const Duration(seconds: 10), (Timer t) async {
            await sendBroadcastIPv6RequestMsg();
          });

      var frxUDPSocket = createNewMNDPIPv6Socket();
      frxUDPSocket.then((rxSocket) async {
        rxUDPIPv6Socket = rxSocket;
        rxUDPIPv6Socket!.broadcastEnabled = true;
        rxUDPIPv6Socket!.multicastLoopback = false;
        rxUDPIPv6Socket!.listen((RawSocketEvent event) async {
          if (event == RawSocketEvent.read) {
            Datagram? datagram = rxSocket.receive();
            if (datagram != null && datagram.data.length > 4) {
              MndpMessage msg = await decoder.decode(datagram.data);
              controller.add(msg);
            }
          }
        });
      });
    });
    return controller.stream;
  }

  Future<void> sendBroadcastIPv4RequestMsg() async {
    var broadcastAddress = await NetworkInfo().getWifiBroadcast();
    broadcastAddress ??= '192.168.1.255';
    txUDPIPv4Socket!.broadcastEnabled = true;
    txUDPIPv4Socket!.multicastHops = 255;
    txUDPIPv4Socket!.send(
      requestPackage,
      InternetAddress(broadcastAddress, type: InternetAddressType.IPv4),
      mndpPort,
    );
  }

  Future<void> sendBroadcastIPv6RequestMsg() async {
    txUDPIPv6Socket!.broadcastEnabled = true;
    txUDPIPv6Socket!.multicastHops = 255;
    txUDPIPv6Socket!.send(
      requestPackage,
      InternetAddress('ff02::1', type: InternetAddressType.IPv6),
      mndpPort,
    );
  }

  Future<RawDatagramSocket> createNewMNDPIPv4Socket() {
    return RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      mndpPort,
      reuseAddress: true,
    );
  }

  Future<RawDatagramSocket> createNewMNDPIPv6Socket() {
    return RawDatagramSocket.bind(
      InternetAddress.anyIPv6,
      mndpPort,
      reuseAddress: true,
    );
  }

  void stop() {
    sendBroadcastIPv4PeriodicTimer?.cancel();
    sendBroadcastIPv6PeriodicTimer?.cancel();

    txUDPIPv4Socket?.close();
    rxUDPIPv4Socket?.close();

    txUDPIPv6Socket?.close();
    rxUDPIPv6Socket?.close();

    if (!controller.isClosed) {
      controller.close();
    }
  }

}
