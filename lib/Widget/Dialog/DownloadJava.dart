import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:rpmlauncher/Launcher/APIs.dart';
import 'package:rpmlauncher/Model/IO/DownloadInfo.dart';
import 'package:rpmlauncher/Utility/LauncherInfo.dart';
import 'package:rpmlauncher/Utility/Process.dart';
import 'package:rpmlauncher/Utility/Config.dart';
import 'package:rpmlauncher/Utility/I18n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:rpmlauncher/Utility/Utility.dart';
import 'package:rpmlauncher/Widget/RPMTW-Design/OkClose.dart';
import 'package:rpmlauncher/Widget/Settings/JavaPath.dart';
import 'package:rpmlauncher/Utility/Data.dart';
import 'package:system_info/system_info.dart';

class _DownloadJavaState extends State<DownloadJava> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: I18nText(
        "gui.tips.info",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25),
      ),
      content: I18nText(
        "launcher.java.install.not",
        args: {
          "java_version": widget.javaVersions.join(I18n.format('gui.separate'))
        },
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
        ),
      ),
      actions: [
        Center(
            child: TextButton(
                child: I18nText("launcher.java.install.auto",
                    style: TextStyle(fontSize: 20, color: Colors.red)),
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => Task(
                            javaVersions: widget.javaVersions,
                            onDownloaded: widget.onDownloaded,
                          ));
                })),
        SizedBox(
          height: 10,
        ),
        Center(
            child: TextButton(
          child: I18nText("launcher.java.install.manual",
              style: TextStyle(fontSize: 20, color: Colors.lightBlue)),
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: I18nText("launcher.java.install.manual"),
                      content: JavaPathWidget(),
                      actions: [
                        OkClose(
                          onOk: () {
                            List<int> needVersions =
                                Uttily.javaCheck(widget.javaVersions);

                            if (needVersions.isNotEmpty) {
                              showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                        title: I18nText.errorInfoText(),
                                        content: I18nText(
                                            "launcher.java.install.manual.error"),
                                        actions: [OkClose()],
                                      ));
                            } else {
                              Navigator.pop(context);
                              widget.onDownloaded?.call();
                            }
                          },
                        )
                      ],
                    ));
          },
        )),
      ],
    );
  }
}

class DownloadJava extends StatefulWidget {
  final List<int> javaVersions;
  final Function? onDownloaded;

  const DownloadJava({required this.javaVersions, this.onDownloaded});

  @override
  _DownloadJavaState createState() => _DownloadJavaState();
}

class Task extends StatefulWidget {
  final List<int> javaVersions;
  final Function? onDownloaded;
  const Task({required this.javaVersions, this.onDownloaded});

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  late List<double> downloadJavaProgress;
  late List<bool> finishList;

  double get downloadProgress {
    if (finishList.every((b) => b)) return 1;
    double _p = 0.0;
    downloadJavaProgress.forEach((progress) {
      _p += progress;
    });
    return _p / downloadJavaProgress.length;
  }

  @override
  void initState() {
    super.initState();
    downloadJavaProgress =
        List.generate(widget.javaVersions.length, (index) => 0.0);
    finishList = List.generate(widget.javaVersions.length, (index) => false);
    widget.javaVersions.forEach((int version) {
      thread(version);
    });
  }

  Future<void> thread(int version) async {
    DateTime startTime = DateTime.now();
    ReceivePort port = ReceivePort();
    Isolate isolate = await Isolate.spawn(
        downloadJavaProcess, [port.sendPort, version, dataHome, kTestMode]);
    ReceivePort exit = ReceivePort();
    isolate.addOnExitListener(exit.sendPort);
    exit.listen((message) async {
      late String _execPath;

      if (Platform.isWindows) {
        _execPath = join(dataHome.absolute.path, "jre", version.toString(),
            "bin", "javaw.exe");
      } else if (Platform.isLinux) {
        _execPath = join(
            dataHome.absolute.path, "jre", version.toString(), "bin", "java");
      } else if (Platform.isMacOS) {
        _execPath = join(dataHome.absolute.path, "jre", version.toString(),
            "jre.bundle", "Contents", "Home", "bin", "java");
      }
      Config.change("java_path_$version", _execPath);
      if (!kTestMode) {
        await chmod(_execPath);
      }

      finishList[widget.javaVersions.indexOf(version)] = true;
      DateTime endTime = DateTime.now();
      Duration duration = endTime.difference(startTime);
      logger.info(
          "It took ${duration.inSeconds} Seconds to download Java $version");
      if (mounted) {
        setState(() {});
      }
    });
    port.listen((message) {
      if (mounted) {
        setState(() {
          downloadJavaProgress[widget.javaVersions.indexOf(version)] =
              double.parse(message.toString());
        });
      }
    });
  }

  static downloadJavaProcess(List arguments) async {
    int totalFiles = 0;
    int doneFiles = 0;
    late Future<void> _future;

    SendPort port = arguments[0];
    int javaVersion = arguments[1];
    Directory dataHome = arguments[2];
    kTestMode = arguments[3];

    Response response = await get(Uri.parse(mojangJavaRuntimeAPI));
    Map mojangJRE = json.decode(response.body);

    Future<void> download(String url) async {
      Response response = await get(Uri.parse(url));
      Map data = json.decode(response.body);
      Map<String, Map> files = data["files"].cast<String, Map>();
      totalFiles = files.keys.length;
      DownloadInfos _infos = DownloadInfos.empty();

      files.keys.forEach((String file) {
        if (files[file]!["type"] == "file") {
          _infos.add(DownloadInfo(files[file]!["downloads"]["raw"]["url"],
              savePath: join(
                  dataHome.absolute.path, "jre", javaVersion.toString(), file),
              onDownloaded: () {
            doneFiles++;
            port.send(doneFiles / totalFiles);
          },
              hashCheck: true,
              sh1Hash: files[file]!["downloads"]["raw"]["sha1"]));
        } else {
          Directory(join(
                  dataHome.absolute.path, "jre", javaVersion.toString(), file))
              .createSync(recursive: true);
          doneFiles++;
          port.send(doneFiles / totalFiles);
        }
      });

      if (kTestMode) {
        _infos.infos.clear();
      }
      await _infos.downloadAll();
    }

    //  String downloadUrl =
    //     "https://api.adoptium.net/v3/binary/latest/$javaVersion/ga/${Platform.isMacOS ? "mac" : Platform.operatingSystem}/x${SysInfo.processors[0].architecture.name.toLowerCase()}/jdk/hotspot/normal/eclipse?project=jdk";

    switch (Platform.operatingSystem) {
      case 'linux':
        mojangJRE["linux"].keys.forEach((version) {
          if (version == "minecraft-java-exe") return;
          var versionMap = mojangJRE["linux"][version][0];
          if (versionMap["version"]["name"].contains(javaVersion.toString())) {
            _future = download(versionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      case 'macos':
        mojangJRE["mac-os"].keys.forEach((version) {
          if (version == "minecraft-java-exe") return;
          var versionMap = mojangJRE["mac-os"][version][0];
          if (versionMap["version"]["name"].contains(javaVersion.toString())) {
            _future = download(versionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      case 'windows':
        mojangJRE["windows-x${SysInfo.userSpaceBitness}"]
            .keys
            .forEach((version) {
          if (version == "minecraft-java-exe") return;
          var versionMap =
              mojangJRE["windows-x${SysInfo.userSpaceBitness}"][version][0];
          if (versionMap["version"]["name"].contains(javaVersion.toString())) {
            _future = download(versionMap["manifest"]["url"]);
            return;
          }
        });
        break;
      default:
        break;
    }

    await Future.sync(() => _future);
  }

  @override
  Widget build(BuildContext context) {
    if (downloadProgress == 1) {
      return AlertDialog(
        title: Text(I18n.format("launcher.java.install.auto.download.done"),
            textAlign: TextAlign.center),
        actions: [
          OkClose(
            onOk: () => widget.onDownloaded?.call(),
          )
        ],
      );
    } else {
      return AlertDialog(
        title: Text(
            I18n.format("launcher.java.install.auto.downloading") + "\n",
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text((downloadProgress * 100).toStringAsFixed(2) + "%"),
            LinearProgressIndicator(
              value: downloadProgress,
            ),
          ],
        ),
      );
    }
  }
}
