/**
 * 分类排行 — 横向进度条
 */
import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { CategoryStats, formatAmount } from '../models/FinanceModels';

@Component
export struct RankBars {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Prop categoryStats: CategoryStats[] = [];
  @Prop centerText: string = '总支出';
  @Prop centerAmount: number = 0;

  build() {
    Column() {
      if (this.centerText) {
        Text(this.centerText).fontSize(13).fontColor(getThemeColors().textSecondary)
        Text(formatAmount(this.centerAmount)).fontSize(32).fontWeight(FontWeight.Bold)
          .fontColor(getThemeColors().textPrimary).fontFamily('monospace').margin({ top: 4, bottom: 20 })
      }

      if (this.categoryStats.length === 0) {
        Text('暂无数据').fontSize(14).fontColor(getThemeColors().textHint).margin({ top: 20 })
      } else {
        Column({ space: 12 }) {
          ForEach(this.categoryStats.slice(0, 8), (s: CategoryStats, i: number) => {
            this.RankBar(s, i)
          })
        }.width('100%').padding({ left: 16, right: 16 })
      }
    }.width('100%')
  }

  @Builder RankBar(s: CategoryStats, idx: number) {
    Row() {
      Text(s.categoryName).fontSize(14).fontColor(getThemeColors().textPrimary).width(64)
      Progress({ value: s.amount, total: this.centerAmount > 0 ? this.centerAmount : 100,
        type: ProgressType.Linear })
        .height(8).color(getThemeColors().chartColors[idx % 10])
        .backgroundColor(getThemeColors().bgInput).layoutWeight(1)
        .margin({ left: 8, right: 8 })
      Row() {
        Text(formatAmount(s.amount)).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().textPrimary).fontFamily('monospace')
          .width(64).textAlign(TextAlign.End)
        Text(s.percent.toFixed(1) + '%').fontSize(11).fontColor(getThemeColors().textHint)
          .width(42).textAlign(TextAlign.End).margin({ left: 4 })
      }.alignItems(VerticalAlign.Center)
    }.width('100%')
  }
}
