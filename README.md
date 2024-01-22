## Introduction

This is a Flutter plugin to discover network devices using the MikroTik Neighbor Discovery Protocol (MNDP).

## Usage

To use this plugin, add `mndp_protocol` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/mndp_protocol).

The plugin is responsible for sending broadcast/multicast requests to the mikrotiks devices on the network. 
These devices then receive these requests and respond with their information. 
The plugin then decodes the response and send a `MndpMessage` object in a Stream.

The `MndpMessage` object contains the following fields:

| Field                | Description                                   | Example                |
|----------------------|-----------------------------------------------|------------------------|
| `type`               | Type of message                               | 0                      |
| `ttl`                | Time to live of the message                   | 0                      |
| `sequence`           | Message sequence number                       | 7                      |
| `mac_address`        | MAC address of the device                     | 48:8F:5A:AD:7E:E9      |
| `identity`           | Identity of the device                        | MikroTik               |
| `version`            | Software version of the device                | 6.45.9 (long-term)     |
| `platform`           | Hardware platform                             | MikroTik               |
| `uptime`             | Time since last reboot (in seconds)           | 201                      |
| `software_id`        | Software identifier                           | H5ZN-JERX              |
| `board_name`         | Hardware model name                           | RB931-2nD              |
| `unpack`             | Unpack status of the message                  | 0                      |
| `interface_name`     | Name of the network interface                 | bridgeLocal/ether2     |
| `unicast_ipv4_address` | Unicast IPv4 address of the device           | 192.168.1.125          |

The plugin also searches for additional information about the device from its name (image, commercial name, link in the description on the mikrotik page)

## Example


<div style="background-color: white;">
    <img src="https://raw.githubusercontent.com/Eitol/mikrotik_mndp/main/doc/img.jpg" alt="App Example Screenshot">
</div>

![doc/app.gif](https://raw.githubusercontent.com/Eitol/mikrotik_mndp/main/doc/app.gif)

```dart
import 'package:flutter/material.dart';
import 'package:mikrotik_mndp/decoder.dart';
import 'package:mikrotik_mndp/product_info_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'message.dart';
import 'listener.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Mikrotik MNDP Demo',
      home: MyHomePage(title: 'Mikrotik MNDP Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<MndpMessage> _messages = [];

  @override
  Widget build(BuildContext context) {
    var productProvider = MikrotikProductInfoProvider();
    var decoder = MndpMessageDecoderImpl(productProvider);
    MNDPListener mndpListener = MNDPListener(decoder);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(      
          children: <Widget>[
            StreamBuilder(
                stream: mndpListener.listen(),
                builder: (BuildContext context,
                    AsyncSnapshot<MndpMessage> snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    var found = false;
                    for (var i = 0; i < _messages.length; i++) {
                      if (_messages[i].macAddress ==
                          snapshot.data!.macAddress) {
                        _messages[i] = snapshot.data!;
                        found = true;
                        break;
                      }
                    }
                    if (!found) {
                      _messages.add(snapshot.data!);
                    }
                    return Column(
                      children: _messages
                          .map((message) => MndpMessageWidget(message: message))
                          .toList(),
                    );
                  }
                  return const Text('Awaiting MNDP messages...');
                }),
          ],
        ),
      ),
    );
  }
}

class MndpMessageWidget extends StatelessWidget {
  final MndpMessage message;

  const MndpMessageWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Visibility(
              visible: message.productInfo?.imageUrl != null,
              child: SizedBox(
                height: 200,
                child: Image.network(message.productInfo!.imageUrl),
              ),
            ),
            ListTile(
              title: Text(message.boardName ?? 'Desconocido'),
              subtitle: Text('MAC: ${message.macAddress ?? 'N/A'}'),
            ),
            _infoRow('Commercial Name', message.productInfo?.name ?? 'N/A'),
            _infoRow('Board Name', message.boardName),
            _infoRow('MAC Address', message.macAddress),
            _infoRow('Identity', message.identity),
            _infoRow('IPv4 Address', message.unicastIpv4Address),
            _infoRow('IPv6 Address', message.unicastIpv6Address),
            _infoRow('Version', message.version),
            _infoRow('Platform', message.platform),
            _infoRow('Uptime', _formatDuration(message.uptime)),
            _infoRow('Software ID', message.softwareId),
            InkWell(
              onTap: () async {
                var url = message.productInfo?.productUrl ?? '';
                var uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                "Page Link",
                style: TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),       
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    return duration != null
        ? '${duration.inHours}h ${duration.inMinutes % 60}m'
        : 'N/A';
  }
}
```

