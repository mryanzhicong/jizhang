/**
 * 设置页面 - 分类管理 / 主题 / 导出 / 关于
 */
import {
  IS_DARK_KEY, getThemeColors, ThemeColors,
  THEME_MODE_LIGHT, THEME_MODE_DARK, THEME_MODE_SYSTEM,
  getThemeMode, setThemeMode
} from '../common/ThemeManager';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { CategoriesPage } from './CategoriesPage';
import { fileIo } from '@kit.CoreFileKit';
import { common, Context } from '@kit.AbilityKit';

@Component
export struct SettingsPage {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;

  @State themeMode: number = getThemeMode();
  @State showCategories: boolean = false;

  private db: DatabaseHelper = DatabaseHelper.getInstance();
  private colors: ThemeColors = getThemeColors();

  aboutToAppear(): void { this.themeMode = getThemeMode(); }

  async exportCSV(): Promise<void> {
    try {
      const csv = await this.db.exportToCSV();
      const ctx = getContext() as common.UIAbilityContext;
      const filePath = ctx.filesDir + '/sharkbook_export.csv';
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, csv);
      fileIo.closeSync(file.fd);

      AlertDialog.show({ title: '导出成功', message: 'CSV 已保存到应用目录', confirm: { value: '确定', action: () => {} } });
    } catch (_e) {
      AlertDialog.show({ title: '导出失败', message: '请重试', confirm: { value: '确定', action: () => {} } });
    }
  }

  build() {
    if (this.showCategories) {
      CategoriesPage({ onBack: () => { this.showCategories = false; AppStorage.set<number>('showCategories', 0); } })
    } else {
    Column() {
      Row() {
        Text('设置').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textPrimary)
      }
      .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 8 })

      Scroll() {
        Column() {
          Column() {
            Text('通用').fontSize(13).fontColor(this.colors.textHint).fontWeight(FontWeight.Medium)
              .padding({ left: 20, top: 12, bottom: 6 })
            this.SRow('分类管理', '管理收支分类', () => { this.showCategories = true; AppStorage.set<number>('showCategories', 1); })
          }
          Blank().height(16)

          Column() {
            Text('外观设置').fontSize(13).fontColor(this.colors.textHint).fontWeight(FontWeight.Medium)
              .padding({ left: 20, top: 12, bottom: 6 })
            this.SRow('主题模式', this.getThemeLabel(), () => { this.cycleTheme(); })
          }
          Blank().height(16)

          Column() {
            Text('数据管理').fontSize(13).fontColor(this.colors.textHint).fontWeight(FontWeight.Medium)
              .padding({ left: 20, top: 12, bottom: 6 })
            this.SRow('导出 CSV', '将当前账本数据导出为 CSV 文件', () => { this.exportCSV(); })
          }
          Blank().height(16)

          Column() {
            Text('关于').fontSize(13).fontColor(this.colors.textHint).fontWeight(FontWeight.Medium)
              .padding({ left: 20, top: 12, bottom: 6 })
            this.SRow('应用名称', '极简记账', undefined)
            this.SRow('版本号', '1.0.0', undefined)
          }
          Blank().height(80)
        }
      }
      .scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.colors.bgPage)
    }
  }

  @Builder SRow(label: string, value: string, onClick?: () => void) {
    Row() {
      Text(label).fontSize(15).fontColor(this.colors.textPrimary).layoutWeight(1)
      Text(value).fontSize(14).fontColor(this.colors.textSecondary)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ right: 4 })
      if (onClick) {
        Text('›')
          .fontSize(18).fontColor(this.colors.textHint)
      }
    }
    .width('100%').height(52).padding({ left: 20, right: 16 })
    .backgroundColor(this.colors.bgCard)
    .border({ width: { bottom: 0.5 }, color: this.colors.divider })
    .onClick(() => { if (onClick) onClick(); })
  }

  cycleTheme(): void {
    if (this.themeMode === THEME_MODE_LIGHT) this.themeMode = THEME_MODE_DARK;
    else if (this.themeMode === THEME_MODE_DARK) this.themeMode = THEME_MODE_SYSTEM;
    else this.themeMode = THEME_MODE_LIGHT;
    setThemeMode(this.themeMode);
  }

  getThemeLabel(): string {
    if (this.themeMode === THEME_MODE_LIGHT) return '浅色模式';
    if (this.themeMode === THEME_MODE_DARK) return '深色模式';
    return '跟随系统';
  }
}
