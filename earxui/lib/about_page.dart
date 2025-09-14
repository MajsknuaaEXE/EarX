import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'localization.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _text = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final txt = await rootBundle.loadString('assets/about/ABOUT.txt');
      if (mounted) setState(() { _text = txt; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _text = 'Failed to load license text.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('about')), backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _text,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ),
    );
  }
}

