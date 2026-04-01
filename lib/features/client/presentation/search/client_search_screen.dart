import 'package:flutter/material.dart';

import '../../../feed/presentation/screens/discover_screen.dart';

/// Onglet « Recherche » du shell client — alias de [DiscoverScreen] (Découvrir).
class ClientSearchScreen extends StatelessWidget {
  const ClientSearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const DiscoverScreen();
}
