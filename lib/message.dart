import 'package:mikrotik_mndp/product.dart';

class MndpMessage {
  int? type;
  int? ttl;
  int? sequence;
  String? macAddress;
  String? identity;
  String? version;
  String? platform;
  Duration? uptime;
  String? softwareId;
  String? boardName;
  int? unpack;
  String? interfaceName;
  String? unicastIpv6Address;
  String? unicastIpv4Address;
  MikrotikProduct? productInfo;

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "ttl": ttl,
      "sequence": sequence,
      "macAddress": macAddress,
      "identity": identity,
      "version": version,
      "platform": platform,
      "uptime": uptime?.inSeconds,
      "softwareId": softwareId,
      "boardName": boardName,
      "unpack": unpack,
      "interfaceName": interfaceName,
      "unicastIpv6Address": unicastIpv6Address,
      "unicastIpv4Address": unicastIpv4Address,
    };
  }

  static fromJson(Map<String, dynamic> json) {
    var msg = MndpMessage();
    msg.type = json['type'];
    msg.ttl = json['ttl'];
    msg.sequence = json['sequence'];
    msg.macAddress = json['mac_address'];
    msg.identity = json['identity'];
    msg.version = json['version'];
    msg.platform = json['platform'];
    msg.uptime = Duration(seconds: json['uptime'] as int? ?? 0);
    msg.softwareId = json['software_id'];
    msg.boardName = json['board_name'];
    msg.unpack = json['unpack'];
    msg.interfaceName = json['interface_name'];
    msg.unicastIpv6Address = json['unicast_ipv6_address'];
    msg.unicastIpv4Address = json['unicast_ipv4_address'];
    return msg;
  }
}
