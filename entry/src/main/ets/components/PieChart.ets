/**
 * 统计展示 — 总金额 + 分类排行（不用Canvas，可靠渲染）
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { CategoryStats, formatAmount } from '../models/FinanceModels';

@Component
export struct PieChart {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Prop categoryStats: CategoryStats[] = [];
  @Prop centerText: string = '总支出';
  @Prop centerAmount: number = 0;

  build() {
    Column() {
      // 总额显示
      Text(this.centerText).fontSize(13).fontColor(getThemeColors().textSecondary)
      Text(formatAmount(this.centerAmount)).fontSize(32).fontWeight(FontWeight.Bold)
        .fontColor(getThemeColors().textPrimary).fontFamily('monospace').margin({ top: 4, bottom: 20 })

      // 分类排行
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
      Column() {
        Text(formatAmount(s.amount)).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor(getThemeColors().textPrimary).fontFamily('monospace')
        Text(`${s.percent.toFixed(1)}%`).fontSize(11).fontColor(getThemeColors().textHint)
      }.width(60).alignItems(HorizontalAlign.End)
    }.width('100%')
  }
}
