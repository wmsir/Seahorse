import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { Want } from '@kit.AbilityKit';

/**
 * EntryAbility for Seahorse Store HarmonyOS Application
 * Wraps FlutterEngine lifecycle on OpenHarmony / HarmonyOS NEXT
 */
export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
  }

  onCreate(want: Want): void {
    super.onCreate(want);
  }
}
