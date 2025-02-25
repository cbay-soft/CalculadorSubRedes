import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Clase para representar una opción de subnetting
class Option {
  final int newCIDR;
  final int subnets;
  final int hosts;
  Option(this.newCIDR, this.subnets, this.hosts);

  @override
  String toString() {
    return "/$newCIDR: $subnets subredes, $hosts hosts cada una";
  }
}

// Genera una lista de opciones válidas en base al CIDR original
List<Option> generateOptions(int originalCIDR) {
  List<Option> options = [];
  // Genera opciones desde el CIDR original hasta /30 (puedes ajustar el límite)
  for (int newCIDR = originalCIDR; newCIDR <= 30; newCIDR++) {
    int hosts = (1 << (32 - newCIDR)) - 2;
    int subnets = newCIDR > originalCIDR ? (1 << (newCIDR - originalCIDR)) : 1;
    options.add(Option(newCIDR, subnets, hosts));
  }
  return options;
}

// Determina la clase de la red basándose en el primer octeto
String getNetworkClass(String ip) {
  int firstOctet = int.tryParse(ip.split('.')[0]) ?? 0;
  if (firstOctet >= 1 && firstOctet <= 126) {
    return "Clase A";
  } else if (firstOctet >= 128 && firstOctet <= 191) {
    return "Clase B";
  } else if (firstOctet >= 192 && firstOctet <= 223) {
    return "Clase C";
  }
  return "Otra";
}

// Convierte un CIDR a máscara de subred en notación decimal
String cidrToMask(int cidr) {
  int mask = 0xffffffff << (32 - cidr) & 0xffffffff;
  return "${(mask >> 24) & 0xff}.${(mask >> 16) & 0xff}.${(mask >> 8) & 0xff}.${mask & 0xff}";
}

// Convierte una IP en notación "a.b.c.d" a un entero
int ipToInt(String ip) {
  List<String> parts = ip.split('.');
  return (int.parse(parts[0]) << 24) |
  (int.parse(parts[1]) << 16) |
  (int.parse(parts[2]) << 8) |
  int.parse(parts[3]);
}

// Convierte un entero a notación IP "a.b.c.d"
String intToIp(int ipInt) {
  return "${(ipInt >> 24) & 0xff}.${(ipInt >> 16) & 0xff}.${(ipInt >> 8) & 0xff}.${ipInt & 0xff}";
}

/// Calcula los detalles de cada subred a partir de la IP original, el CIDR original y el nuevo CIDR.
/// Retorna una lista de mapas, uno por cada subred.
List<Map<String, String>> computeSubnetsDetails(String ip, int originalCIDR, int newCIDR) {
  int ipInt = ipToInt(ip);
  int maskOriginal = 0xffffffff << (32 - originalCIDR) & 0xffffffff;
  int networkOriginal = ipInt & maskOriginal;
  int blockSize = 1 << (32 - newCIDR);
  int numSubnets = 1 << (newCIDR - originalCIDR);
  List<Map<String, String>> detailsList = [];
  String subnetMask = cidrToMask(newCIDR);
  for (int i = 0; i < numSubnets; i++) {
    int network_i = networkOriginal + i * blockSize;
    int broadcast_i = network_i + blockSize - 1;
    String networkStr = intToIp(network_i);
    String broadcastStr = intToIp(broadcast_i);
    String usable = (blockSize > 2)
        ? "${intToIp(network_i + 1)} - ${intToIp(broadcast_i - 1)}"
        : "N/A";
    detailsList.add({
      "subnetNumber": "${i + 1}",
      "network": networkStr,
      "broadcast": broadcastStr,
      "usable": usable,
      "subnetMask": subnetMask,
    });
  }
  return detailsList;
}

/// Construye el widget que muestra los detalles de cada subred en una columna.
Widget buildSubnetsDetails(String ip, int originalCIDR, int newCIDR) {
  List<Map<String, String>> detailsList = computeSubnetsDetails(ip, originalCIDR, newCIDR);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: detailsList.map((subnet) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Subred ${subnet['subnetNumber']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "Dirección de red: ${subnet['network']}"),
            Text(
              "Dirección de broadcast: ${subnet['broadcast']}"),
            Text(
              "Rango de IPs para hosts: ${subnet['usable']}"),
            Text("Máscara de subred: ${subnet['subnetMask']}"),
          ],
        ),
      );
    }).toList(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CALCULADORA DE SUBREDES',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SubnetCalculatorPage(),
    );
  }
}

class SubnetCalculatorPage extends StatefulWidget {
  const SubnetCalculatorPage({super.key});
  @override
  State<SubnetCalculatorPage> createState() => _SubnetCalculatorPageState();
}

class _SubnetCalculatorPageState extends State<SubnetCalculatorPage> {
  final TextEditingController _cidrController = TextEditingController();
  String _networkInfo = "";
  List<Option> _options = [];
  String _configMode = "subredes"; // "subredes" o "hosts"
  Option? _selectedOption;
  bool _isIpValid = false;

  // Se valida automáticamente mientras se escribe.
  void _updateNetworkInfo() {
    String input = _cidrController.text.trim();
    if (!input.contains('/')) {
      setState(() {
        _networkInfo = "";
        _options = [];
        _selectedOption = null;
        _isIpValid = false;
      });
      return;
    }
    List<String> parts = input.split('/');
    if (parts.length != 2) {
      setState(() {
        _networkInfo = "";
        _options = [];
        _selectedOption = null;
        _isIpValid = false;
      });
      return;
    }
    String ip = parts[0];
    int? cidr = int.tryParse(parts[1]);
    if (cidr == null || cidr < 0 || cidr > 32) {
      setState(() {
        _networkInfo = "";
        _options = [];
        _selectedOption = null;
        _isIpValid = false;
      });
      return;
    }
    List<String> ipParts = ip.split('.');
    if (ipParts.length != 4) {
      setState(() {
        _networkInfo = "";
        _options = [];
        _selectedOption = null;
        _isIpValid = false;
      });
      return;
    }
    bool validOctets = ipParts.every((octet) {
      int? val = int.tryParse(octet);
      return val != null && val >= 0 && val <= 255;
    });
    if (!validOctets) {
      setState(() {
        _networkInfo = "";
        _options = [];
        _selectedOption = null;
        _isIpValid = false;
      });
      return;
    }
    int availableHosts = (1 << (32 - cidr)) - 2;
    String netClass = getNetworkClass(ip);
    String mask = cidrToMask(cidr);
    String info =
        "IP: $ip\nCIDR: /$cidr\nMáscara: $mask\nClase: $netClass\nHosts disponibles: $availableHosts";
    List<Option> options = generateOptions(cidr);
    setState(() {
      _networkInfo = info;
      _options = options;
      _isIpValid = true;
      _selectedOption = null;
    });
  }

  // Reinicia el estado para ingresar otra IP
  void _reset() {
    setState(() {
      _cidrController.clear();
      _networkInfo = "";
      _options = [];
      _selectedOption = null;
      _isIpValid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget subnetDetailsWidget = const SizedBox();
    if (_selectedOption != null) {
      List<String> parts = _cidrController.text.trim().split('/');
      String ip = parts[0];
      int originalCIDR = int.parse(parts[1]);
      int newCIDR = _selectedOption!.newCIDR;
      subnetDetailsWidget = buildSubnetsDetails(ip, originalCIDR, newCIDR);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("CALCULADORA DE SUBREDES"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _cidrController,
              decoration: const InputDecoration(
                labelText: "Ingrese la red en formato CIDR (ej. 192.168.1.0/24)",
              ),
              keyboardType: TextInputType.text,
              onChanged: (value) {
                _updateNetworkInfo();
              },
            ),
            const SizedBox(height: 20),
            // Muestra la información de la red solo si es válida
            if (_isIpValid)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _networkInfo,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Muestra los controles de modo y opciones
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: "subredes",
                        groupValue: _configMode,
                        onChanged: (value) {
                          setState(() {
                            _configMode = value!;
                            _selectedOption = null;
                          });
                        },
                      ),
                      const Text("Configurar por Subredes"),
                      Radio<String>(
                        value: "hosts",
                        groupValue: _configMode,
                        onChanged: (value) {
                          setState(() {
                            _configMode = value!;
                            _selectedOption = null;
                          });
                        },
                      ),
                      const Text("Configurar por Hosts"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_options.isNotEmpty)
                    DropdownButton<Option>(
                      hint: Text(_configMode == "subredes"
                          ? "Seleccione una opción "
                          : "Seleccione una opción"),
                      value: _selectedOption,
                      items: _options.map((option) {
                        String text = _configMode == "subredes"
                            ? "${option.subnets} subred/es, (CIDR: /${option.newCIDR})"
                            : "${option.hosts} hosts, (CIDR: /${option.newCIDR})";
                        return DropdownMenuItem<Option>(
                          value: option,
                          child: Text(text),
                        );
                      }).toList(),
                      onChanged: (Option? newOption) {
                        setState(() {
                          _selectedOption = newOption;
                        });
                      },
                    ),
                ],
              ),
            const SizedBox(height: 20),
            // Si se seleccionó una opción, muestra el resumen y los detalles de cada subred
            if (_selectedOption != null) ...[
              Text(
                "Has seleccionado: ${_configMode == "subredes" ? _selectedOption!.subnets : _selectedOption!.hosts} ${_configMode == "subredes" ? "subredes" : "hosts"} con nuevo CIDR: /${_selectedOption!.newCIDR}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Detalles de cada subred:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subnetDetailsWidget,
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _reset,
                child: const Text("Ingresar nueva IP"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
