import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:mikrotik_mndp/product_info_provider.dart';

import 'message.dart';

const int tlvTypeMacAddress = 1;
const int tlvTypeIdentity = 5;
const int tlvTypeVersion = 7;
const int tlvTypePlatform = 8;
const int tlvTypeUptime = 10;
const int tlvTypeSoftwareId = 11;
const int tlvTypeBoardName = 12;
const int tlvTypeUnpack = 14;
const int tlvTypeIPV6 = 15;
const int tlvTypeInterfaceName = 16;
const int tlvTypeIPV4 = 17;

abstract class MndpMessageDecoder {
  Future<MndpMessage> decode(Uint8List data);
}

class MndpMessageDecoderImpl implements MndpMessageDecoder {
  MikrotikProductInfoProvider _productInfoProvider;

  MndpMessageDecoderImpl(this._productInfoProvider);

  @override
  Future<MndpMessage> decode(Uint8List data) async {
    var msg = MndpMessage();
    var buffer = ByteData.sublistView(data);
    msg.type = buffer.getUint8(0);
    msg.ttl = buffer.getUint8(1);
    msg.sequence = buffer.getUint16(2);
    int offset = 4;

    while (offset < data.length) {
      int tlvType = buffer.getUint16(offset);
      int tlvLength = buffer.getUint16(offset + 2);
      offset += 4;
      var tlvValue = data.sublist(offset, offset + tlvLength);
      offset += tlvLength;

      switch (tlvType) {
        case tlvTypeMacAddress:
          msg.macAddress = _bytesToMACAddress(tlvValue);
          break;
        case tlvTypeIdentity:
          msg.identity = utf8.decode(tlvValue);
          break;
        case tlvTypeVersion:
          msg.version = utf8.decode(tlvValue);
          break;
        case tlvTypePlatform:
          msg.platform = utf8.decode(tlvValue);
          break;
        case tlvTypeSoftwareId:
          msg.softwareId = utf8.decode(tlvValue);
          break;
        case tlvTypeBoardName:
          msg.boardName = utf8.decode(tlvValue);
          break;
        case tlvTypeInterfaceName:
          msg.interfaceName = utf8.decode(tlvValue);
          break;
        case tlvTypeUptime:
          msg.uptime = Duration(seconds: _bytesToInt(tlvValue));
          break;
        case tlvTypeUnpack:
          msg.unpack = tlvValue[0];
          break;
        case tlvTypeIPV6:
          msg.unicastIpv6Address = _formatIpv6Address(tlvValue);
          break;
        case tlvTypeIPV4:
          msg.unicastIpv4Address = _formatIpv4Address(tlvValue);
          break;
      }
    }
    msg.productInfo = await _productInfoProvider.find(msg.boardName ?? '');
    return msg;
  }

  String _bytesToMACAddress(List<int> bytes) {
    // example: 488F5AAD0B8C
    String m = _bytesToHex(bytes);
    return '${m.substring(0, 2)}:${m.substring(2, 4)}:${m.substring(4, 6)}:${m.substring(6, 8)}:${m.substring(8, 10)}:${m.substring(10, 12)}';
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  int _bytesToInt(List<int> bytes) {
    return bytes.reversed.fold(0, (total, byte) => total * 256 + byte);
  }

  String _formatIpv4Address(List<int> bytes) {
    assert(bytes.length == 4);
    return bytes.map((byte) => byte.toString()).join('.');
  }

  String _formatIpv6Address(List<int> bytes) {
    assert(bytes.length == 16);
    return [
      for (int i = 0; i < bytes.length; i += 2)
        bytes[i].toRadixString(16).padLeft(2, '0') +
            bytes[i + 1].toRadixString(16).padLeft(2, '0')
    ].join(':');
  }
}
