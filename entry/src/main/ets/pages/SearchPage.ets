/**
 * 搜索页面 — 全屏搜索所有账单
 */
import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { RecordDisplay, RECORD_TYPE_EXPENSE, formatAmount } from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';

@Component
export struct SearchPage {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @State searchText: string = '';
  @State results: RecordDisplay[] = [];
  @State allRecords: RecordDisplay[] = [];
  onClose?: () => void;
  onDelete?: () => void;
  private db: DatabaseHelper = DatabaseHelper.getInstance();
  private col = getThemeColors();

  aboutToAppear(): void { this.load(); }

  async load(): Promise<void> {
    this.allRecords = await this.db.getAllRecords();
    this.results = [];
  }

  doSearch(): void {
    const kw = this.searchText.trim().toLowerCase();
    if (!kw) { this.results = []; return; }
    const result: RecordDisplay[] = [];
    for (const r of this.allRecords) {
      if (r.note.toLowerCase().includes(kw)) result.push(r);
      else if (r.categoryName.toLowerCase().includes(kw)) result.push(r);
      else if (r.amount.toString().includes(kw)) result.push(r);
      else if (r.parentCategoryName.toLowerCase().includes(kw)) result.push(r);
    }
    this.results = result;
  }

  async del(id: number): Promise<void> {
    await this.db.deleteRecord(id);
    if (this.onDelete) this.onDelete();
    this.load();
  }

  build() {
    Stack() {
    Column() {
      // 搜索栏
      Row() {
        Button() { Text('‹').fontSize(22).fontColor(this.col.textSecondary) }
          .width(36).height(36).backgroundColor(Color.Transparent)
          .onClick(() => { if (this.onClose) this.onClose(); })
        TextInput({ text: this.searchText, placeholder: '搜索备注、分类、金额...' })
          .fontSize(15).layoutWeight(1).height(40)
          .backgroundColor(this.col.bgInput).borderRadius(20)
          .padding({ left: 16, right: 16 })
          .margin({ left: 8, right: 8 })
          .onChange((value: string) => { this.searchText = value; this.doSearch(); })
        if (this.searchText) {
          Text('✕').fontSize(16).fontColor(this.col.textHint)
            .onClick(() => { this.searchText = ''; this.doSearch(); })
        }
      }.width('100%').padding({ left: 16, right: 16, top: 17, bottom: 8 })

      // 结果
      if (this.results.length > 0) {
        Scroll() {
          Column() {
            ForEach(this.results, (r: RecordDisplay) => {
              Column() {
                Row() {
                  Text(new Date(r.date).toLocaleDateString('zh-CN')).fontSize(11).fontColor(this.col.textHint)
                }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 2 })
                Row() {
                  Text(r.parentCategoryName ? r.parentCategoryName + '-' + r.categoryName : r.categoryName)
                    .fontSize(13).fontColor(this.col.textPrimary)
                  Text(' ' + r.note).fontSize(12).fontColor(this.col.textHint)
                    .maxLines(1).layoutWeight(1)
                  Text((r.type === RECORD_TYPE_EXPENSE ? '-' : '+') + formatAmount(r.amount))
                    .fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor(r.type === RECORD_TYPE_EXPENSE ? this.col.expenseColor : this.col.incomeColor)
                    .fontFamily('monospace').margin({ left: 8 })
                  Button('✕').fontSize(12).fontColor(this.col.textHint)
                    .width(24).height(24).backgroundColor(Color.Transparent)
                    .onClick(() => this.del(r.id))
                }.width('100%').padding({ left: 16, right: 16, top: 2, bottom: 12 })
              }
              .width('100%').backgroundColor(this.col.bgCard).borderRadius(10)
              .margin({ left: 12, right: 12, bottom: 6 })
            })
          }.width('100%')
        }.scrollBar(BarState.Off)
      }
    }
    .width('100%').height('100%').backgroundColor(this.col.bgCard)

      // 白色延伸条
      Column()
        .width('100%').height(60)
        .backgroundColor(this.col.bgCard)
        .position({ x: 0, y: -48 })
    }
    .width('100%').height('100%').clip(false)
  }
}
