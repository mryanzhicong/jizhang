/**
 * 饼图（环形） + 图例 + 横柱排行
 */
import { IS_DARK_KEY, getThemeColors } from '../common/ThemeManager';
import { CategoryStats, formatAmount } from '../models/FinanceModels';

@Component
export struct PieChart {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Prop categoryStats: CategoryStats[] = [];
  @Prop centerText: string = '总支出';
  @Prop centerAmount: number = 0;
  @Prop refresh: number = 0;

  top5(): CategoryStats[] {
    if (this.categoryStats.length <= 5) return this.categoryStats;
    const top = this.categoryStats.slice(0, 5);
    let otherAmount = 0;
    for (let i = 5; i < this.categoryStats.length; i++) otherAmount += this.categoryStats[i].amount;
    const otherPercent = this.centerAmount > 0 ? (otherAmount / this.centerAmount) * 100 : 0;
    top.push({
      categoryId: 0, categoryName: '其他', categoryIcon: '',
      parentCategoryId: 0, parentCategoryName: '',
      amount: otherAmount, percent: otherPercent, count: 0
    });
    return top;
  }

  build() {
    Column() {
      if (this.top5().length === 0) {
        Text('暂无数据').fontSize(14).fontColor(getThemeColors().textHint).margin({ top: 20 })
      } else {
        Row() {
          Stack({ alignContent: Alignment.Center }) {
            Canvas(this.ctx)
              .width(150).height(150)
              .onReady(() => { this.drawRing(); })
            Column() {
              Text(this.centerText).fontSize(10).fontColor(getThemeColors().textSecondary)
              Text(formatAmount(this.centerAmount)).fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(getThemeColors().textPrimary).fontFamily('monospace').margin({ top: 1 })
            }
          }
          .layoutWeight(1).height(150).margin({ left: 35 })

          Column({ space: 6 }) {
            ForEach(this.top5(), (s: CategoryStats, i: number) => {
              Row() {
                Blank()
                Column()
                  .width(8).height(8).borderRadius(4)
                  .backgroundColor(getThemeColors().chartColors[i % 10])
                Text(s.categoryName).fontSize(12).fontColor(getThemeColors().textPrimary)
                  .margin({ left: 4, right: 50 })
                Text(s.percent.toFixed(1) + '%').fontSize(11).fontColor(getThemeColors().textSecondary)
                  .width(42).textAlign(TextAlign.End)
              }.width('100%')
            })
          }
          .layoutWeight(1).margin({ left: 12 })
        }
        .width('100%').padding({ left: 12, right: 12, top: 0 })

        Column({ space: 6 }) {
          ForEach(this.top5(), (s: CategoryStats, i: number) => {
            Row() {
              Text(s.categoryName).fontSize(12).fontColor(getThemeColors().textPrimary)
                .width(36)
              Progress({ value: s.amount, total: this.centerAmount > 0 ? this.centerAmount : 100,
                type: ProgressType.Linear })
                .height(6).color(getThemeColors().chartColors[i % 10])
                .backgroundColor(getThemeColors().bgInput).layoutWeight(1)
                .margin({ left: 4, right: 4 })
              Text(formatAmount(s.amount)).fontSize(12).fontWeight(FontWeight.Medium)
                .fontColor(getThemeColors().textPrimary).fontFamily('monospace')
                .width(64).textAlign(TextAlign.End)
            }.width('100%')
          })
        }.width('100%').padding({ left: 16, right: 8 }).margin({ top: 0 })
      }
    }.width('100%')
  }

  drawRing(): void {
    this.ctx.reset();
    const stats = this.top5();
    const cx = 75; const cy = 75; const r = 60;
    let startAngle = -Math.PI / 2;
    const total = this.centerAmount > 0 ? this.centerAmount : 1;
    for (let k = 0; k < stats.length; k++) {
      const s = stats[k];
      const sweep = (s.amount / total) * Math.PI * 2;
      this.ctx.beginPath();
      this.ctx.moveTo(cx, cy);
      this.ctx.arc(cx, cy, r, startAngle, startAngle + sweep);
      this.ctx.closePath();
      this.ctx.fillStyle = getThemeColors().chartColors[k % 10];
      this.ctx.fill();
      startAngle += sweep;
    }
    this.ctx.beginPath();
    this.ctx.arc(cx, cy, 38, 0, Math.PI * 2);
    this.ctx.fillStyle = getThemeColors().bgCard;
    this.ctx.fill();
  }

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
}
