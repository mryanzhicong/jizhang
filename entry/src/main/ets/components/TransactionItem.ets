/**
 * 交易记录行组件 - 左滑删除
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { RecordDisplay, RECORD_TYPE_INCOME, formatAmountWithSign } from '../models/FinanceModels';
import { getCategoryEmoji } from '../common/IconHelper';

@Component
export struct TransactionItem {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Prop record: RecordDisplay;
  onDelete?: (id: number) => void;
  onEdit?: (record: RecordDisplay) => void;
  @State offsetX: number = 0;

  private colors: ThemeColors = getThemeColors();

  build() {
    Stack({ alignContent: Alignment.End }) {
      // 红色删除按钮
      Button('删除')
        .fontSize(13).fontColor(Color.White)
        .width(52).padding({ top: 16, bottom: 16 })
        .backgroundColor(this.colors.expenseColor)
        .borderRadius({ topRight: 12, bottomRight: 12 })
      .onClick(() => {
        this.offsetX = 0;
        if (this.onDelete) this.onDelete(this.record.id);
      })

      Row() {
        Column() {
          Text(getCategoryEmoji(this.record.categoryIcon))
            .fontSize(24)
        }
        .width(44).height(44)
        .borderRadius(22)
        .backgroundColor(this.isExp() ? '#FDEAEA' : '#E8F5E9')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(this.record.categoryName)
            .fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textPrimary)
            .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.record.note) {
            Text(this.record.note)
              .fontSize(12).fontColor(this.colors.textHint)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 }).layoutWeight(1)

        Text(formatAmountWithSign(this.record.amount, this.record.type))
          .fontSize(17).fontWeight(FontWeight.Medium)
          .fontColor(this.isExp() ? this.colors.expenseColor : this.colors.incomeColor)
          .fontFamily('monospace')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor(this.colors.bgCard)
      .borderRadius(12)
      .offset({ x: this.offsetX })
      .gesture(
        PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 5 })
          .onActionStart(() => { })
          .onActionUpdate((event: GestureEvent) => {
            if (event.offsetX > 0) { this.offsetX = 0; }
            else if (event.offsetX < -56) { this.offsetX = -56; }
            else { this.offsetX = event.offsetX; }
          })
          .onActionEnd(() => {
            this.offsetX = this.offsetX < -28 ? -56 : 0;
          })
      )
      .onClick(() => {
        if (this.offsetX < 0) { this.offsetX = 0; return; }
        if (this.onEdit) this.onEdit(this.record);
      })
    }
    .width('100%').margin({ bottom: 1 })
  }

  isExp(): boolean { return this.record.type !== RECORD_TYPE_INCOME; }
}
