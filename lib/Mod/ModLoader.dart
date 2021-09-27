import '../Utility/i18n.dart';

enum ModLoaders { Vanilla, Fabric, Forge, Unknown }

extension ExtensionModLoader on ModLoaders {
  String get fixedString {
    switch (this) {
      case ModLoaders.Vanilla:
        return 'vanilla';
      case ModLoaders.Fabric:
        return 'fabric';
      case ModLoaders.Forge:
        return 'forge';
      default:
        return 'unknown';
    }
  }

  String get i18nString {
    switch (this) {
      case ModLoaders.Vanilla:
        return i18n.format("version.list.mod.loader.vanilla");
      case ModLoaders.Fabric:
        return i18n.format("version.list.mod.loader.fabric");
      case ModLoaders.Forge:
        return i18n.format("version.list.mod.loader.forge");
      default:
        return i18n.format("version.list.mod.loader.unknown");
    }
  }

}

class ModLoaderUttily {
  List<String> ModLoaderNames = [
    i18n.format("version.list.mod.loader.vanilla"),
    i18n.format("version.list.mod.loader.fabric"),
    i18n.format("version.list.mod.loader.forge")
  ];

  ModLoaders getByIndex(Index) {
    switch (Index) {
      case 0:
        return ModLoaders.Vanilla;
      case 1:
        return ModLoaders.Fabric;
      case 2:
        return ModLoaders.Forge;
      default:
        return ModLoaders.Vanilla;
    }
  }

  int getIndexByLoader(ModLoaders Loader) {
    switch (Loader) {
      case ModLoaders.Vanilla:
        return 0;
      case ModLoaders.Fabric:
        return 1;
      case ModLoaders.Forge:
        return 2;
      default:
        return 0;
    }
  }
}
