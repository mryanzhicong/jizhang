import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { DayGroup, MonthStats, RecordDisplay, Category, getMonthLabel, formatAmount }
  from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { TransactionItem } from '../components/TransactionItem';
import { SearchPage } from './SearchPage';
import { AddRecordPanel } from '../components/AddRecordPanel';
import { getCategoryEmoji } from '../common/IconHelper';

@Component
export struct HomePage {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @StorageLink('refreshTrigger') @Watch('onRefresh') refresh: number = 0;
  @StorageLink('showMonthPicker') @Watch('onPickerLink') showPickerLink: number = 0;
  @State groups: DayGroup[] = [];
  @State stats: MonthStats =
    { totalIncome: 0, totalExpense: 0, balance: 0 };
  @State y: number = new Date().getFullYear();
  @State m: number = new Date().getMonth();
  @State showPicker: boolean = false;
  @State pickYear: number = new Date().getFullYear();
  @StorageLink('showHomeSearch') @Watch('onSearchLink') showHomeSearch: number = 0;
  @StorageLink('showEditPanel') @Watch('onEditLink') showEditLink: number = 0;
  @StorageLink('showCatPicker') @Watch('onCatLink') showCatLink: number = 0;
  @StorageLink('showAmtKey') @Watch('onAmtLink') showAmtLink: number = 0;
  @State showSearch: boolean = false;
  @State editingRecord: RecordDisplay | null = null;
  @State showEditPanel: boolean = false;
  @State editPanelKey: number = 0;

  onSearchLink(): void {
    if (this.showHomeSearch === 0) this.showSearch = false;
  }
  onEditLink(): void {
    if (this.showEditLink === 0) this.showEditPanel = false;
  }
  onCatLink(): void {
    if (this.showCatLink === 0) this.catPickRec = null;
  }
  onAmtLink(): void {
    if (this.showAmtLink === 0) this.amtRec = null;
  }

  onPickerLink(): void {
    if (this.showPickerLink === 0) this.showPicker = false;
  }
  db = DatabaseHelper.getInstance();
  col = getThemeColors();

  aboutToAppear(): void { this.load(); }
  onRefresh(): void { this.load(); }
  async load(): Promise<void> {
    try {
      this.stats = await this.db.getMonthStats(this.y, this.m);
      this.groups = await this.db.getRecordsGroupedByDay(this.y, this.m);
    } catch (_e) { }
  }
  async del(id: number): Promise<void> { await this.db.deleteRecord(id); this.load(); }

  // --- 快速编辑备注 ---
  @State noteEditRec: RecordDisplay | null = null;
  @State noteEditText: string = '';
  openNoteEdit(r: RecordDisplay): void { this.noteEditRec = r; this.noteEditText = r.note; }
  async saveNote(): Promise<void> {
    if (this.noteEditRec) { await this.db.updateRecord(this.noteEditRec.id,
      this.noteEditRec.type, this.noteEditRec.categoryId, this.noteEditRec.amount,
      this.noteEditText.trim(), this.noteEditRec.date); this.noteEditRec = null; this.load(); }
  }

  // --- 快速修改分类 ---
  @State catPickRec: RecordDisplay | null = null;
  @State catPickList: Category[] = [];
  openCatPick(r: RecordDisplay): void {
    this.catPickRec = r;
    this.catPickList = [];
    this.db.getParentCategories(r.type).then((cats: Category[]) => { this.catPickList = cats; });
    AppStorage.set<number>('showCatPicker', 1);
  }
  async pickCat(cat: Category): Promise<void> {
    if (this.catPickRec) {
      await this.db.updateRecord(this.catPickRec.id, this.catPickRec.type,
        cat.id, this.catPickRec.amount, this.catPickRec.note, this.catPickRec.date);
      this.catPickRec = null; AppStorage.set<number>('showCatPicker', 0); this.load();
    }
  }

  // --- 快速编辑金额（纯键盘+计算器）---
  @State amtRec: RecordDisplay | null = null;
  @State amtFirst: string = ''; @State amtSecond: string = ''; @State amtOp: string = '';
  @State amtDisp: string = '';
  openAmtEdit(r: RecordDisplay): void {
    this.amtRec = r; this.amtFirst = ''; this.amtSecond = ''; this.amtOp = ''; this.amtDisp = '';
    AppStorage.set<number>('showAmtKey', 1);
  }
  amtResult(): number { const a=parseFloat(this.amtFirst)||0; const b=parseFloat(this.amtSecond)||0;
    return this.amtOp==='+'?a+b:this.amtOp==='-'?a-b:parseFloat(this.amtSecond)||parseFloat(this.amtFirst)||0; }
  amtTypeColor(): string { return this.amtRec && this.amtRec.type === 0 ? this.col.expenseColor : this.col.incomeColor; }
  async saveAmt(): Promise<void> {
    if (this.amtRec) { const a = Math.abs(this.amtResult()) || 1;
      const d = this.amtRec.date; // 可能已被 DateBtn 修改
      await this.db.updateRecord(this.amtRec.id, this.amtRec.type, this.amtRec.categoryId,
        a, this.amtRec.note, d); this.amtRec = null; AppStorage.set<number>('showAmtKey', 0); this.load(); }
  }
  amtKey(key: string): void {
    if (key === '⌫') {
      if (this.amtSecond) { this.amtSecond=this.amtSecond.slice(0,-1); this.amtDisp=this.amtFirst+this.amtOp+this.amtSecond; }
      else if (this.amtOp) { this.amtOp=''; this.amtDisp=this.amtFirst; }
      else if (this.amtFirst) { this.amtFirst=this.amtFirst.slice(0,-1); this.amtDisp=this.amtFirst; }
      return;
    }
    if (key === '.') { const cur=this.amtOp?this.amtSecond:this.amtFirst;
      if (cur.includes('.')) return; if (this.amtOp) { this.amtSecond=cur?cur+'.':'0.'; }
      else { this.amtFirst=cur?cur+'.':'0.'; } this.amtDisp=this.amtFirst+this.amtOp+this.amtSecond; return; }
    if (key === '+' || key === '-') {
      if (this.amtFirst && this.amtSecond && this.amtOp) { this.amtFirst=this.amtResult().toString(); this.amtSecond=''; }
      if (!this.amtFirst) return; this.amtOp=key; this.amtDisp=this.amtFirst+this.amtOp; return;
    }
    const cur2=this.amtOp?this.amtSecond:this.amtFirst;
    if (cur2==='0') return; if (cur2.includes('.')&&cur2.split('.')[1].length>=2) return;
    if (cur2.replace('.','').length>=9) return;
    if (this.amtOp) { this.amtSecond=this.amtSecond+key; } else { this.amtFirst=this.amtFirst+key; }
    this.amtDisp=this.amtFirst+this.amtOp+this.amtSecond;
  }

  showMonthPicker(): void {
    this.pickYear = this.y;
    this.showPicker = true;
    AppStorage.set<number>('showMonthPicker', 1);
  }
  closeMonthPicker(): void {
    this.showPicker = false;
    AppStorage.set<number>('showMonthPicker', 0);
  }
  selectMonth(mon: number): void {
    this.y = this.pickYear;
    this.m = mon;
    this.closeMonthPicker();
    this.load();
  }

  openSearch(): void {
    this.showSearch = true;
    AppStorage.set<number>('showHomeSearch', 1);
  }
  closeSearch(): void {
    this.showSearch = false;
    AppStorage.set<number>('showHomeSearch', 0);
  }

  editRecord(r: RecordDisplay): void {
    this.editingRecord = r;
    this.showEditPanel = true;
    AppStorage.set<number>('showEditPanel', 1);
  }
  onEditSaved(): void {
    this.showEditPanel = false;
    AppStorage.set<number>('showEditPanel', 0);
    this.load();
  }

  build() {
    Stack() {
      Column() {
        // 月份卡片
        Column() {
          Row() {
            Text('     ').fontSize(18)  // 左侧占位，保持居中
            Text(getMonthLabel(this.y, this.m) + ' ▾').fontSize(17).fontWeight(FontWeight.Bold)
              .fontColor(this.col.textPrimary).layoutWeight(1).textAlign(TextAlign.Center)
              .onClick(() => this.showMonthPicker())
            Text('🔍').fontSize(18)
              .onClick(() => this.openSearch())
          }.width('100%').margin({ bottom: 20 })
          Row() {
            Column() {
              Text('支出').fontSize(13).fontColor(this.col.textSecondary).margin({ bottom: 10 })
              Text(formatAmount(this.stats.totalExpense)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.col.expenseColor).fontFamily('monospace')
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
            Column().width(0.5).height(36).backgroundColor(this.col.divider)
            Column() {
              Text('收入').fontSize(13).fontColor(this.col.textSecondary).margin({ bottom: 10 })
              Text(formatAmount(this.stats.totalIncome)).fontSize(28).fontWeight(FontWeight.Bold)
                .fontColor(this.col.incomeColor).fontFamily('monospace')
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.layoutWeight(1).alignItems(HorizontalAlign.Center)
          }.width('100%')
        }
        .width('100%').padding(20).backgroundColor(this.col.bgCard).borderRadius(16)
        .margin({ left: 16, right: 16, top: 12, bottom: 12 })

        // 记录（可滚动）
        Scroll() {
        Column() {
        if (this.groups.length === 0) {
          Column() {
            Text('📄').fontSize(44).fontColor(this.col.textHint).margin({ top: 40, bottom: 10 })
            Text('还没有记录').fontSize(15).fontColor(this.col.textSecondary)
            Text('点击 ＋ 开始记账').fontSize(12).fontColor(this.col.textHint).margin({ top: 4 })
          }.width('100%')
        } else {
          ForEach(this.groups, (g: DayGroup) => {
            Column() {
              Row() {
                Text(g.dateLabel).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.col.textPrimary)
                Blank()
                if (g.dayExpense > 0) {
                  Text(`-${formatAmount(g.dayExpense)}`).fontSize(13)
                    .fontColor(this.col.expenseColor).fontFamily('monospace')
                }
                if (g.dayExpense > 0 && g.dayIncome > 0) { Text('  ').fontSize(13) }
                if (g.dayIncome > 0) {
                  Text(`+${formatAmount(g.dayIncome)}`).fontSize(13)
                    .fontColor(this.col.incomeColor).fontFamily('monospace')
                }
              }.width('100%').padding({ left: 20, right: 16, top: 18, bottom: 10 })
              Column({ space: 2 }) {
                ForEach(g.records, (r: RecordDisplay) => {
                  TransactionItem({ record: r,
                    onDelete: (id: number) => this.del(id),
                    onEdit: (record: RecordDisplay) => this.editRecord(record),
                    onChangeCategory: (record: RecordDisplay) => this.openCatPick(record),
                    onEditNote: (record: RecordDisplay) => this.openNoteEdit(record),
                    onEditAmount: (record: RecordDisplay) => this.openAmtEdit(record) })
                })
              }
            }.width('100%').margin({ bottom: 4 })
          })
        }
        }.width('100%')
        }.scrollBar(BarState.Off)
      }
    .width('100%').height('100%').backgroundColor(this.col.bgPage)

      // 搜索页
      if (this.showSearch) {
        SearchPage({ onClose: () => { this.closeSearch(); },
          onDelete: () => { this.load(); } })
      }

      // 编辑面板
      if (this.showEditPanel && this.editingRecord) {
        AddRecordPanel({ showPanel: this.showEditPanel,
          editRecord: this.editingRecord,
          onRecordAdded: () => { this.onEditSaved(); } })
      }

      // 分类选择弹窗
      if (this.catPickRec) {
        Column() {
          Row() {
            Text('‹ 选择分类').fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.col.textPrimary)
              .onClick(() => { this.catPickRec = null; AppStorage.set<number>('showCatPicker', 0); })
            Blank()
          }.width('100%').padding({ left: 16, right: 16, top: 12, bottom: 8 })
          Grid() {
            ForEach(this.catPickList, (cat: Category) => {
              GridItem() {
                Column() {
                  Column() {
                    Text(getCategoryEmoji(cat.icon)).fontSize(26)
                  }.width(52).height(52).borderRadius(26)
                  .backgroundColor(cat.id === this.catPickRec!.categoryId ? this.col.primaryLight : this.col.bgInput)
                  .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
                  Text(cat.name).fontSize(11).fontColor(this.col.textSecondary).margin({ top: 4 })
                }.alignItems(HorizontalAlign.Center).onClick(() => { this.pickCat(cat); })
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr').columnsGap(4).rowsGap(12).width('100%').padding({ left: 12, right: 12 })
        }
        .width('100%').height('100%').backgroundColor(this.col.bgPage).padding({ top: 42 })
      }

      // 备注弹窗
      if (this.noteEditRec) {
        Stack({ alignContent: Alignment.Center }) {
          Column().width('100%').height('100%').backgroundColor(this.col.overlay)
            .onClick(() => { this.noteEditRec = null; })
          Column() {
            Text('修改备注').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.col.textPrimary).margin({ bottom: 16 })
            TextInput({ text: this.noteEditText, placeholder: '备注...' })
              .fontSize(15).backgroundColor(this.col.bgInput).borderRadius(12).width('100%')
              .onChange((v: string) => { this.noteEditText = v; })
            Row({ space: 12 }) {
              Button('取消').layoutWeight(1).height(40).fontColor(this.col.textPrimary)
                .backgroundColor(this.col.bgInput).borderRadius(20)
                .onClick(() => { this.noteEditRec = null; })
              Button('保存').layoutWeight(1).height(40).fontColor(Color.White)
                .backgroundColor(this.col.primary).borderRadius(20)
                .onClick(() => { this.saveNote(); })
            }.width('100%').margin({ top: 20 })
          }.width('80%').padding(24).backgroundColor(this.col.bgCard).borderRadius(20).offset({ y: -100 })
        }.width('100%').height('100%').zIndex(200)
      }

      // 金额键盘弹窗
      if (this.amtRec) {
        Column() {
          Column() {
            Text(this.amtDisp || '0.00').fontSize(this.amtDisp ? 42 : 36).fontWeight(FontWeight.Bold)
              .fontColor(this.amtDisp ? this.amtTypeColor() : this.col.textHint).fontFamily('monospace')
          }.width('100%').height(70).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          Grid() {
            GridItem() { this.Kb('7') }; GridItem() { this.Kb('8') }; GridItem() { this.Kb('9') };
            GridItem() { this.DateBtn() }
            GridItem() { this.Kb('4') }; GridItem() { this.Kb('5') }; GridItem() { this.Kb('6') };
            GridItem() { Button('+').fontSize(22).fontColor(this.col.textSecondary).backgroundColor(this.col.bgCard)
              .borderRadius(0).width('100%').height('100%').padding(4).onClick(()=>{this.amtKey('+')}) }
            GridItem() { this.Kb('1') }; GridItem() { this.Kb('2') }; GridItem() { this.Kb('3') };
            GridItem() { Button('-').fontSize(22).fontColor(this.col.textSecondary).backgroundColor(this.col.bgCard)
              .borderRadius(0).width('100%').height('100%').padding(4).onClick(()=>{this.amtKey('-')}) }
            GridItem() { this.Kb('.') }; GridItem() { this.Kb('0') }; GridItem() { this.Kb('⌫') };
            GridItem() { Button('完成').fontSize(15).fontWeight(FontWeight.Bold).fontColor(Color.White)
              .backgroundColor(this.amtTypeColor()).borderRadius(0).width('100%').height('100%').padding(4)
              .onClick(()=>{this.saveAmt()}) }
          }.columnsTemplate('1fr 1fr 1fr 1fr').rowsTemplate('1fr 1fr 1fr 1fr')
          .columnsGap(4).rowsGap(4).width('100%').height(260).padding({ left: 16, right: 16 }).backgroundColor(this.col.divider)
        }.width('100%').backgroundColor(this.col.bgCard)
        .position({ x: 0, y: '100%' }).translate({ y: -350 })

        // 底部白色填充
        Column().width('100%').height(20).backgroundColor(this.col.bgCard)
        .position({ x: 0, y: '100%' }).translate({ y: -20 })
      }

      // 白色延伸条：填充卡片上方到状态栏之间的区域
      Column()
        .width('100%').height(60)
        .backgroundColor(this.col.bgCard)
        .position({ x: 0, y: -48 })

      // 月份选择器（全屏）
      if (this.showPicker) {
        Column() {
          Row() {
            Button('‹').fontSize(20).fontColor(this.col.textSecondary)
              .width(40).height(40).backgroundColor(Color.Transparent)
              .onClick(() => { this.pickYear--; })
            Text(this.pickYear.toString()).fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(this.col.textPrimary).layoutWeight(1).textAlign(TextAlign.Center)
            Button('›').fontSize(20).fontColor(this.col.textSecondary)
              .width(40).height(40).backgroundColor(Color.Transparent)
              .onClick(() => { this.pickYear++; })
          }.width('100%').padding({ left: 20, right: 20, top: 20 })

          Grid() {
            ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], (mon: number) => {
              GridItem() {
                Column() {
                  Text((mon + 1) + '月')
                    .fontSize(16)
                    .fontWeight(this.pickYear === this.y && mon === this.m ? FontWeight.Bold : FontWeight.Normal)
                    .fontColor(this.pickYear === this.y && mon === this.m ? this.col.primary : this.col.textPrimary)
                }
                .width('100%').height(52).justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center).borderRadius(10)
                .backgroundColor(this.pickYear === this.y && mon === this.m ? this.col.primaryLight : this.col.bgInput)
                .onClick(() => this.selectMonth(mon))
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .rowsGap(8).columnsGap(8)
          .width('100%').padding({ left: 24, right: 24, top: 12 })
        }
        .width('100%').layoutWeight(1)
        .backgroundColor(this.col.bgPage)
      }
    }
    .width('100%').height('100%').clip(false)
  }

  @Builder DateBtn() {
    Button() { Text('📅').fontSize(18).fontColor(this.col.textHint) }
      .backgroundColor(this.col.bgCard).borderRadius(0).width('100%').height('100%').padding(4)
      .onClick(() => {
        const rec = this.amtRec;
        if (rec) {
          DatePickerDialog.show({ start: new Date('2000-1-1'), end: new Date('2099-12-31'),
            selected: new Date(rec.date),
            onAccept: (v: DatePickerResult) => {
              if (v.month !== undefined) { rec.date = new Date(v.year, v.month, v.day ?? 1).getTime(); }
            }
          });
        }
      })
  }

  @Builder Kb(label: string) {
    Button(label).fontSize(label === '⌫' ? 20 : 22)
      .fontColor(label === '⌫' ? this.col.textSecondary : this.col.textPrimary)
      .backgroundColor(this.col.bgCard).borderRadius(0).width('100%').height('100%').padding(4)
      .onClick(() => { this.amtKey(label); })
  }
}
