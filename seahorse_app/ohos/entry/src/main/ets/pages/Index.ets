import { FlutterPage } from '@ohos/flutter_ohos';

/**
 * Main Page hosting the Flutter view in HarmonyOS ArkTS Stage mode
 */
@Entry
@Component
struct Index {
  build() {
    Column() {
      FlutterPage()
    }
    .width('100%')
    .height('100%')
  }
}
