import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { CategoryStats, MonthTrend, RECORD_TYPE_EXPENSE, RECORD_TYPE_INCOME, formatAmount }
  from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { RankBars } from '../components/RankBars';
import { LineChart } from '../components/LineChart';

interface OptionRange {
  start: number;
  end: number;
}

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
  @State selectedBarIdx: number = -1;
  @State periodLabel: string = '';
  @State periodOptions: string[] = [];
  @State selectedOptionIdx: number = 0;
  private optionRanges: OptionRange[] = [];
  private dismissTimer: number = -1;
  db = DatabaseHelper.getInstance();
  c = getThemeColors();

  aboutToAppear(): void { this.load(); }
  onRefresh(): void { this.load(); }

  selectOption(idx: number): void {
    this.selectedOptionIdx = idx;
    this.loadData();
  }

  async load(): Promise<void> {
    const ymList = await this.db.getAvailableYearMonths();
    const dates = await this.db.getAllRecordDates();
    await this.buildPeriodOptions(ymList, dates);
    // 默认选中当前所在月份
    let selIdx = this.periodOptions.length - 1; // 默认最新
    const today2 = new Date();
    const curYM = today2.getFullYear() + '-' + ((today2.getMonth() + 1).toString().padStart(2, '0'));
    let i = 0;
    while (i < this.periodOptions.length) {
      const r = this.optionRanges[i];
      const d = new Date(r.start);
      if (d.getFullYear() === today2.getFullYear() && d.getMonth() === today2.getMonth()) {
        selIdx = i; break;
      }
      i++;
    }
    this.selectedOptionIdx = selIdx;
    await this.loadData();
  }

  buildPeriodOptions(ymList: string[], dates: number[]): void {
    const today = new Date();
    const opts: string[] = [];
    const ranges: OptionRange[] = [];

    if (this.p === 0) {
      // 用实际记录日期生成有数据的周（dates 已排序，Map 保持插入顺序）
      const weekMap = new Map<string, OptionRange>();
      for (let di = 0; di < dates.length; di++) {
        const d = new Date(dates[di]);
        const mon = this.weekMon(d);
        const sun = new Date(mon.getFullYear(), mon.getMonth(), mon.getDate() + 6);
        const label = `${mon.getMonth()+1}.${mon.getDate()}-${sun.getMonth()+1}.${sun.getDate()}`;
        if (!weekMap.has(label)) {
          const range: OptionRange = {
            start: new Date(mon.getFullYear(), mon.getMonth(), mon.getDate(), 0, 0, 0).getTime(),
            end: new Date(sun.getFullYear(), sun.getMonth(), sun.getDate(), 23, 59, 59).getTime()
          };
          weekMap.set(label, range);
        }
      }
      // 遍历 Map 输出，已是插入顺序（旧→新）
      weekMap.forEach((rng: OptionRange, lbl: string) => {
        opts.push(lbl);
        ranges.push(rng);
      });
    } else if (this.p === 1) {
      for (const ym of ymList) {
        const parts = ym.split('-');
        const y = parseInt(parts[0]);
        const m = parseInt(parts[1]);
        const label = y === today.getFullYear() ? `${m}月` : `${y}年${m}月`;
        opts.push(label);
        const range: OptionRange = {
          start: new Date(y, m - 1, 1, 0, 0, 0).getTime(),
          end: new Date(y, m, 0, 23, 59, 59).getTime()
        };
        ranges.push(range);
      }
    } else {
      // 去重年份
      const yearSet = new Set<number>();
      for (const ym of ymList) {
        yearSet.add(parseInt(ym.split('-')[0]));
      }
      const years: number[] = [];
      yearSet.forEach((v: number) => { years.push(v); });
      years.sort((a: number, b: number) => b - a);
      for (const y of years) {
        opts.push(`${y}年`);
        const range: OptionRange = {
          start: new Date(y, 0, 1, 0, 0, 0).getTime(),
          end: new Date(y, 11, 31, 23, 59, 59).getTime()
        };
        ranges.push(range);
      }
    }

    // 没数据时至少显示当前周期
    if (opts.length === 0) {
      if (this.p === 0) {
        const mon = this.weekMon(today);
        const sun = new Date(mon.getFullYear(), mon.getMonth(), mon.getDate() + 6);
        opts.push(`${mon.getMonth()+1}.${mon.getDate()}-${sun.getMonth()+1}.${sun.getDate()}`);
        const range: OptionRange = {
          start: new Date(mon.getFullYear(), mon.getMonth(), mon.getDate(), 0, 0, 0).getTime(),
          end: new Date(sun.getFullYear(), sun.getMonth(), sun.getDate(), 23, 59, 59).getTime()
        };
        ranges.push(range);
      } else if (this.p === 1) {
        opts.push(`${today.getMonth()+1}月`);
        const range: OptionRange = {
          start: new Date(today.getFullYear(), today.getMonth(), 1, 0, 0, 0).getTime(),
          end: new Date(today.getFullYear(), today.getMonth() + 1, 0, 23, 59, 59).getTime()
        };
        ranges.push(range);
      } else {
        opts.push(`${today.getFullYear()}年`);
        const range: OptionRange = {
          start: new Date(today.getFullYear(), 0, 1, 0, 0, 0).getTime(),
          end: new Date(today.getFullYear(), 11, 31, 23, 59, 59).getTime()
        };
        ranges.push(range);
      }
    }

    // 月/年数据库返回是最新在前，需反转让最新在右；周已是旧→新顺序
    if (this.p !== 0) {
      this.periodOptions = opts.reverse();
      this.optionRanges = ranges.reverse();
    } else {
      this.periodOptions = opts;
      this.optionRanges = ranges;
    }
  }

  weekMon(d: Date): Date {
    const dow = d.getDay() || 7;
    return new Date(d.getFullYear(), d.getMonth(), d.getDate() - dow + 1);
  }

  async loadData(): Promise<void> {
    const range = this.optionRanges[this.selectedOptionIdx];
    if (!range) return;
    const s = range.start;
    const e = range.end;
    const now = new Date(s);
    let d: number;
    let lbl: string;
    if (this.p === 0) {
      d = 7; lbl = '日均';
      const mon = new Date(s);
      const sun = new Date(e);
      this.periodLabel = `${mon.getMonth()+1}.${mon.getDate()}-${sun.getMonth()+1}.${sun.getDate()}`;
    } else if (this.p === 1) {
      d = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate(); lbl = '日均';
      this.periodLabel = this.periodOptions[this.selectedOptionIdx];
    } else {
      d = 12; lbl = '月均';
      this.periodLabel = this.periodOptions[this.selectedOptionIdx];
    }
    this.al = lbl;
    this.catStats = await this.db.getPeriodCategoryStats(s, e, this.t);
    this.total = 0;
    for (const cs of this.catStats) this.total += cs.amount;
    this.av = d > 0 ? this.total / d : 0;

    // 补全周期内所有日期/月份，缺失填0
    const dbBars = await this.db.getDayBars(s, e, this.t, this.p === 2 ? 'month' : 'day');
    const barMap = new Map<string, MonthTrend>();
    for (const b of dbBars) barMap.set(b.label, b);

    const bars: MonthTrend[] = [];
    if (this.p === 0) {
      const startDate = new Date(s);
      for (let i = 0; i < 7; i++) {
        const dt = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + i);
        const key = `${dt.getFullYear()}-${(dt.getMonth() + 1).toString().padStart(2, '0')}-${dt.getDate().toString().padStart(2, '0')}`;
        const exist = barMap.get(key);
        bars.push(exist || { year: dt.getFullYear(), month: dt.getMonth(), label: key, income: 0, expense: 0 });
      }
    } else if (this.p === 1) {
      const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
      for (let i = 1; i <= daysInMonth; i++) {
        const key = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}-${i.toString().padStart(2, '0')}`;
        const exist = barMap.get(key);
        bars.push(exist || { year: now.getFullYear(), month: now.getMonth(), label: key, income: 0, expense: 0 });
      }
    } else {
      for (let i = 1; i <= 12; i++) {
        const key = `${now.getFullYear()}-${i.toString().padStart(2, '0')}`;
        const exist = barMap.get(key);
        bars.push(exist || { year: now.getFullYear(), month: i - 1, label: key, income: 0, expense: 0 });
      }
    }
    this.bars = bars;

    // 从 label 解析 year/month（DB 数据默认都是 0）
    for (const b of this.bars) {
      if (b.year === 0) {
        const parts = b.label.split('-');
        if (parts.length >= 2) {
          b.year = parseInt(parts[0]);
          b.month = parseInt(parts[1]) - 1;
        }
      }
    }

    // 缩短标签显示
    for (const b of this.bars) {
      if (this.p === 0 || this.p === 1) {
        b.label = b.label.substring(b.label.length - 2);
        if (this.p === 1) {
          const day = parseInt(b.label);
          if (day % 2 === 0) b.label = '';
        }
      } else {
        const parts = b.label.split('-');
        b.label = parts.length > 1 ? `${parseInt(parts[1])}月` : b.label;
      }
    }

    // 无记录则清空
    let hasData = false;
    for (const b of this.bars) {
      if (b.expense > 0 || b.income > 0) { hasData = true; break; }
    }
    if (!hasData) this.bars = [];
  }

  cardDateLabel(): string {
    const b = this.bars[this.selectedBarIdx];
    if (this.p === 2) return b.label;
    const m = b.month + 1;
    if (this.p === 1) return `${m}月${this.selectedBarIdx + 1}日`;
    return `${m}月${b.label}日`;
  }

  handleBarSelect(idx: number): void {
    clearTimeout(this.dismissTimer);
    this.selectedBarIdx = idx;
    if (idx >= 0) {
      this.dismissTimer = setTimeout(() => { this.selectedBarIdx = -1; }, 2000);
    }
  }

  build() {
    Stack() {
    Column() {
      Text('统计分析').fontSize(17).fontWeight(FontWeight.Bold)
        .fontColor(this.c.textPrimary).width('100%').textAlign(TextAlign.Center)
        .padding({ left: 20, right: 20, top: 32, bottom: 8 })

      // 固定筛选栏 1：周期类型 + 收支切换
      Row() {
        Button('周').fontSize(14).fontWeight(this.p === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.p === 0 ? Color.White : this.c.textSecondary)
          .backgroundColor(this.p === 0 ? this.c.primary : Color.Transparent)
          .borderRadius(14).height(28).padding({ left: 16, right: 16 })
          .onClick(() => { this.p = 0; this.load(); })
        Button('月').fontSize(14).fontWeight(this.p === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.p === 1 ? Color.White : this.c.textSecondary)
          .backgroundColor(this.p === 1 ? this.c.primary : Color.Transparent)
          .borderRadius(14).height(28).padding({ left: 16, right: 16 }).margin({ left: 8 })
          .onClick(() => { this.p = 1; this.load(); })
        Button('年').fontSize(14).fontWeight(this.p === 2 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.p === 2 ? Color.White : this.c.textSecondary)
          .backgroundColor(this.p === 2 ? this.c.primary : Color.Transparent)
          .borderRadius(14).height(28).padding({ left: 16, right: 16 }).margin({ left: 8 })
          .onClick(() => { this.p = 2; this.load(); })
        Blank()
        Button('支出').fontSize(13).fontWeight(this.t === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.t === 0 ? Color.White : this.c.textSecondary)
          .backgroundColor(this.t === 0 ? this.c.expenseColor : Color.Transparent)
          .borderRadius(14).height(28).padding({ left: 14, right: 14 })
          .onClick(() => { this.t = 0; this.loadData(); })
        Button('收入').fontSize(13).fontWeight(this.t === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.t === 1 ? Color.White : this.c.textSecondary)
          .backgroundColor(this.t === 1 ? this.c.incomeColor : Color.Transparent)
          .borderRadius(14).height(28).padding({ left: 14, right: 14 }).margin({ left: 6 })
          .onClick(() => { this.t = 1; this.loadData(); })
      }.width('100%').padding({ left: 20, right: 16, top: 8, bottom: 4 })

      // 固定筛选栏 2：横向滑动周期选择器
      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.periodOptions, (label: string, idx: number) => {
            Text(label)
              .fontSize(13).fontWeight(idx === this.selectedOptionIdx ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(idx === this.selectedOptionIdx ? this.c.primary : this.c.textSecondary)
              .padding({ left: 14, right: 14, top: 6, bottom: 4 })
              .onClick(() => { this.selectOption(idx); })
          })
        }.padding({ left: 20, right: 20 })
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      .width('100%').padding({ bottom: 8 })

      Scroll() {
        Column() {
          Row() {
            Column() {
              Text('总' + (this.t === 0 ? '支出' : '收入')).fontSize(13).fontColor(this.c.textSecondary)
              Text(formatAmount(this.total)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.t === 0 ? this.c.expenseColor : this.c.incomeColor)
                .fontFamily('monospace').margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column() {
              Text(this.al).fontSize(13).fontColor(this.c.textSecondary)
              Text(formatAmount(this.av)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.c.textPrimary).fontFamily('monospace').margin({ top: 4 })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }.width('100%').height(96).padding(20).backgroundColor(this.c.bgCard).borderRadius(16)
          .margin({ left: 16, right: 16, bottom: 16 })

          Column() {
            Text(this.periodLabel)
              .fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.c.textPrimary)
              .padding({ left: 20, top: 14 })
            Column() {
              LineChart({ trends: this.bars, showIncome: this.t === 1, showExpense: this.t === 0,
                selectedIdx: this.selectedBarIdx,
                onSelect: (idx: number) => { this.handleBarSelect(idx); } })
            }.layoutWeight(1)
          }.width('100%').height(180).backgroundColor(this.c.bgCard).borderRadius(16).clip(false)
          .margin({ left: 16, right: 16, bottom: 16 })

          Column() {
            Text(this.t === 0 ? '支出排行' : '收入排行').fontSize(14)
              .fontWeight(FontWeight.Medium).fontColor(this.c.textPrimary)
              .padding({ left: 20, top: 14, bottom: 8 })
            RankBars({ categoryStats: this.catStats, centerText: '', centerAmount: this.total })
          }.width('100%').height(420).backgroundColor(this.c.bgCard).borderRadius(16)
          .margin({ left: 16, right: 16, bottom: 80 })
        }
      }.scrollBar(BarState.Off).layoutWeight(1)
    }.width('100%').height('100%').backgroundColor(this.c.bgPage)

    if (this.selectedBarIdx >= 0 && this.selectedBarIdx < this.bars.length) {
      Column() {
        Row() {
          Text(this.cardDateLabel())
            .fontSize(12).fontColor(this.c.textHint)
          Blank()
          Text('✕').fontSize(16).fontColor(this.c.textHint)
            .onClick(() => { clearTimeout(this.dismissTimer); this.selectedBarIdx = -1; })
        }.width('100%').alignItems(VerticalAlign.Center)
        Text(formatAmount(this.t === 0 ? this.bars[this.selectedBarIdx].expense : this.bars[this.selectedBarIdx].income))
          .fontSize(24).fontWeight(FontWeight.Bold).fontFamily('monospace')
          .fontColor(this.t === 0 ? this.c.expenseColor : this.c.incomeColor)
          .margin({ top: 8 })
          .alignSelf(ItemAlign.Start)
      }
      .width('75%').padding({ left: 16, right: 16, top: 12, bottom: 14 })
      .backgroundColor(this.c.bgCard)
      .borderRadius(12)
      .shadow({ radius: 16, color: '#40000000', offsetY: 6 })
      .position({ x: '12.5%', y: 134 })
    }
    }.width('100%').height('100%')
  }
}
