/**
 * 应用入口 Ability
 */
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { initTheme } from '../common/ThemeManager';

export default class EntryAbility extends UIAbility {
  private db: DatabaseHelper = DatabaseHelper.getInstance();

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    initTheme();
    try {
      await this.db.init(this.context);
    } catch (err) {
      console.error('Database init error:', JSON.stringify(err));
    }
  }

  onDestroy(): void { }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error('Failed to load content:', JSON.stringify(err));
        return;
      }
    });

    // 沉浸式状态栏 — 先全屏，回调中设属性
    const win = windowStage.getMainWindowSync();
    win.setWindowLayoutFullScreen(true, (err) => {
      if (err.code) { return; }
      win.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#000000',
        navigationBarColor: '#00000000'
      });
    });
  }

  onWindowStageDestroy(): void { }

  onForeground(): void { }

  onBackground(): void { }
}
