import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

typedef UpgradeAnnouncerBottomSheetBuilder = Widget Function(
    BuildContext context, VoidCallback goToAppStore, String? releaseNotes);

class UpgradeAnnouncer extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Upgrader? upgrader;
  final Color? backgroundColor;
  final double bottomSheetHeightFactor;
  final Color? bottomSheetBackgroundColor;
  final UpgradeAnnouncerBottomSheetBuilder? bottomSheetBuilder;
  final TextStyle? bottomSheetTitleTextStyle;
  final TextStyle? bottomSheetReleaseNotesTextStyle;
  final TextStyle? titleTextStyle;
  final IconData? infoIcon;
  final Color? infoIconColor;
  final IconData? downloadIcon;
  final Color? downloadIconColor;
  final bool forceShow;
  final Widget child;

  const UpgradeAnnouncer({
    super.key,
    required this.scaffoldMessengerKey,
    this.upgrader,
    this.backgroundColor,
    this.bottomSheetHeightFactor = .6,
    this.bottomSheetBackgroundColor,
    this.bottomSheetBuilder,
    this.bottomSheetTitleTextStyle,
    this.bottomSheetReleaseNotesTextStyle,
    this.titleTextStyle,
    this.infoIcon,
    this.infoIconColor,
    this.downloadIcon,
    this.downloadIconColor,
    this.forceShow = false,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _UpgradeAnnouncer();
}

class _UpgradeAnnouncer extends State<UpgradeAnnouncer> {
  late final _upgrader = widget.upgrader ?? Upgrader();

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

      if (versionInfo != null &&
          appStoreVersion != null &&
          installedVersion != null) {
        if (appStoreVersion > installedVersion || widget.forceShow) {
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
                IconButton(
                  onPressed: _upgrader.sendUserToAppStore,
                  icon: Icon(widget.downloadIcon ?? Icons.download,
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
    showModalBottomSheet(
      backgroundColor: widget.bottomSheetBackgroundColor,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext c) {
        return widget.bottomSheetBuilder?.call(
              context,
              upgrader.sendUserToAppStore,
              releaseNotes,
            ) ??
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      widget.bottomSheetHeightFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 0, right: 20, left: 20, bottom: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          UpgraderMessages().newInThisVersion,
                          style: widget.bottomSheetTitleTextStyle ??
                              const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          onPressed: upgrader.sendUserToAppStore,
                          icon: Icon(widget.downloadIcon ?? Icons.download,
                              color: widget.downloadIconColor),
                        )
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          top: 0, right: 20, left: 20, bottom: 20),
                      child: Text(
                        style: widget.bottomSheetReleaseNotesTextStyle ??
                            const TextStyle(fontSize: 14),
                        releaseNotes ??
                            UpgraderMessages().noAvailableReleaseNotes,
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
