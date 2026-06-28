/**
 * 设置页面 - 分类管理 / 导出 / 关于
 */
import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { CategoriesPage } from './CategoriesPage';
import { fileIo } from '@kit.CoreFileKit';
import { common, Context } from '@kit.AbilityKit';

@Component
export struct SettingsPage {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;

  @StorageLink('showCategories') @Watch('onCatChange') showCatLink: number = 0;
  @State showCategories: boolean = false;

  onCatChange(): void { this.showCategories = this.showCatLink === 1; }

  private db: DatabaseHelper = DatabaseHelper.getInstance();

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
      Column() { CategoriesPage() }.width('100%').height('100%')
    } else {
    Column() {
      Text('设置').fontSize(17).fontWeight(FontWeight.Bold)
        .fontColor(getThemeColors().textPrimary).width('100%').textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20, top: 32, bottom: 8 })

      Scroll() {
        Column() {
          Text('通用').fontSize(13).fontColor(getThemeColors().textSecondary).fontWeight(FontWeight.Medium)
            .width('100%').textAlign(TextAlign.Start).padding({ left: 20, top: 12, bottom: 6 })
          this.SRow('分类管理', '管理收支分类', () => { this.showCategories = true; AppStorage.set<number>('showCategories', 1); })
          Blank().height(16)

          Text('数据管理').fontSize(13).fontColor(getThemeColors().textSecondary).fontWeight(FontWeight.Medium)
            .width('100%').textAlign(TextAlign.Start).padding({ left: 20, top: 12, bottom: 6 })
          this.SRow('导出 CSV', '将当前账本数据导出为 CSV 文件', () => { this.exportCSV(); })
          Blank().height(16)

          Text('关于').fontSize(13).fontColor(getThemeColors().textSecondary).fontWeight(FontWeight.Medium)
            .width('100%').textAlign(TextAlign.Start).padding({ left: 20, top: 12, bottom: 6 })
          this.SRow('应用名称', '极简记账', undefined)
          this.SRow('版本号', '1.0.0', undefined)
          Blank().height(16)
        }
      }
      .scrollBar(BarState.Off)
    }
    .width('100%').height('100%').backgroundColor(getThemeColors().bgPage)
    }
  }

  @Builder SRow(label: string, value: string, onClick?: () => void) {
    Row() {
      Text(label).fontSize(15).fontColor(getThemeColors().textPrimary).layoutWeight(1)
      Text(value).fontSize(14).fontColor(getThemeColors().textSecondary)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ right: 4 })
      if (onClick) {
        Text('›').fontSize(18).fontColor(getThemeColors().textHint)
      }
    }
    .width('100%').height(52).padding({ left: 20, right: 16 })
    .backgroundColor(getThemeColors().bgCard)
    .border({ width: { bottom: 0.5 }, color: getThemeColors().divider })
    .onClick(() => { if (onClick) onClick(); })
  }
}
