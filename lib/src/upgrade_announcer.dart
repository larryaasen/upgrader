import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

typedef UpgradeAnnouncerBottomSheetBuilder = Widget Function(
    BuildContext context,
    VoidCallback goToAppStore,
    Future<String?> releaseNotes);
typedef UpgradeAnnouncerEnforceUpgradeBuilder = Widget Function(
    BuildContext context, VoidCallback goToAppStore);

class UpgradeAnnouncer extends StatefulWidget {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Upgrader? upgrader;
  final UpgradeAnnouncerBottomSheetBuilder? bottomSheetBuilder;
  final Color? backgroundColor;
  final double bottomSheetHeightFactor;
  final Color? bottomSheetBackgroundColor;
  final Color? bottomSheetLoadingIndicatorColor;
  final TextStyle? bottomSheetTitleTextStyle;
  final TextStyle? bottomSheetReleaseNotesTextStyle;
  final UpgradeAnnouncerEnforceUpgradeBuilder? enforceUpgradeBuilder;
  final Color? enforceUpgradeBackgroundColor;
  final TextStyle? enforceUpgradeTextStyle;
  final TextStyle? titleTextStyle;
  final IconData? infoIcon;
  final Color? infoIconColor;
  final IconData? downloadIcon;
  final Color? downloadIconColor;

  /// When set to true this will enforce an upgrade based on the
  /// [Upgrader.minAppVersion] version
  final bool enforceUpgrade;
  final bool debugEnforceUpgrade;
  final bool debugAvailableUpgrade;
  final Widget child;

  const UpgradeAnnouncer({
    super.key,
    required this.scaffoldMessengerKey,
    this.upgrader,
    this.backgroundColor,
    this.bottomSheetBuilder,
    this.bottomSheetHeightFactor = .6,
    this.bottomSheetBackgroundColor,
    this.bottomSheetLoadingIndicatorColor,
    this.bottomSheetTitleTextStyle,
    this.bottomSheetReleaseNotesTextStyle,
    this.enforceUpgradeBuilder,
    this.enforceUpgradeBackgroundColor,
    this.enforceUpgradeTextStyle,
    this.titleTextStyle,
    this.infoIcon,
    this.infoIconColor,
    this.downloadIcon,
    this.downloadIconColor,
    this.enforceUpgrade = false,
    this.debugEnforceUpgrade = false,
    this.debugAvailableUpgrade = false,
    required this.child,
  });

  static void showReleaseNotesBottomSheet({
    required BuildContext context,
    Upgrader? upgrader,
    UpgradeAnnouncerBottomSheetBuilder? bottomSheetBuilder,
    double bottomSheetMaxHeightFactor = 0.6,
    Color? bottomSheetBackgroundColor,
    Color? bottomSheetLoadingIndicatorColor,
    TextStyle? bottomSheetTitleTextStyle,
    TextStyle? bottomSheetReleaseNotesTextStyle,
    bool showDownloadIcon = false,
    IconData? downloadIcon,
    Color? downloadIconColor,
  }) async {
    if (context.mounted) {
      upgrader = upgrader ?? Upgrader();

      Future<String?> getReleaseNotes(Upgrader upgrader) async {
        await upgrader.initialize();

        final versionInfo = await upgrader.updateVersionInfo();

        return versionInfo?.releaseNotes;
      }

      final releaseNotes = getReleaseNotes(upgrader);

      await showModalBottomSheet(
        backgroundColor: bottomSheetBackgroundColor,
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (BuildContext c) {
          return FutureBuilder(
              future: releaseNotes,
              builder: (context, snapshot) =>
                  bottomSheetBuilder?.call(
                    context,
                    upgrader!.sendUserToAppStore,
                    releaseNotes,
                  ) ??
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedCrossFade(
                        firstChild: SizedBox(
                          height: 150,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: bottomSheetLoadingIndicatorColor),
                          ),
                        ),
                        secondChild: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height *
                                  bottomSheetMaxHeightFactor),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 20, right: 20, left: 20, bottom: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      upgrader!
                                          .determineMessages(context)
                                          .newInThisVersion,
                                      style: bottomSheetTitleTextStyle ??
                                          const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600),
                                    ),
                                    if (showDownloadIcon)
                                      IconButton(
                                        onPressed: upgrader.sendUserToAppStore,
                                        icon: Icon(
                                            downloadIcon ?? Icons.download,
                                            color: downloadIconColor),
                                      )
                                  ],
                                ),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      style: bottomSheetReleaseNotesTextStyle ??
                                          const TextStyle(fontSize: 14),
                                      snapshot.data ??
                                          upgrader
                                              .determineMessages(context)
                                              .noAvailableReleaseNotes,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        crossFadeState:
                            snapshot.connectionState == ConnectionState.waiting
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 500)),
                  ));
        },
      );
    }
  }

  @override
  State<StatefulWidget> createState() => _UpgradeAnnouncer();
}

class _UpgradeAnnouncer extends State<UpgradeAnnouncer> {
  late final _upgrader = widget.upgrader ?? Upgrader();

  bool _shouldEnforceUpgrade = false;

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
    return Stack(
      children: [
        AbsorbPointer(absorbing: _shouldEnforceUpgrade, child: widget.child),
        if (_shouldEnforceUpgrade)
          Container(
            color: Colors.black.withOpacity(.5),
          ),
        if (_shouldEnforceUpgrade)
          Material(
            color: Colors.transparent,
            child: widget.enforceUpgradeBuilder
                    ?.call(context, _upgrader.sendUserToAppStore) ??
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: widget.enforceUpgradeBackgroundColor ??
                              Theme.of(context).canvasColor,
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(widget.infoIcon ?? Icons.info_outline,
                                    color: widget.infoIconColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    UpgraderMessages().upgradeEnforce,
                                    style: widget.enforceUpgradeTextStyle ??
                                        const TextStyle(
                                          fontSize: 14,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.all(16)),
                            Material(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _upgrader.sendUserToAppStore,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        UpgraderMessages().buttonTitleUpdate,
                                        style: widget.enforceUpgradeTextStyle ??
                                            const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                      ),
                                      const Padding(padding: EdgeInsets.all(2)),
                                      Icon(
                                          widget.downloadIcon ?? Icons.download,
                                          color: widget.downloadIconColor),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          )
      ],
    );
  }

  void _checkForUpgrade({bool dismissMaterialBanners = false}) {
    _upgrader.initialize().then((initialized) async {
      final versionInfo = await _upgrader.updateVersionInfo();
      final appStoreVersion = versionInfo?.appStoreVersion;
      final installedVersion = versionInfo?.installedVersion;
      final minAppVersion = _upgrader.versionInfo?.minAppVersion;

      if (versionInfo != null &&
          appStoreVersion != null &&
          installedVersion != null) {
        if (appStoreVersion > installedVersion ||
            (widget.debugAvailableUpgrade || widget.debugEnforceUpgrade)) {
          if (widget.enforceUpgrade || widget.debugEnforceUpgrade) {
            setState(() {
              _shouldEnforceUpgrade =
                  minAppVersion != null && minAppVersion > installedVersion ||
                      widget.debugEnforceUpgrade;
            });
          }

          _showMaterialBanner(dismissMaterialBanners);
        }
      }
    });
  }

  void _showMaterialBanner(bool dismissMaterialBanners) {
    if (!_shouldEnforceUpgrade) {
      if (dismissMaterialBanners) {
        widget.scaffoldMessengerKey.currentState?.clearMaterialBanners();
      }

      widget.scaffoldMessengerKey.currentState?.showMaterialBanner(
        MaterialBanner(
          dividerColor: Colors.transparent,
          backgroundColor: widget.backgroundColor ?? Colors.green,
          content: Builder(
            builder: (context) => TextButton(
              onPressed: mounted
                  ? () => UpgradeAnnouncer.showReleaseNotesBottomSheet(
                        context: context,
                        upgrader: _upgrader,
                        bottomSheetBuilder: widget.bottomSheetBuilder,
                        bottomSheetMaxHeightFactor:
                            widget.bottomSheetHeightFactor,
                        bottomSheetBackgroundColor:
                            widget.bottomSheetBackgroundColor,
                        bottomSheetLoadingIndicatorColor:
                            widget.bottomSheetLoadingIndicatorColor,
                        bottomSheetTitleTextStyle:
                            widget.bottomSheetTitleTextStyle,
                        bottomSheetReleaseNotesTextStyle:
                            widget.bottomSheetReleaseNotesTextStyle,
                        downloadIcon: widget.downloadIcon,
                        downloadIconColor: widget.downloadIconColor,
                        showDownloadIcon: true,
                      )
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
}
