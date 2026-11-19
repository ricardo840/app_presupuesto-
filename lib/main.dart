import 'package:cupertino_ui/cupertino_ui.dart';

void main() {
  runApp(const LinForgeApp());
}

/// Pantalla mínima mientras se construye la app (F0-T2).
/// El arranque, el tema y la navegación llegan en F4-T1.
class LinForgeApp extends StatelessWidget {
  const LinForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'LinForge',
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('LinForge')),
        child: Center(child: Text('Cotizador de herrería')),
      ),
    );
  }
}
