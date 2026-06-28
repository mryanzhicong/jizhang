/**
 * 柱状图 — 纯组件实现
 */
import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { MonthTrend, formatAmount } from '../models/FinanceModels';

@Component
export struct LineChart {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Prop trends: MonthTrend[] = [];
  @Prop showIncome: boolean = true;
  @Prop showExpense: boolean = true;
  @Prop selectedIdx: number = -1;
  onSelect?: (idx: number) => void;

  build() {
    Column() {
      if (this.trends.length === 0) {
        Text('暂无数据').fontSize(14).fontColor(getThemeColors().textHint).margin({ top: 20 })
      } else {
        Row({ space: 0 }) {
          ForEach(this.trends, (t: MonthTrend, i: number) => {
            Column() {
              if (this.showExpense && this.barH(t.expense) > 0) {
                Column()
                  .width(i === this.selectedIdx ? 12 : 10)
                  .height(this.barH(t.expense))
                  .backgroundColor(getThemeColors().expenseColor)
                  .borderRadius(2)
                  .opacity(i === this.selectedIdx ? 1 : 0.75)
              }
              if (this.showIncome && this.barH(t.income) > 0) {
                Column()
                  .width(i === this.selectedIdx ? 12 : 10)
                  .height(this.barH(t.income))
                  .backgroundColor(getThemeColors().incomeColor)
                  .borderRadius(2)
                  .margin({ top: 2 })
                  .opacity(i === this.selectedIdx ? 1 : 0.7)
              }
            }
            .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.End)
            .layoutWeight(1)
            .backgroundColor(i === this.selectedIdx ? getThemeColors().bgInput : Color.Transparent)
            .borderRadius(4)
            .onClick(() => {
              const newIdx = this.selectedIdx === i ? -1 : i;
              if (this.onSelect) this.onSelect(newIdx);
            })
          })
        }.width('100%').padding({ left: 16, right: 16, top: 8 })
        .alignItems(VerticalAlign.Bottom)

        Row({ space: 0 }) {
          ForEach(this.trends, (t: MonthTrend) => {
            Text(t.label).fontSize(9).fontColor(getThemeColors().textHint)
              .layoutWeight(1).textAlign(TextAlign.Center)
          })
        }.width('100%').padding({ left: 16, right: 16, top: 4 })
      }
    }.width('100%').height('100%').justifyContent(FlexAlign.End).padding({ bottom: 5 })
  }

  barH(val: number): number {
    const max = this.maxVal();
    if (max === 0 || val === 0) return 0;
    return Math.max(4, (val / max) * 110);
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
