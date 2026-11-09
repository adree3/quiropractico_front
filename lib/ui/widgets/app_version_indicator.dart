import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionIndicator extends StatefulWidget {
  const AppVersionIndicator({super.key});

  @override
  State<AppVersionIndicator> createState() => _AppVersionIndicatorState();
}

class _AppVersionIndicatorState extends State<AppVersionIndicator> {
  static const String gitHash = String.fromEnvironment('GIT_HASH', defaultValue: 'dev-local');
  static const String buildTime = String.fromEnvironment('BUILD_TIME', defaultValue: 'Local Build');

  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _version = '1.0.0';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      'v$_version • Hash: $gitHash • $buildTime',
      style: TextStyle(
        fontSize: 10.5,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
    );
  }
}

