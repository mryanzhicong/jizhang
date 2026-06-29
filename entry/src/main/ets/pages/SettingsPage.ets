/**
 * 设置页面 - 分类管理 / 导出 / 关于
 */
import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { CategoriesPage } from './CategoriesPage';
import { fileIo } from '@kit.CoreFileKit';
import picker from '@ohos.file.picker';
import { util } from '@kit.ArkTS';

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
      const saveOption = new picker.DocumentSaveOptions();
      saveOption.newFileNames = ['极简记账_' + new Date().toISOString().slice(0,10) + '.csv'];
      const documentPicker = new picker.DocumentViewPicker();
      const uris = await documentPicker.save(saveOption);
      if (uris.length === 0) return;
      const file = fileIo.openSync(uris[0], fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, csv);
      fileIo.closeSync(file.fd);
      AlertDialog.show({ title: '导出成功', message: 'CSV 已保存', confirm: { value: '确定', action: () => {} } });
    } catch (_e) {
      AlertDialog.show({ title: '导出失败', message: '请重试', confirm: { value: '确定', action: () => {} } });
    }
  }

  async importCSV(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker();
      const uris = await documentPicker.select();
      if (uris.length === 0) return;
      const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buf);
      fileIo.closeSync(file.fd);
      const decoder = new util.TextDecoder('utf-8');
      const text = decoder.decodeWithStream(new Uint8Array(buf), { stream: false });
      // 解析 CSV：日期,类型,分类,金额,备注
      const lines = text.split('\n');
      let count = 0;
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;
        const cols = this.splitCsvLine(line);
        if (cols.length < 4) continue;
        const dateStr = cols[0];
        const typeStr = cols[1];
        const catName = cols[2];
        const amountStr = cols[3];
        const note = cols.length > 4 ? cols[4] : '';
        // 解析日期 "YYYY/MM/DD" 或 "YYYY-MM-DD"
        const dateParts = dateStr.split(/[\/\-]/);
        if (dateParts.length < 3) continue;
        const recordDate = new Date(parseInt(dateParts[0]), parseInt(dateParts[1]) - 1, parseInt(dateParts[2]), 12, 0, 0).getTime();
        const type = typeStr.includes('收入') ? 1 : 0;
        const amount = parseFloat(amountStr) || 0;
        // 查找或创建分类
        const cats = await this.db.getParentCategories(type);
        let catId = 0;
        for (const c of cats) { if (c.name === catName) { catId = c.id; break; } }
        if (catId === 0) continue; // 分类不匹配，跳过
        await this.db.addRecord(type, catId, amount, note, recordDate);
        count++;
      }
      AlertDialog.show({ title: '导入成功', message: '已导入 ' + count + ' 条记录', confirm: { value: '确定', action: () => {} } });
    } catch (_e) {
      AlertDialog.show({ title: '导入失败', message: '请检查文件格式', confirm: { value: '确定', action: () => {} } });
    }
  }

  // 简单的 CSV 行解析（支持引号）
  splitCsvLine(line: string): string[] {
    const result: string[] = [];
    let cur = '';
    let inQuote = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') { inQuote = !inQuote; continue; }
      if (ch === ',' && !inQuote) { result.push(cur); cur = ''; continue; }
      cur += ch;
    }
    result.push(cur);
    return result;
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
          this.SRow('导入 CSV', '从 CSV 文件导入记录', () => { this.importCSV(); })
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
