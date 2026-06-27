/**
 * 自定义数字键盘组件
 * 类似计算器布局，用于金额输入
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';

@Component
export struct NumKeyboard {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Link amountStr: string;
  onConfirm?: () => void;
  onClear?: () => void;

  private colors: ThemeColors = getThemeColors();

  build() {
    Column() {
      // 计算结果展示行
      Row() {
        Text(this.amountStr || '0')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colors.textPrimary)
          .fontFamily('monospace')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .padding({ right: 16 })
      }
      .width('100%')
      .height(64)
      .backgroundColor(this.colors.bgInput)
      .borderRadius(8)
      .margin({ left: 16, right: 16, top: 8, bottom: 8 })

      // 键盘网格
      Grid() {
        GridItem() { this.KeyButton('7') }
        GridItem() { this.KeyButton('8') }
        GridItem() { this.KeyButton('9') }
        GridItem() { this.KeyButton('清除', true) }

        GridItem() { this.KeyButton('4') }
        GridItem() { this.KeyButton('5') }
        GridItem() { this.KeyButton('6') }
        GridItem() { this.KeyButton('.') }

        GridItem() { this.KeyButton('1') }
        GridItem() { this.KeyButton('2') }
        GridItem() { this.KeyButton('3') }
        GridItem() { this.KeyButton('完成', false, true) }

        GridItem() { this.KeyButton('00', false, false, 2) }
        GridItem() { this.KeyButton('0') }
        GridItem() { this.KeyButton('⌫', true) }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(1)
      .rowsGap(1)
      .width('100%')
      .height(280)
      .backgroundColor(this.colors.divider)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
  }

  @Builder
  KeyButton(label: string, isAction: boolean = false, isConfirm: boolean = false, colSpan: number = 1) {
    Button(label)
      .fontSize(isAction ? 16 : 24)
      .fontWeight(isConfirm ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(isConfirm || isAction
        ? this.colors.primary
        : this.colors.textPrimary)
      .backgroundColor(this.colors.bgCard)
      .borderRadius(0)
      .width('100%')
      .height('100%')
      .onClick(() => {
        this.onKeyPress(label);
      })
  }

  onKeyPress(key: string): void {
    if (key === '完成') {
      // 确保有值
      if (!this.amountStr || this.amountStr === '') {
        this.amountStr = '0';
      }
      // 移除末尾多余的小数点
      if (this.amountStr.endsWith('.')) {
        this.amountStr = this.amountStr.slice(0, -1);
      }
      if (this.onConfirm) {
        this.onConfirm();
      }
      return;
    }

    if (key === '清除') {
      this.amountStr = '';
      if (this.onClear) {
        this.onClear();
      }
      return;
    }

    if (key === '⌫') {
      this.amountStr = this.amountStr.slice(0, -1);
      return;
    }

    if (key === '.') {
      if (this.amountStr.includes('.')) return;
      if (this.amountStr === '' || this.amountStr === '0') {
        this.amountStr = '0.';
        return;
      }
      this.amountStr += '.';
      return;
    }

    // 数字键
    if (this.amountStr === '0' || this.amountStr === '') {
      this.amountStr = key;
      return;
    }

    // 限制小数点后 2 位
    if (this.amountStr.includes('.')) {
      const parts = this.amountStr.split('.');
      if (parts[1].length >= 2) return;
    }

    // 限制总长度
    if (this.amountStr.replace('.', '').length >= 9) return;

    this.amountStr += key;
  }
}
