import 'package:flutter/material.dart';

/// Observador de rutas global: permite que el inicio se entere
/// cuando el jugador VUELVE a él (salió de una partida o del
/// lobby) para re-ofrecer la sala activa. Antes el aviso solo se
/// comprobaba al abrir la app: en la APK, donde el inicio ya
/// existe bajo la partida, el aviso nunca aparecía (reporte del
/// usuario, 23-oct).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
