import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Launcher/Fabric/FabricAPI.dart';
import 'package:rpmlauncher/Launcher/GameRepository.dart';
import 'package:rpmlauncher/Launcher/MinecraftServer.dart';
import 'package:rpmlauncher/Model/Game/FabricInstallerVersion.dart';
import 'package:rpmlauncher/Model/Game/Instance.dart';
import 'package:rpmlauncher/Model/Game/Libraries.dart';
import 'package:rpmlauncher/Model/Game/MinecraftMeta.dart';
import 'package:rpmlauncher/Model/Game/MinecraftSide.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Launcher/Arguments.dart';
import 'package:rpmlauncher/Launcher/InstallingState.dart';
import 'package:rpmlauncher/Mod/ModLoader.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:rpmlauncher/Utility/Utility.dart';

class FabricServer extends MinecraftServer {
  @override
  MinecraftServerHandler handler;

  final String loaderVersion;

  FabricServer._init({required this.handler, required this.loaderVersion});

  static Future<FabricServer> createServer(
      {required MinecraftMeta meta,
      required String versionID,
      required Instance instance,
      required String loaderVersion,
      required StateSetter setState}) async {
    return await FabricServer._init(
      handler: MinecraftServerHandler(
          meta: meta,
          versionID: versionID,
          instance: instance,
          setState: setState),
      loaderVersion: loaderVersion,
    )._ready();
  }

  late String _serverJarPath;

  Future<void> serverJar() async {
    FabricInstallerVersions versions = await FabricAPI.getInstallerVersion();

    String installerVersion = versions
        .firstWhere((e) => e.stable, orElse: () => versions.first)
        .version;
    String downloadUrl =
        "$fabricApi/versions/loader/$versionID/$loaderVersion/$installerVersion/server/jar";
    String jar = "$versionID-$loaderVersion-$installerVersion.jar";
    _serverJarPath = join(GameRepository.getLibraryGlobalDir().path, "net",
        "fabricmc", "installer", "server", jar);

    Libraries _libraries = instance.config.libraries;
    _libraries.add(Library(
        name:
            "net.fabricmc::installer:server:$versionID-$loaderVersion-$installerVersion",
        downloads: LibraryDownloads(
            artifact: Artifact(
          url: downloadUrl,
          path: "net/fabricmc/installer/server/$jar",
        ))));
    instance.config.libraries = _libraries;

    installingState.downloadInfos.add(DownloadInfo(downloadUrl,
        savePath: _serverJarPath,
        description: I18n.format('version.list.downloading.main')));
  }

  Future<void> getArgs() async {
    File serverJar = File(_serverJarPath);

    File argsFile = GameRepository.getArgsFile(
        versionID, ModLoader.fabric, MinecraftSide.server,
        loaderVersion: loaderVersion);
    await argsFile.create(recursive: true);
    Map argsMap = Arguments().getArgsString(versionID, meta);
    String? mainClass = Uttily.getJarMainClass(serverJar);
    argsMap['mainClass'] = mainClass ?? "net.fabricmc.installer.ServerLauncher";
    await argsFile.writeAsString(json.encode(argsMap));
  }

  Future<FabricServer> _ready() async {
    await serverJar();
    await installingState.downloadInfos.downloadAll(
        onReceiveProgress: (_progress) {
      try {
        setState(() {});
      } catch (e) {}
    });
    setState(() {
      installingState.nowEvent = I18n.format('version.list.downloading.args');
    });
    await getArgs();

    return this;
  }
}
