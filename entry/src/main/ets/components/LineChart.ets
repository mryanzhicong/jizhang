/**
 * 月度趋势 — 纯组件实现
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { MonthTrend, formatAmount } from '../models/FinanceModels';

@Component
export struct LineChart {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Prop trends: MonthTrend[] = [];
  @Prop showIncome: boolean = true;
  @Prop showExpense: boolean = true;

  build() {
    Column() {
      if (this.trends.length === 0) {
        Text('暂无数据').fontSize(14).fontColor(getThemeColors().textHint).margin({ top: 20 })
      } else {
        Row({ space: 0 }) {
          ForEach(this.trends, (t: MonthTrend) => {
            Column() {
              // 支出柱（红色在上）
              Column()
                .width(16)
                .height(this.barH(t.expense))
                .backgroundColor(getThemeColors().expenseColor)
                .borderRadius(3)
                .visibility(this.showExpense ? Visibility.Visible : Visibility.Hidden)
              // 收入柱（绿色在下）
              Column()
                .width(16)
                .height(this.barH(t.income))
                .backgroundColor(getThemeColors().incomeColor)
                .borderRadius(3)
                .margin({ top: 2 })
                .visibility(this.showIncome ? Visibility.Visible : Visibility.Hidden)
              Text(t.label).fontSize(9).fontColor(getThemeColors().textHint).margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)
            .layoutWeight(1)
          })
        }.width('100%').padding({ left: 16, right: 16, top: 8 })
        .alignItems(VerticalAlign.Bottom)

      }
    }.width('100%')
  }

  barH(val: number): number {
    const max = this.maxVal();
    if (max === 0) return 0;
    return Math.max(4, (val / max) * 80);
  }

  maxVal(): number {
    let m = 0;
    for (const t of this.trends) {
      if (this.showExpense && t.expense > m) m = t.expense;
      if (this.showIncome && t.income > m) m = t.income;
    }
    return m > 0 ? m : 100;
  }
}
