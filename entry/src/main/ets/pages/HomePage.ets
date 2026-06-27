import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { DayGroup, MonthStats, RecordDisplay, getMonthLabel, formatAmount }
  from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { TransactionItem } from '../components/TransactionItem';

@Component
export struct HomePage {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @StorageLink('refreshTrigger') @Watch('onRefresh') refresh: number = 0;
  @State groups: DayGroup[] = [];
  @State stats: MonthStats =
    { totalIncome: 0, totalExpense: 0, balance: 0, budgetAmount: 0, budgetUsed: 0 };
  @State y: number = new Date().getFullYear();
  @State m: number = new Date().getMonth();
  db = DatabaseHelper.getInstance();
  col = getThemeColors();

  aboutToAppear(): void { this.load(); }
  onRefresh(): void { this.load(); }
  async load(): Promise<void> {
    try {
      this.stats = await this.db.getMonthStats(this.y, this.m);
      this.groups = await this.db.getRecordsGroupedByDay(this.y, this.m);
    } catch (_e) { }
  }
  async del(id: number): Promise<void> { await this.db.deleteRecord(id); this.load(); }
  prev(): void { this.m = this.m === 0 ? 11 : this.m - 1; if (this.m === 11) this.y--; this.load(); }
  next(): void { this.m = this.m === 11 ? 0 : this.m + 1; if (this.m === 0) this.y++; this.load(); }

  build() {
    Column() {
        // 月份卡片
        Column() {
          Row() {
            Button() { Text('‹').fontSize(22).fontColor(this.col.textSecondary) }
              .width(32).height(32).backgroundColor(Color.Transparent).onClick(() => this.prev())
            Text(getMonthLabel(this.y, this.m)).fontSize(17).fontWeight(FontWeight.Medium)
              .fontColor(this.col.textPrimary).layoutWeight(1).textAlign(TextAlign.Center)
            Button() { Text('›').fontSize(22).fontColor(this.col.textSecondary) }
              .width(32).height(32).backgroundColor(Color.Transparent).onClick(() => this.next())
          }.width('100%').margin({ bottom: 20 })
          Row() {
            Column() {
              Text('支出').fontSize(13).fontColor(this.col.textSecondary).margin({ bottom: 10 })
              Text(formatAmount(this.stats.totalExpense)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.col.expenseColor).fontFamily('monospace')
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column().width(0.5).height(36).backgroundColor(this.col.divider)
            Column() {
              Text('收入').fontSize(13).fontColor(this.col.textSecondary).margin({ bottom: 10 })
              Text(formatAmount(this.stats.totalIncome)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.col.incomeColor).fontFamily('monospace')
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }.width('100%')
        }
        .width('100%').padding(20).backgroundColor(this.col.bgCard).borderRadius(16)
        .margin({ left: 16, right: 16, top: 0, bottom: 12 })

        // 预算
        if (this.stats.budgetAmount > 0) {
          Column() {
            Row() {
              Text('预算').fontSize(12).fontColor(this.col.textSecondary)
              Blank()
              Text(`${this.stats.totalExpense.toFixed(0)} / ${this.stats.budgetAmount.toFixed(0)}`)
                .fontSize(12).fontColor(this.col.textSecondary)
            }.width('100%').margin({ bottom: 6 })
            Progress({
              value: Math.min(this.stats.totalExpense, this.stats.budgetAmount),
              total: this.stats.budgetAmount, type: ProgressType.Linear
            })
            .width('100%').height(6).style({ strokeWidth: 6, strokeRadius: 3 })
            .color(this.barC()).backgroundColor(this.col.bgInput)
          }.width('100%').padding({ left: 16, right: 16 }).margin({ bottom: 12 })
        }

        // 记录
        if (this.groups.length === 0) {
          Column() {
            Text('📄').fontSize(44).fontColor(this.col.textHint).margin({ top: 40, bottom: 10 })
            Text('还没有记录').fontSize(15).fontColor(this.col.textSecondary)
            Text('点击 ＋ 开始记账').fontSize(12).fontColor(this.col.textHint).margin({ top: 4 })
          }.width('100%')
        } else {
          ForEach(this.groups, (g: DayGroup) => {
            Column() {
              Row() {
                Text(g.dateLabel).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.col.textPrimary)
                Blank()
                if (g.dayExpense > 0) {
                  Text(`-${formatAmount(g.dayExpense)}`).fontSize(13)
                    .fontColor(this.col.expenseColor).fontFamily('monospace')
                }
                if (g.dayExpense > 0 && g.dayIncome > 0) { Text('  ').fontSize(13) }
                if (g.dayIncome > 0) {
                  Text(`+${formatAmount(g.dayIncome)}`).fontSize(13)
                    .fontColor(this.col.incomeColor).fontFamily('monospace')
                }
              }.width('100%').padding({ left: 20, right: 16, top: 18, bottom: 10 })
              Column({ space: 2 }) {
                ForEach(g.records, (r: RecordDisplay) => {
                  TransactionItem({ record: r, onDelete: (id: number) => this.del(id) })
                })
              }
            }.width('100%').margin({ bottom: 4 })
          })
        }
      }
    .width('100%').height('100%').backgroundColor(this.col.bgPage)
  }

  barC(): ResourceColor {
    const r = this.stats.budgetAmount > 0 ? this.stats.totalExpense / this.stats.budgetAmount : 0;
    if (r >= 1) { return this.col.expenseColor; }
    if (r >= 0.8) { return '#FF9800'; }
    return this.col.primary;
  }
}
