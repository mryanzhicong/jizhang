/**
 * 记账面板 — 选分类 → 输金额 → 点完成保存
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { RECORD_TYPE_EXPENSE, RECORD_TYPE_INCOME, Category, RecordDisplay } from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { getCategoryEmoji } from '../common/IconHelper';

@Component
export struct AddRecordPanel {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Link showPanel: boolean;
  onRecordAdded?: () => void;
  editRecord?: RecordDisplay;

  @State recordType: number = RECORD_TYPE_EXPENSE;
  @State selectedCategoryId: number = 0;
  @State selectedCategoryName: string = '';
  @State selectedCategoryIcon: string = '';
  @State parentCategories: Category[] = [];
  @State amountStr: string = '';
  @State note: string = '';
  @State showNoteField: boolean = true;
  @State selectedDate: Date = new Date();
  @State dateStr: string = '今天';
  @State keyboardActive: boolean = false;
  // 计算器状态
  @State firstNum: string = '';
  @State secondNum: string = '';
  @State op: string = '';
  @State displayStr: string = '';

  private db: DatabaseHelper = DatabaseHelper.getInstance();
  private colors: ThemeColors = getThemeColors();

  aboutToAppear(): void {
    if (this.editRecord) {
      this.recordType = this.editRecord.type;
      this.selectedCategoryId = this.editRecord.categoryId;
      this.selectedCategoryName = this.editRecord.categoryName;
      this.selectedCategoryIcon = this.editRecord.categoryIcon;
      this.displayStr = this.editRecord.amount.toString();
      this.firstNum = this.editRecord.amount.toString();
      this.note = this.editRecord.note;
      this.selectedDate = new Date(this.editRecord.date);
      this.dateStr = `${this.selectedDate.getMonth()+1}月${this.selectedDate.getDate()}日`;
      this.keyboardActive = false;
    } else {
      this.resetForm();
    }
    this.loadCategories();
  }

  async loadCategories(): Promise<void> {
    this.parentCategories = await this.db.getParentCategories(this.recordType);
  }

  resetForm(): void {
    this.keyboardActive = false; this.amountStr = ''; this.note = '';
    this.showNoteField = true; this.selectedCategoryId = 0;
    this.selectedCategoryName = ''; this.selectedCategoryIcon = '';
    this.selectedDate = new Date(); this.dateStr = '今天';
    this.firstNum = ''; this.secondNum = ''; this.op = ''; this.displayStr = '';
  }

  selectCategory(cat: Category): void {
    this.selectedCategoryId = cat.id;
    this.selectedCategoryName = cat.name;
    this.selectedCategoryIcon = cat.icon;
    this.firstNum = ''; this.secondNum = ''; this.op = ''; this.displayStr = '';
    this.keyboardActive = true;
  }

  calResult(): number {
    const a = parseFloat(this.firstNum) || 0;
    const b = parseFloat(this.secondNum) || 0;
    if (this.op === '+') return a + b;
    if (this.op === '-') return a - b;
    return parseFloat(this.secondNum) || parseFloat(this.firstNum) || 0;
  }

  onKeyboardConfirm(): void {
    const amt = Math.abs(this.calResult()) || 1;
    const catId = this.selectedCategoryId || 1;
    const rd = this.selectedDate;
    const recordDate = new Date(rd.getFullYear(), rd.getMonth(), rd.getDate(),
      new Date().getHours(), new Date().getMinutes(), 0, 0).getTime();
    if (this.editRecord) {
      this.db.updateRecord(this.editRecord.id, this.recordType, catId, amt, this.note.trim(), recordDate)
        .then(() => {
          if (this.onRecordAdded) this.onRecordAdded();
          this.showPanel = false;
        });
    } else {
      this.db.addRecord(this.recordType, catId, amt, this.note.trim(), recordDate)
        .then(() => {
          if (this.onRecordAdded) this.onRecordAdded();
          this.showPanel = false;
          this.resetForm();
        });
    }
  }

  switchType(type: number): void {
    this.recordType = type; this.selectedCategoryId = 0;
    this.selectedCategoryName = ''; this.keyboardActive = false;
    this.amountStr = ''; this.loadCategories();
  }

  showDatePicker(): void {
    try {
      DatePickerDialog.show({
        start: new Date('2000-1-1'), end: new Date('2099-12-31'),
        selected: this.selectedDate,
        onAccept: (value: DatePickerResult) => {
          if (value.month !== undefined) {
            this.selectedDate = new Date(value.year, value.month, value.day ?? 1);
            this.dateStr = `${value.month + 1}月${value.day ?? 1}日`;
          }
        }
      });
    } catch (_e) { }
  }

  typeColor(): string {
    return this.recordType === RECORD_TYPE_EXPENSE
      ? this.colors.expenseColor : this.colors.incomeColor;
  }

  build() {
    if (this.showPanel) {
      Column() {
        this.TopBar()
        if (!this.keyboardActive) { this.CategoryGridFull() }
        else { this.AmountArea() }
        if (this.keyboardActive) { this.KeyboardArea() }
        else {
          Row()
            .width('100%').height(60)
            .backgroundColor(this.colors.bgCard)
            .justifyContent(FlexAlign.Center)
            .border({ width: { top: 0.5 }, color: this.colors.divider })
        }
      }
      .width('100%').height('100%')
      .padding({ top: 42 })
      .backgroundColor(this.colors.bgPage)
    }
  }

  @Builder TopBar() {
    Row() {
      Button('支出')
        .fontSize(15).fontWeight(this.recordType === RECORD_TYPE_EXPENSE ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.recordType === RECORD_TYPE_EXPENSE ? Color.White : this.colors.textSecondary)
        .backgroundColor(this.recordType === RECORD_TYPE_EXPENSE ? this.colors.expenseColor : Color.Transparent)
        .borderRadius(20).height(36).padding({ left: 24, right: 24 })
        .onClick(() => this.switchType(RECORD_TYPE_EXPENSE))
      Button('收入')
        .fontSize(15).fontWeight(this.recordType === RECORD_TYPE_INCOME ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.recordType === RECORD_TYPE_INCOME ? Color.White : this.colors.textSecondary)
        .backgroundColor(this.recordType === RECORD_TYPE_INCOME ? this.colors.incomeColor : Color.Transparent)
        .borderRadius(20).height(36).padding({ left: 24, right: 24 })
        .margin({ left: 12 })
        .onClick(() => this.switchType(RECORD_TYPE_INCOME))
      Blank()
      Button() {
        Text('✕').fontSize(18).fontColor(this.colors.textSecondary)
      }
      .width(36).height(36).backgroundColor(this.colors.bgInput).borderRadius(18)
      .onClick(() => { this.showPanel = false; this.resetForm(); })
    }
    .width('100%').padding({ left: 20, right: 16, top: 16, bottom: 12 })
  }

  @Builder CategoryGridFull() {
    Scroll() {
      Grid() {
        ForEach(this.parentCategories, (cat: Category) => {
          GridItem() {
            Column() {
              Column() {
                Text(getCategoryEmoji(cat.icon)).fontSize(26)
              }
              .width(56).height(56).borderRadius(28)
              .backgroundColor(this.isDark ? '#3A3A3A' : '#E0E0E0')
              .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
              Text(cat.name).fontSize(12).fontColor(this.colors.textSecondary).margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Center).padding({ top: 8, bottom: 8 })
            .onClick(() => this.selectCategory(cat))
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .columnsGap(4).rowsGap(4)
      .width('100%').padding({ left: 12, right: 12 })
    }
    .layoutWeight(1).scrollBar(BarState.Off)
  }

  @Builder AmountArea() {
    Column() {
      Row() {
        Row() {
          Text(getCategoryEmoji(this.selectedCategoryIcon)).fontSize(18)
          Text(this.selectedCategoryName).fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor(this.colors.textPrimary).margin({ left: 8 })
          Text('▾').fontSize(12).fontColor(this.colors.textHint).margin({ left: 4 })
        }
        .onClick(() => { this.keyboardActive = false; this.firstNum = ''; this.secondNum = ''; this.op = ''; this.displayStr = ''; })
        Blank()
        Row({ space: 8 }) {
          Button() {
            Text('✎').fontSize(14).fontColor(this.note ? this.typeColor() : this.colors.textHint)
          }
          .width(30).height(30).backgroundColor(this.note ? this.typeColor() + '18' : this.colors.bgInput)
          .borderRadius(15).onClick(() => { this.showNoteField = !this.showNoteField; })
          Button() {
            Row() {
              Text('📅').fontSize(13).fontColor(this.colors.textSecondary)
              Text(this.dateStr).fontSize(11).fontColor(this.colors.textSecondary).margin({ left: 2 })
            }
          }
          .height(30).backgroundColor(this.colors.bgInput).borderRadius(15)
          .padding({ left: 8, right: 8 }).onClick(() => this.showDatePicker())
        }
      }
      .width('100%').padding({ left: 20, right: 16, top: 8, bottom: 4 })

      Column() {
        Text(this.displayStr || '0.00')
          .fontSize(this.displayStr ? 42 : 36).fontWeight(FontWeight.Bold)
          .fontColor(this.displayStr ? this.typeColor() : this.colors.textHint)
          .fontFamily('monospace')
      }
      .width('100%').height(65).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)

      if (this.showNoteField || this.note) {
        Row() {
          Text('✎').fontSize(13).fontColor(this.colors.textHint).margin({ right: 6 })
          TextInput({ text: this.note, placeholder: '添加备注…' })
            .fontSize(14).placeholderColor(this.colors.textHint)
            .backgroundColor(Color.Transparent).height(32).layoutWeight(1)
            .onChange((value: string) => { this.note = value; })
        }
        .width('100%').padding({ left: 20, right: 20, top: 4, bottom: 4 })
      }

    }
    .width('100%').layoutWeight(1)
  }

  @Builder KeyboardArea() {
    Column() {
      Grid() {
        GridItem() { this.K('7') }
        GridItem() { this.K('8') }
        GridItem() { this.K('9') }
        GridItem() { this.KBtn() }

        GridItem() { this.K('4') }
        GridItem() { this.K('5') }
        GridItem() { this.K('6') }
        GridItem() { this.K('+') }

        GridItem() { this.K('1') }
        GridItem() { this.K('2') }
        GridItem() { this.K('3') }
        GridItem() { this.K('-') }

        GridItem() { this.K('.') }
        GridItem() { this.K('0') }
        GridItem() { this.K('⌫') }
        GridItem() { this.KConfirm() }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(4).rowsGap(4)
      .width('100%').height(260)
      .backgroundColor(this.colors.divider)
      .padding({ left: 16, right: 16 })
    }
    .width('100%').backgroundColor(this.colors.bgCard).padding({ bottom: 15 })
  }

  @Builder K(label: string) {
    Button(label)
      .fontSize(label === '⌫' ? 20 : 22)
      .fontColor(label === '⌫' ? this.colors.textSecondary : this.colors.textPrimary)
      .backgroundColor(this.colors.bgCard).borderRadius(0)
      .width('100%').height('100%').padding(6)
      .onClick(() => this.onKey(label))
  }

  @Builder KBtn() {
    Button() {
      Text('📅').fontSize(18).fontColor(this.colors.textHint)
    }
    .backgroundColor(this.colors.bgCard).borderRadius(0)
    .width('100%').height('100%')
    .onClick(() => this.showDatePicker())
  }

  @Builder KConfirm() {
    Button('完成')
      .fontSize(15).fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .backgroundColor(this.typeColor()).borderRadius(0)
      .width('100%').height('100%')
      .onClick(() => { this.onKeyboardConfirm(); })
  }

  onKey(key: string): void {
    if (key === '⌫') {
      if (this.secondNum) {
        this.secondNum = this.secondNum.slice(0, -1);
        this.displayStr = this.firstNum + this.op + this.secondNum;
      } else if (this.op) {
        this.op = '';
        this.displayStr = this.firstNum;
      } else if (this.firstNum) {
        this.firstNum = this.firstNum.slice(0, -1);
        this.displayStr = this.firstNum;
      }
      return;
    }
    if (key === '.') {
      const cur = this.op ? this.secondNum : this.firstNum;
      if (cur.includes('.')) return;
      if (this.op) {
        this.secondNum = cur ? cur + '.' : '0.';
      } else {
        this.firstNum = cur ? cur + '.' : '0.';
      }
      this.displayStr = this.firstNum + this.op + this.secondNum;
      return;
    }
    if (key === '+' || key === '-') {
      if (this.firstNum && this.secondNum && this.op) {
        // 链式计算
        this.firstNum = this.calResult().toString();
        this.secondNum = '';
      }
      if (!this.firstNum) return;
      this.op = key;
      this.displayStr = this.firstNum + this.op;
      return;
    }
    // 数字键
    const cur = this.op ? this.secondNum : this.firstNum;
    if (cur === '0') return;
    if (cur.includes('.') && cur.split('.')[1].length >= 2) return;
    if (cur.replace('.', '').length >= 9) return;
    if (this.op) {
      this.secondNum = this.secondNum + key;
    } else {
      this.firstNum = this.firstNum + key;
    }
    this.displayStr = this.firstNum + this.op + this.secondNum;
  }
}
