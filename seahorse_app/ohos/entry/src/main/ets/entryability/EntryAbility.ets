import {
  FlutterAbility,
  FlutterEngine,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult
} from '@ohos/flutter_ohos';
import { common, Want } from '@kit.AbilityKit';
import vibrator from '@ohos.vibrator';

class ScannerSoundMethodHandler implements MethodCallHandler {
  onMethodCall(call: MethodCall, result: MethodResult): void {
    const method: string = call.method;
    if (method === 'playScanSuccessSound') {
      this.triggerShortVibration(80);
      result.success(true);
      return;
    }
    if (method === 'playImportantNoticeSound' || method === 'playOrderAlertSound') {
      this.triggerShortVibration(280);
      result.success(true);
      return;
    }
    if (method === 'speakText') {
      const textArg: string | null = call.argument('text') as string | null;
      if (!textArg || textArg.trim().length === 0) {
        result.error('EMPTY_TEXT', 'Speech text is empty', null);
        return;
      }
      this.triggerShortVibration(120);
      result.success(true);
      return;
    }
    result.notImplemented();
  }

  private triggerShortVibration(durationMs: number): void {
    try {
      vibrator.startVibration(
        { type: 'time', duration: durationMs },
        { id: 0, usage: 'notification' }
      );
    } catch (_err) {
      // Ignore vibration errors on emulators or unsupported devices
    }
  }
}

class PhoneDialerMethodHandler implements MethodCallHandler {
  private abilityContext: common.UIAbilityContext;

  constructor(abilityContext: common.UIAbilityContext) {
    this.abilityContext = abilityContext;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method !== 'makePhoneCall') {
      result.notImplemented();
      return;
    }
    const rawPhone: string | null = call.argument('phoneNumber') as string | null;
    if (!rawPhone || rawPhone.trim().length === 0) {
      result.error('INVALID_NUMBER', 'Phone number is empty', null);
      return;
    }
    const cleaned: string = rawPhone.trim();
    const dialWant: Want = {
      action: 'ohos.want.action.dial',
      uri: `tel:${cleaned}`
    };
    this.abilityContext.startAbility(dialWant)
      .then(() => {
        result.success(true);
      })
      .catch(() => {
        result.success(false);
      });
  }
}

/**
 * EntryAbility for Seahorse Store HarmonyOS Application
 * Wraps FlutterEngine lifecycle and native MethodChannels on OpenHarmony / HarmonyOS NEXT
 */
export default class EntryAbility extends FlutterAbility {
  private soundChannel: MethodChannel | null = null;
  private dialerChannel: MethodChannel | null = null;

  configureFlutterEngine(flutterEngine: FlutterEngine): void {
    super.configureFlutterEngine(flutterEngine);
    const messenger = flutterEngine.dartExecutor.getBinaryMessenger();

    this.soundChannel = new MethodChannel(messenger, 'com.seahorse.app/scanner_sound');
    this.soundChannel.setMethodCallHandler(new ScannerSoundMethodHandler());

    this.dialerChannel = new MethodChannel(messenger, 'com.seahorse.app/phone_dialer');
    this.dialerChannel.setMethodCallHandler(new PhoneDialerMethodHandler(this.context));
  }

  onCreate(want: Want): void {
    super.onCreate(want);
  }
}
