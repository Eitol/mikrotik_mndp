import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_mndp/decoder.dart';
import 'package:mikrotik_mndp/message.dart';
import 'package:mikrotik_mndp/product_info_provider.dart';

void main() {
  test('adds one to input values', () async {
    String data =
        '\x00\x00\x00\x07\x00\x01\x00\x06H\x8fZ\xad~\xe9\x00\x05\x00\x08MikroTik\x00\x07\x00\x126.45.9 ('
        'long-term)\x00\x08\x00\x08MikroTik\x00\n\x00\x04\xc9\x00\x00\x00\x00\x0b\x00\tH5ZN-JERX\x00\x0c'
        '\x00\tRB931-2nD\x00\x0e\x00\x01\x00\x00\x10\x00\x12bridgeLocal/ether2\x00\x11\x00\x04\xc0\xa8\x01}';
    var productInfoProvider = MikrotikProductInfoProviderImpl();
    var decoder = MndpMessageDecoderImpl(productInfoProvider);
    var msg = await decoder.decode(Uint8List.fromList(data.codeUnits));
    expect(msg, isNotNull);
    MndpMessage expectedMessage = MndpMessage.fromJson({
      'type': 0,
      'ttl': 0,
      'sequence': 7,
      'mac_address': '48:8F:5A:AD:7E:E9',
      'identity': 'MikroTik',
      'version': '6.45.9 (long-term)',
      'platform': 'MikroTik',
      'uptime': 201,
      'software_id': 'H5ZN-JERX',
      'board_name': 'RB931-2nD',
      'unpack': 0,
      'interface_name': 'bridgeLocal/ether2',
      'unicast_ipv4_address': '192.168.1.125',
    });
    expect(msg.toJson(), expectedMessage.toJson());
  });
}
