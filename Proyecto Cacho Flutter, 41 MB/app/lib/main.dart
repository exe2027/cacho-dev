import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/audio.dart';
import 'state/route_observer.dart';
import 'state/settings.dart';
import 'state/wallet.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.instance.load();
  await Wallet.instance.load();
  runApp(const CachoApp());
}

class CachoApp extends StatelessWidget {
  const CachoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cacho · El Dudo Chileno',
      debugShowCheckedModeBanner: false,
      theme: buildCachoTheme(),
      navigatorObservers: [appRouteObserver],
      // Navegación de menú: SIN rutas nombradas ni onGenerateRoute
      // (las pantallas navegan con rutas directas). La transición
      // compartida vive en widgets/menu_transitions.dart
      // (pushMenuPage / MenuPageRoute, fundido + deslizamiento
      // 150–600 ms, instantánea con animaciones apagadas o
      // reduce-motion); aquí no hay nada que cablear.
      // iOS bloquea el audio web hasta el primer gesto: el primer
      // toque en cualquier parte desbloquea el contexto de sonido.
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => AudioService.instance.unlock(),
        child: _PortraitGate(child: child),
      ),
      home: const HomeScreen(),
    );
  }
}

/// TODO HORIZONTAL (orden 26-oct): en portrait NO se muestra ningún
/// layout vertical. Este gate vive SOLO en `main.dart` y solo decide
/// qué se MUESTRA: si el ancho es mayor o igual que el alto, pasa el
/// hijo tal cual (navegación y estado intactos); si es portrait,
/// muestra esta pantalla de aviso de girar en lugar de la app.
///
/// No sustituye rutas ni estado: al girar a landscape, el `MediaQuery`
/// reconstruye el gate y reaparece exactamente la pantalla en la que
/// estaba el usuario. El arranque no se toca (`main()` sigue siendo
/// Settings + Wallet y luego `runApp`).
///
/// Tensión honesta, pendiente del coordinador: el patrón anterior
/// `RotateNotice.confirmIfPortrait` (widgets/rotate_notice.dart,
/// archivo prohibido para este agente) ofrecía "Jugar igual en
/// vertical" y lo recordaba en sesión; con este gate duro ese opt-out
/// ya no se alcanza en portrait (en landscape devuelve `true`
/// inmediato y sigue siendo no-op). Si el coordinador quiere mantener
/// alguna vía para quien no pueda girar, debe decidirlo él y tocar
/// ese archivo; este agente NO añade un botón de seguir en vertical
/// porque contradiría la orden TODO horizontal.
class _PortraitGate extends StatelessWidget {
  final Widget? child;
  const _PortraitGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= size.height) {
      return child ?? const SizedBox.shrink();
    }
    return Scaffold(
      body: DecoratedBox(
        decoration: menuDecoration,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.screen_rotation,
                      size: 64, color: CachoColors.gold),
                  const SizedBox(height: 20),
                  Text(
                    'GIRA EL CELULAR',
                    textAlign: TextAlign.center,
                    style: titleStyle.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cacho se juega en horizontal. Gira el celular o '
                    'ensancha la ventana para seguir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: CachoColors.ivory),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Al girar, vuelves exactamente a donde estabas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
