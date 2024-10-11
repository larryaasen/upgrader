import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

class UpgradeAnnouncer extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Color? backgroundColor;
  final Color? bottomSheetBackgroundColor;
  final Widget Function(
          BuildContext context, Upgrader upgrader, String releaseNotes)?
      bottomSheetBuilder;
  final TextStyle? titleTextStyle;
  final TextStyle? bottomSheetTitleTextStyle;
  final TextStyle? bottomSheetReleaseNotesTextStyle;
  final IconData? infoIcon;
  final Color? infoIconColor;
  final IconData? downloadIcon;
  final Color? downloadIconColor;
  final Widget child;

  const UpgradeAnnouncer({
    super.key,
    required this.scaffoldMessengerKey,
    this.backgroundColor,
    this.bottomSheetBackgroundColor,
    this.bottomSheetBuilder,
    this.titleTextStyle,
    this.bottomSheetTitleTextStyle,
    this.bottomSheetReleaseNotesTextStyle,
    this.infoIcon,
    this.infoIconColor,
    this.downloadIcon,
    this.downloadIconColor,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _UpgradeAnnouncer();
}

class _UpgradeAnnouncer extends State<UpgradeAnnouncer> {
  final _upgrader = Upgrader();

  @override
  void initState() {
    _checkForUpgrade();

    AppLifecycleListener(onResume: () {
      _checkForUpgrade(dismissMaterialBanners: true);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  _checkForUpgrade({bool dismissMaterialBanners = false}) {
    _upgrader.initialize().then((initialized) async {
      final versionInfo = await _upgrader.updateVersionInfo();
      final appStoreVersion = versionInfo?.appStoreVersion;
      final installedVersion = versionInfo?.installedVersion;
      final releaseNotes = versionInfo?.releaseNotes;

      if (true) {
        if (true) {
          if (dismissMaterialBanners) {
            widget.scaffoldMessengerKey.currentState?.clearMaterialBanners();
          }

          widget.scaffoldMessengerKey.currentState?.showMaterialBanner(
            MaterialBanner(
              content: Builder(
                builder: (context) => TextButton(
                  onPressed: mounted
                      ? () => _infoBottomSheet(context, releaseNotes, _upgrader)
                      : null,
                  child: Row(
                    children: [
                      Icon(widget.infoIcon ?? Icons.info_outline,
                          color: widget.infoIconColor ?? Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        UpgraderMessages().upgradeAvailable,
                        style: widget.titleTextStyle ??
                            const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              backgroundColor: widget.backgroundColor ?? Colors.green,
              actions: <Widget>[
                TextButton(
                  onPressed: _upgrader.sendUserToAppStore,
                  child: Icon(widget.downloadIcon ?? Icons.download,
                      color: widget.downloadIconColor ?? Colors.white),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  _infoBottomSheet(
      BuildContext context, String? releaseNotes, Upgrader upgrader) {
    if (releaseNotes == null) return;
    showModalBottomSheet(
      backgroundColor: widget.bottomSheetBackgroundColor,
      context: context,
      enableDrag: false,
      builder: (BuildContext c) {
        return widget.bottomSheetBuilder?.call(
              context,
              upgrader,
              releaseNotes,
            ) ??
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        UpgraderMessages().newInThisVersion,
                        style: widget.bottomSheetTitleTextStyle ??
                            const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: upgrader.sendUserToAppStore,
                        icon: Icon(widget.downloadIcon ?? Icons.download,
                            color: widget.downloadIconColor ?? Colors.white),
                      )
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        style: widget.bottomSheetTitleTextStyle ??
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                        releaseNotes, // TODO: Create translation
                      ),
                    ),
                  ),
                ],
              ),
            );
      },
    );
  }
}
