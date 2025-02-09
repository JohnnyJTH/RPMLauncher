import 'dart:io';
import 'package:pub_semver/pub_semver.dart';
import 'package:rpmlauncher/Mod/CurseForge/ModPackHandler.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:rpmlauncher/Model/Game/MinecraftVersion.dart';
import 'package:rpmlauncher/Screen/CurseForgeModPack.dart';
import 'package:rpmlauncher/Screen/FTBModPack.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Screen/RecommendedModpackScreen.dart';
import 'package:rpmlauncher/Utility/Extensions.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/Theme.dart';
import 'package:rpmlauncher/Widget/Dialog/UnSupportedForgeVersion.dart';
import 'package:rpmlauncher/Widget/RWLLoading.dart';
import 'package:split_view/split_view.dart';

import 'package:rpmlauncher/Utility/Data.dart';
import 'DownloadGameDialog.dart';

class VersionSelection extends StatefulWidget {
  final MinecraftSide side;

  const VersionSelection({Key? key, required this.side}) : super(key: key);

  @override
  _VersionSelectionState createState() => _VersionSelectionState();
}

class _VersionSelectionState extends State<VersionSelection> {
  int _selectedIndex = 0;
  bool showRelease = true;
  bool showSnapshot = false;
  bool versionManifestLoading = true;
  TextEditingController versionSearchController = TextEditingController();

  String modLoaderName = I18n.format("version.list.mod.loader.vanilla");
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    versionSearchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    _widgetOptions = <Widget>[
      SplitView(
        children: [
          FutureBuilder(
              future: MCVersionManifest.formLoaderType(
                  ModLoaderUttily.getByI18nString(modLoaderName)),
              builder: (BuildContext context,
                  AsyncSnapshot<MCVersionManifest> snapshot) {
                versionManifestLoading =
                    snapshot.connectionState != ConnectionState.done;

                if (!versionManifestLoading && snapshot.hasData) {
                  List<MCVersion> versions = snapshot.data!.versions;
                  List<MCVersion> formattedVersions = [];
                  formattedVersions = versions.where((_version) {
                    bool inputVersionID =
                        _version.id.contains(versionSearchController.text);
                    switch (_version.type.name) {
                      case "release":
                        return showRelease && inputVersionID;
                      case "snapshot":
                        return showSnapshot && inputVersionID;
                      default:
                        return false;
                    }
                  }).toList();

                  return ListView.builder(
                      itemCount: formattedVersions.length,
                      itemBuilder: (context, index) {
                        final MCVersion version = formattedVersions[index];
                        return ListTile(
                          title: Text(version.id),
                          onTap: () {
                            ModLoader _loader =
                                ModLoaderUttily.getByI18nString(modLoaderName);

                            // TODO: 支援啟動 Forge 遠古版本
                            if (_loader == ModLoader.forge &&
                                version.comparableVersion < Version(1, 7, 0)) {
                              showDialog(
                                  context: context,
                                  builder: (context) => UnSupportedForgeVersion(
                                      gameVersion: version.id));
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return DownloadGameDialog(
                                        "${_loader.name.toCapitalized()}-${version.id}",
                                        version,
                                        _loader,
                                        widget.side);
                                  });
                            }
                          },
                        );
                      });
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else {
                  return Center(child: RWLLoading());
                }
              }),
          Column(
            children: [
              SizedBox(height: 10),
              SizedBox(
                height: 45,
                width: 200,
                child: TextField(
                  controller: versionSearchController,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: I18n.format("version.list.filter"),
                  ),
                  onEditingComplete: () {
                    setState(() {});
                  },
                ),
              ),
              Text(
                I18n.format("version.list.mod.loader"),
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 100,
                child: DropdownButton<String>(
                  value: modLoaderName,
                  style: TextStyle(color: Colors.lightBlue),
                  onChanged: (String? value) {
                    setState(() {
                      modLoaderName = value!;
                    });
                  },
                  isExpanded: true,
                  items: ModLoader.values
                      .where((e) =>
                          e.supportInstall() &&
                          e.supportedSides().any((e) => e == widget.side))
                      .map((e) => e.i18nString)
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      alignment: Alignment.center,
                      child: Text(value,
                          style: TextStyle(fontSize: 17.5, fontFamily: 'font'),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                ),
              ),
              Text(
                I18n.format("version.list.type"),
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showRelease = value!;
                    });
                  },
                  value: showRelease,
                ),
                title: Text(
                  I18n.format("version.list.show.release"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Checkbox(
                  onChanged: (bool? value) {
                    setState(() {
                      showSnapshot = value!;
                    });
                  },
                  value: showSnapshot,
                ),
                title: Text(
                  I18n.format("version.list.show.snapshot"),
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
        gripSize: 3,
        controller: SplitViewController(weights: [0.83]),
        viewMode: SplitViewMode.Horizontal,
      ),
      ListView(
        children: [
          Text(I18n.format('modpack.install'),
              style: TextStyle(fontSize: 30, color: Colors.lightBlue),
              textAlign: TextAlign.center),
          Text(I18n.format('modpack.source'),
              textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
          SizedBox(
            height: 12,
          ),
          Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("assets/images/CurseForge.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.curseforge'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) => CurseForgeModPack());
                },
              ),
              SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.asset("assets/images/FTB.png")),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.from.ftb'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context, builder: (context) => FTBModPack());
                },
              ),
              SizedBox(
                height: 12,
              ),
              InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.computer,
                      size: 60,
                    ),
                    SizedBox(
                      width: 12,
                    ),
                    Text(I18n.format('modpack.import'),
                        style: TextStyle(fontSize: 20)),
                  ],
                ),
                onTap: () async {
                  final file = await FileSelectorPlatform.instance
                      .openFile(acceptedTypeGroups: [
                    XTypeGroup(
                        label: I18n.format('modpack.file'),
                        extensions: ['zip']),
                  ]);

                  if (file == null) return;
                  showDialog(
                      context: context,
                      builder: (context) =>
                          CurseModPackHandler.setup(File(file.path)));
                },
              ),
            ],
          ))
        ],
      ),
      RecommendedModpackScreen()
    ];
    return Scaffold(
      appBar: AppBar(
        title: I18nText("version.list.instance.type"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: I18n.format("gui.back"),
          onPressed: () {
            navigator.pop();
          },
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: widget.side == MinecraftSide.client
          ? NavigationBar(
              destinations: [
                NavigationDestination(
                    icon: SizedBox(
                        width: 30,
                        height: 30,
                        child: Image.asset("assets/images/Minecraft.png")),
                    label: 'Minecraft',
                    tooltip: ""),
                NavigationDestination(
                    icon: SizedBox(
                        width: 30, height: 30, child: Icon(Icons.folder)),
                    label: I18n.format('modpack.title'),
                    tooltip: ""),
                NavigationDestination(
                    icon: SizedBox(
                        width: 30, height: 30, child: Icon(Icons.reviews)),
                    tooltip: "",
                    label: I18n.format('version.recommended_modpack.title')),
              ],
              selectedIndex: _selectedIndex,
              backgroundColor:
                  ThemeUtility.getThemeEnumByConfig() == Themes.dark
                      ? Colors.black12.withAlpha(15)
                      : null,
              onDestinationSelected: _onItemTapped,
            )
          : SizedBox(
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: Theme.of(context).colorScheme.background,
                          width: 0.2)),
                ),
                child: InkWell(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                            width: 30,
                            height: 30,
                            child: Image.asset("assets/images/Minecraft.png")),
                        Text('Minecraft'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
