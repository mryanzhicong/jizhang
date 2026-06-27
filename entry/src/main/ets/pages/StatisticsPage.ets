import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { CategoryStats, MonthTrend, RECORD_TYPE_EXPENSE, RECORD_TYPE_INCOME, formatAmount }
  from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { PieChart } from '../components/PieChart';
import { LineChart } from '../components/LineChart';

@Component
export struct StatisticsPage {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @StorageLink('refreshTrigger') @Watch('onRefresh') refresh: number = 0;
  @State p: number = 0;
  @State t: number = RECORD_TYPE_EXPENSE;
  @State catStats: CategoryStats[] = [];
  @State bars: MonthTrend[] = [];
  @State total: number = 0;
  @State al: string = '日均';
  @State av: number = 0;
  db = DatabaseHelper.getInstance();
  c = getThemeColors();

  aboutToAppear(): void { this.load(); }
  onRefresh(): void { this.load(); }

  async load(): Promise<void> {
    const now = new Date();
    let s: number, e: number, d: number, lbl: string;
    if (this.p === 0) {
      const dow = now.getDay() || 7;
      s = new Date(now.getFullYear(), now.getMonth(), now.getDate()-dow+1,0,0,0).getTime();
      e = new Date(now.getFullYear(), now.getMonth(), now.getDate()+(7-dow),23,59,59).getTime();
      d = 7; lbl = '日均';
    } else if (this.p === 1) {
      s = new Date(now.getFullYear(), now.getMonth(),1,0,0,0).getTime();
      e = new Date(now.getFullYear(), now.getMonth()+1,0,23,59,59).getTime();
      d = new Date(now.getFullYear(), now.getMonth()+1,0).getDate(); lbl = '日均';
    } else {
      s = new Date(now.getFullYear(),0,1,0,0,0).getTime();
      e = new Date(now.getFullYear(),11,31,23,59,59).getTime();
      d = 12; lbl = '月均';
    }
    this.al = lbl;
    this.catStats = await this.db.getPeriodCategoryStats(s, e, this.t);
    this.bars = await this.db.getDayBars(s, e, this.t, this.p===2?'month':'day');
    this.total = 0;
    for (const cs of this.catStats) this.total += cs.amount;
    this.av = d > 0 ? this.total / d : 0;
    for (const b of this.bars) {
      if (this.p === 0 || this.p === 1) b.label = b.label.substring(b.label.length - 2);
      else { const parts = b.label.split('-'); b.label = parts.length>1?`${parseInt(parts[1])}月`:b.label; }
    }
  }

  build() {
    Column() {
      Text('统计分析').fontSize(20).fontWeight(FontWeight.Bold)
        .fontColor(this.c.textPrimary).padding({ left: 20, top: 12, bottom: 8 })

      Scroll() {
        Column() {
          Row() {
            Button('周').fontSize(14).fontWeight(this.p===0?FontWeight.Bold:FontWeight.Normal)
              .fontColor(this.p===0?Color.White:this.c.textSecondary)
              .backgroundColor(this.p===0?this.c.primary:Color.Transparent)
              .borderRadius(14).height(28).padding({ left: 16, right: 16 })
              .onClick(() => { this.p=0; this.load(); })
            Button('月').fontSize(14).fontWeight(this.p===1?FontWeight.Bold:FontWeight.Normal)
              .fontColor(this.p===1?Color.White:this.c.textSecondary)
              .backgroundColor(this.p===1?this.c.primary:Color.Transparent)
              .borderRadius(14).height(28).padding({ left: 16, right: 16 }).margin({ left: 8 })
              .onClick(() => { this.p=1; this.load(); })
            Button('年').fontSize(14).fontWeight(this.p===2?FontWeight.Bold:FontWeight.Normal)
              .fontColor(this.p===2?Color.White:this.c.textSecondary)
              .backgroundColor(this.p===2?this.c.primary:Color.Transparent)
              .borderRadius(14).height(28).padding({ left: 16, right: 16 }).margin({ left: 8 })
              .onClick(() => { this.p=2; this.load(); })
            Blank()
            Button('支出').fontSize(13).fontWeight(this.t===0?FontWeight.Bold:FontWeight.Normal)
              .fontColor(this.t===0?Color.White:this.c.textSecondary)
              .backgroundColor(this.t===0?this.c.expenseColor:Color.Transparent)
              .borderRadius(14).height(28).padding({ left: 14, right: 14 })
              .onClick(() => { this.t=0; this.load(); })
            Button('收入').fontSize(13).fontWeight(this.t===1?FontWeight.Bold:FontWeight.Normal)
              .fontColor(this.t===1?Color.White:this.c.textSecondary)
              .backgroundColor(this.t===1?this.c.incomeColor:Color.Transparent)
              .borderRadius(14).height(28).padding({ left: 14, right: 14 }).margin({ left: 6 })
              .onClick(() => { this.t=1; this.load(); })
          }.width('100%').padding({ left: 20, right: 16, top: 12, bottom: 16 })

          // 第一步：只显示总额（无柱状图、无排行）
          Row() {
            Column() {
              Text('总'+(this.t===0?'支出':'收入')).fontSize(13).fontColor(this.c.textSecondary)
              Text(formatAmount(this.total)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.t===0?this.c.expenseColor:this.c.incomeColor)
                .fontFamily('monospace').margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column() {
              Text(this.al).fontSize(13).fontColor(this.c.textSecondary)
              Text(formatAmount(this.av)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.c.textPrimary).fontFamily('monospace').margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }.width('100%').height(96).padding(20).backgroundColor(this.c.bgCard).borderRadius(16)
          .margin({ left: 16, right: 16, bottom: 16 })

          // 柱状图 — 真实数据
          Column() {
            Text(this.p===0?'本周每日':this.p===1?'本月每日':'本年每月')
              .fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.c.textPrimary)
              .padding({ left: 20, top: 14 })
            LineChart({ trends: this.bars, showIncome: this.t===1, showExpense: this.t===0 })
          }.width('100%').height(160).backgroundColor(this.c.bgCard).borderRadius(16)
          .margin({ left: 16, right: 16, bottom: 16 })

          // 排行 — 加固定高度防止切换跳变
          Column() {
            Text(this.t===0?'支出排行':'收入排行').fontSize(14)
              .fontWeight(FontWeight.Medium).fontColor(this.c.textPrimary)
              .padding({ left: 20, top: 14, bottom: 8 })
            PieChart({ categoryStats: this.catStats, centerText: '', centerAmount: this.total })
          }.width('100%').height(420).backgroundColor(this.c.bgCard).borderRadius(16)
          .margin({ left: 16, right: 16, bottom: 80 })
        }
      }.scrollBar(BarState.Off).layoutWeight(1)
    }.width('100%').height('100%').backgroundColor(this.c.bgPage)
  }
}
