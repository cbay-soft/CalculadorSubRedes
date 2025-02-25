class SubnetCalculator {
  // Calcula el número máximo de hosts que se pueden tener con una máscara de subred (CIDR)
  static int calculateHosts(String networkCIDR) {
    final parts = networkCIDR.split('/');
    int cidr = int.parse(parts[1]);
    // Número total de direcciones IP posibles
    int totalIPs = (1 << (32 - cidr));
    // Restamos 2 por la dirección de red y la de broadcast
    return totalIPs - 2;
  }

  // Calcula el número máximo de subredes posibles con una máscara de subred (CIDR)
  static int calculateSubnets(String networkCIDR) {
    final parts = networkCIDR.split('/');
    int cidr = int.parse(parts[1]);
    int subnetBits = cidr - 24; // Se asume que la red es de clase C (CIDR >= 24)
    if (subnetBits < 0) return 0;
    return (1 << subnetBits);
  }

  // Ajusta el número de hosts solicitados y proporciona opciones cercanas
  static List<int> adjustHosts(int requestedHosts) {
    if (requestedHosts < 2) return [2];
    List<int> options = [];
    int closestLower = (requestedHosts / 2).floor() * 2;
    int closestUpper = closestLower + 2;
    if (closestLower >= 2) options.add(closestLower);
    options.add(closestUpper);
    return options;
  }

  // Ajusta el número de subredes solicitadas y proporciona opciones cercanas
  static List<int> adjustSubnets(int requestedSubnets) {
    if (requestedSubnets < 1) return [1];
    List<int> options = [];
    int closestLower = (requestedSubnets / 2).floor() * 2;
    int closestUpper = closestLower + 1;
    if (closestLower >= 1) options.add(closestLower);
    options.add(closestUpper);
    return options;
  }

  // Calcula la nueva máscara de subred en función del número de subredes
  static String calculateCIDRFromSubnets(int subnets) {
    int bits = (subnets > 1) ? (subnets - 1).bitLength : 0;
    int cidr = 24 + bits;
    return "/$cidr";
  }

  // Calcula el número de hosts disponibles por subred en función de las subredes
  static int calculateHostsFromSubnets(int subnets) {
    int bits = (subnets > 1) ? (subnets - 1).bitLength : 0;
    return (1 << (32 - (24 + bits))) - 2;
  }
}
