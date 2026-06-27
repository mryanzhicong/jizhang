/**
 * 预算进度条组件
 * 显示月度预算使用情况
 * 绿色(正常) → 橙色(接近预算) → 红色(超预算)
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';

@Component
export struct BudgetProgress {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Prop budgetAmount: number = 0;
  @Prop expenseAmount: number = 0;

  private colors: ThemeColors = getThemeColors();

  build() {
    Column() {
      if (this.budgetAmount > 0) {
        Row() {
          Text('预算')
            .fontSize(12)
            .fontColor(this.colors.textSecondary)
          Blank()
          Text(`${this.expenseAmount.toFixed(0)} / ${this.budgetAmount.toFixed(0)}`)
            .fontSize(12)
            .fontColor(this.colors.textSecondary)
        }
        .width('100%')
        .margin({ bottom: 6 })

        // 进度条
        Progress({
          value: Math.min(this.expenseAmount, this.budgetAmount),
          total: this.budgetAmount,
          type: ProgressType.Linear
        })
        .width('100%')
        .height(6)
        .style({ strokeWidth: 6, strokeRadius: 3 })
        .color(this.getProgressColor())
        .backgroundColor(this.colors.bgInput)
      }
    }
    .width('100%')
  }

  getProgressColor(): ResourceColor {
    const ratio = this.budgetAmount > 0
      ? this.expenseAmount / this.budgetAmount
      : 0;
    if (ratio >= 1) return this.colors.expenseColor;      // 超预算-红色
    if (ratio >= 0.8) return '#FF9800';                     // 接近-橙色
    return this.colors.primary;                              // 正常-蓝色
  }
}
