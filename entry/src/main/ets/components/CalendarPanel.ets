/**
 * 日历面板 — 显示当月每日净流水，选中日期显示分类排行
 */
import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { DayGroup, CategoryStats, RECORD_TYPE_EXPENSE, RECORD_TYPE_INCOME, formatAmount }
  from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { RankBars } from '../components/RankBars';
import { PieChart } from '../components/PieChart';

@Component
export struct CalendarPanel {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @StorageLink('showCalMonthPicker') @Watch('onPickerLink') calPickerLink: number = 0;
  @Prop initYear: number = new Date().getFullYear();
  @Prop initMonth: number = new Date().getMonth();

  onPickerLink(): void {
    if (this.calPickerLink === 0) this.showPicker = false;
  }
  @State y: number = 0;
  @State m: number = 0;
  @State dayMap: Map<number, DayGroup> = new Map();
  @State totalIncome: number = 0;
  @State totalExpense: number = 0;
  @State selectedDay: number = 0;
  @State dayCatStats: CategoryStats[] = [];
  @State dayTotal: number = 0;
  @State dayType: number = RECORD_TYPE_EXPENSE;
  @State monthCatStats: CategoryStats[] = [];
  @State monthCatType: number = RECORD_TYPE_EXPENSE;
  @State pieRefresh: number = 0;
  @State showPie: boolean = true;
  onClose?: () => void;
  private db: DatabaseHelper = DatabaseHelper.getInstance();

  aboutToAppear(): void {
    this.y = this.initYear;
    this.m = this.initMonth;
    this.load();
  }

  async load(): Promise<void> {
    try {
      const groups = await this.db.getRecordsGroupedByDay(this.y, this.m);
      const map = new Map<number, DayGroup>();
      let ti = 0; let te = 0;
      for (const g of groups) {
        ti += g.dayIncome; te += g.dayExpense;
        const match = g.dateLabel.match(/(\d+)日/);
        if (match) map.set(parseInt(match[1]), g);
      }
      this.dayMap = map;
      this.totalIncome = ti;
      this.totalExpense = te;
      // 加载月分类统计（饼图用）
      const ms = new Date(this.y, this.m, 1, 0, 0, 0).getTime();
      const me = new Date(this.y, this.m + 1, 0, 23, 59, 59).getTime();
      this.monthCatStats = await this.db.getPeriodCategoryStats(ms, me, this.monthCatType);
      this.pieRefresh++;
      this.showPie = false;
      setTimeout(() => { this.showPie = true; }, 50);
      // 如果选中日不在本月则清除
      if (this.selectedDay > 0 && !map.has(this.selectedDay)) this.selectedDay = 0;
      if (this.selectedDay > 0) await this.loadDayDetail();
    } catch (_e) { }
  }

  async loadDayDetail(): Promise<void> {
    if (this.selectedDay <= 0) return;
    const ms = new Date(this.y, this.m, this.selectedDay, 0, 0, 0).getTime();
    const me = new Date(this.y, this.m, this.selectedDay, 23, 59, 59).getTime();
    this.dayCatStats = await this.db.getPeriodCategoryStats(ms, me, this.dayType);
    this.dayTotal = 0;
    for (const s of this.dayCatStats) this.dayTotal += s.amount;
  }

  selectDay(d: number): void {
    if (d <= 0) return;
    if (this.selectedDay === d) { this.selectedDay = 0; this.dayCatStats = []; return; }
    this.selectedDay = d;
    this.loadDayDetail();
  }

  @State showPicker: boolean = false;
  @State pickYear: number = new Date().getFullYear();

  showMonthPicker(): void {
    this.pickYear = this.y;
    this.showPicker = true;
    AppStorage.set<number>('showCalMonthPicker', 1);
  }
  closeMonthPicker(): void {
    this.showPicker = false;
    AppStorage.set<number>('showCalMonthPicker', 0);
  }
  selectMonth(mon: number): void {
    this.y = this.pickYear;
    this.m = mon;
    this.closeMonthPicker();
    this.selectedDay = 0;
    this.dayCatStats = [];
    this.load();
  }

  daysInMonth(): number { return new Date(this.y, this.m + 1, 0).getDate(); }
  // 周一=0，周日=6
  firstDow(): number { const d = new Date(this.y, this.m, 1).getDay(); return d === 0 ? 6 : d - 1; }
  netOf(d: number): number {
    const g = this.dayMap.get(d);
    return g ? g.dayIncome - g.dayExpense : 0;
  }
  isToday(d: number): boolean {
    const now = new Date();
    return this.y === now.getFullYear() && this.m === now.getMonth() && d === now.getDate();
  }
  dayBg(d: number): string {
    if (d <= 0) return '#00000000';
    const hasData = this.dayMap.has(d);
    const net = this.netOf(d);
    const sel = this.selectedDay === d || (this.selectedDay <= 0 && this.isToday(d));
    if (!hasData) return getThemeColors().bgPage === '#121212' ? '#1E1E1E' : '#E8E8E8';
    if (net > 0) return sel ? '#E8554A' : '#FFCDD2';
    return sel ? '#4CAF50' : '#C8E6C9';
  }
  dayTextColor(d: number): ResourceColor {
    if (d <= 0) return Color.Transparent;
    if ((this.selectedDay === d || (this.selectedDay <= 0 && this.isToday(d))) && this.dayMap.has(d)) return Color.White;
    return getThemeColors().textPrimary;
  }

  weekRows(): number[][] {
    const start = this.firstDow();
    const cnt = this.daysInMonth();
    const total = start + cnt;
    const rem = total % 7 === 0 ? 0 : 7 - total % 7;
    const all: number[] = [];
    let idx = 0;
    while (idx < start) { all.push(0); idx++; }
    idx = 1;
    while (idx <= cnt) { all.push(idx); idx++; }
    idx = 0;
    while (idx < rem) { all.push(0); idx++; }
    const rows: number[][] = [];
    const n = all.length;
    let i = 0;
    while (i < n) {
      const row: number[] = [];
      let j = 0;
      while (j < 7 && i < n) { row.push(all[i]); i++; j++; }
      rows.push(row);
    }
    return rows;
  }

  build() {
    Column() {
      Row() {
        Text(this.y + '年' + ((this.m + 1) < 10 ? '0' + (this.m + 1) : (this.m + 1).toString()) + '月 ▾').fontSize(17).fontWeight(FontWeight.Bold)
          .fontColor(getThemeColors().textPrimary).layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => this.showMonthPicker())
      }.width('100%').padding({ left: 20, right: 20, top: 32, bottom: 8 })

      if (!this.showPicker) {
        Row() {
          Column() {
            Text('支出').fontSize(12).fontColor(getThemeColors().textSecondary)
            Text(formatAmount(this.totalExpense)).fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(getThemeColors().expenseColor).fontFamily('monospace').margin({ top: 2 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          Column() {
            Text('收入').fontSize(12).fontColor(getThemeColors().textSecondary)
            Text(formatAmount(this.totalIncome)).fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(getThemeColors().incomeColor).fontFamily('monospace').margin({ top: 2 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          Column() {
            Text('结余').fontSize(12).fontColor(getThemeColors().textSecondary)
            Text(formatAmount(this.totalIncome - this.totalExpense)).fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(this.totalIncome - this.totalExpense >= 0 ? getThemeColors().incomeColor : getThemeColors().expenseColor)
              .fontFamily('monospace').margin({ top: 2 })
          }.layoutWeight(1).alignItems(HorizontalAlign.Center)
        }.width('100%').padding({ left: 16, right: 16, top: 8, bottom: 16 })

        Row() {
          ForEach(['一', '二', '三', '四', '五', '六', '日'], (w: string) => {
            Text(w).fontSize(12).fontColor(getThemeColors().textHint)
              .layoutWeight(1).textAlign(TextAlign.Center)
          })
        }.width('100%').padding({ left: 16, right: 16, bottom: 4 })

        Column() {
          ForEach(this.weekRows(), (row: number[]) => {
            Row() {
              ForEach(row, (d: number) => {
                Column() {
                  if (d > 0) {
                    Text(d.toString()).fontSize(14)
                      .fontColor(this.dayTextColor(d))
                    if (this.dayMap.has(d)) {
                      Text((this.netOf(d) >= 0 ? '+' : '') + formatAmount(this.netOf(d))).fontSize(9).fontWeight(FontWeight.Medium).fontFamily('monospace')
                        .fontColor((this.selectedDay === d || (this.selectedDay <= 0 && this.isToday(d))) ? Color.White :
                          (this.netOf(d) >= 0 ? '#C62828' : '#2E7D32'))
                        .margin({ top: 4 })
                    }
                  }
                }
                .width('100%').height(46).justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderRadius(6)
                .backgroundColor(this.dayBg(d))
                .layoutWeight(1)
                .margin(2)
                .onClick(() => this.selectDay(d))
              })
            }.width('100%')
          })
        }.width('100%').padding({ left: 8, right: 8 })

        // 选中日详情 或 月饼图
        if (this.selectedDay > 0) {
          Column() {
            Text(this.y + '年' + (this.m + 1) + '月' + this.selectedDay + '日')
              .fontSize(14).fontWeight(FontWeight.Medium).fontColor(getThemeColors().textPrimary)
              .padding({ left: 20, top: 2, bottom: 4 })

            Row({ space: 8 }) {
              Button('支出')
                .fontSize(13).fontWeight(this.dayType === RECORD_TYPE_EXPENSE ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.dayType === RECORD_TYPE_EXPENSE ? Color.White : getThemeColors().textSecondary)
                .backgroundColor(this.dayType === RECORD_TYPE_EXPENSE ? getThemeColors().expenseColor : getThemeColors().bgInput)
                .borderRadius(14).height(28).padding({ left: 14, right: 14 })
                .onClick(() => { this.dayType = RECORD_TYPE_EXPENSE; this.loadDayDetail(); })
              Button('收入')
                .fontSize(13).fontWeight(this.dayType === RECORD_TYPE_INCOME ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.dayType === RECORD_TYPE_INCOME ? Color.White : getThemeColors().textSecondary)
                .backgroundColor(this.dayType === RECORD_TYPE_INCOME ? getThemeColors().incomeColor : getThemeColors().bgInput)
                .borderRadius(14).height(28).padding({ left: 14, right: 14 })
                .onClick(() => { this.dayType = RECORD_TYPE_INCOME; this.loadDayDetail(); })
            }.width('100%').justifyContent(FlexAlign.Center).margin({ top: 8 })

            RankBars({ categoryStats: this.dayCatStats, centerText: '', centerAmount: this.dayTotal })
              .margin({ top: 8, bottom: 20 })
          }
        } else {
          Column() {
            Row({ space: 8 }) {
              Button('支出')
                .fontSize(13).fontWeight(this.monthCatType === RECORD_TYPE_EXPENSE ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.monthCatType === RECORD_TYPE_EXPENSE ? Color.White : getThemeColors().textSecondary)
                .backgroundColor(this.monthCatType === RECORD_TYPE_EXPENSE ? getThemeColors().expenseColor : getThemeColors().bgInput)
                .borderRadius(14).height(28).padding({ left: 14, right: 14 })
                .onClick(() => { this.monthCatType = RECORD_TYPE_EXPENSE; this.load(); })
              Button('收入')
                .fontSize(13).fontWeight(this.monthCatType === RECORD_TYPE_INCOME ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.monthCatType === RECORD_TYPE_INCOME ? Color.White : getThemeColors().textSecondary)
                .backgroundColor(this.monthCatType === RECORD_TYPE_INCOME ? getThemeColors().incomeColor : getThemeColors().bgInput)
                .borderRadius(14).height(28).padding({ left: 14, right: 14 })
                .onClick(() => { this.monthCatType = RECORD_TYPE_INCOME; this.load(); })
            }.width('100%').justifyContent(FlexAlign.Center).margin({ top: 4 })

            if (this.showPie) {
              PieChart({ categoryStats: this.monthCatStats,
                centerText: this.monthCatType === RECORD_TYPE_EXPENSE ? '总支出' : '总收入',
                centerAmount: this.monthCatType === RECORD_TYPE_EXPENSE ? this.totalExpense : this.totalIncome,
                refresh: this.pieRefresh })
                .margin({ top: 0, bottom: 0 })
            }
          }
        }
      }

      if (this.showPicker) {
        Column() {
          Row() {
            Button('‹').fontSize(20).fontColor(getThemeColors().textSecondary)
              .width(40).height(40).backgroundColor(Color.Transparent)
              .onClick(() => { this.pickYear--; })
            Text(this.pickYear.toString()).fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(getThemeColors().textPrimary).layoutWeight(1).textAlign(TextAlign.Center)
            Button('›').fontSize(20).fontColor(getThemeColors().textSecondary)
              .width(40).height(40).backgroundColor(Color.Transparent)
              .onClick(() => { this.pickYear++; })
          }.width('100%').padding({ left: 20, right: 20, top: 20 })

          Grid() {
            ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], (mon: number) => {
              GridItem() {
                Column() {
                  Text((mon + 1) + '月')
                    .fontSize(16).fontWeight(this.pickYear === this.y && mon === this.m ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.pickYear === this.y && mon === this.m ? getThemeColors().primary : getThemeColors().textPrimary)
                }
                .width('100%').height(48).justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderRadius(10)
                .backgroundColor(this.pickYear === this.y && mon === this.m ? getThemeColors().primaryLight : getThemeColors().bgInput)
                .onClick(() => this.selectMonth(mon))
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(8).columnsGap(8)
          .width('100%').padding({ left: 24, right: 24, top: 12 })

          Button('取消').fontSize(15).fontColor(getThemeColors().textSecondary)
            .backgroundColor(getThemeColors().bgInput).borderRadius(20).height(40)
            .padding({ left: 32, right: 32 }).margin({ top: 20, bottom: 20 })
            .onClick(() => { this.closeMonthPicker(); })
        }
        .width('100%').layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .backgroundColor(getThemeColors().bgPage)
  }
}
