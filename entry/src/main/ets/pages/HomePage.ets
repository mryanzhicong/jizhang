import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { DayGroup, MonthStats, RecordDisplay, getMonthLabel, formatAmount }
  from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { TransactionItem } from '../components/TransactionItem';
import { SearchPage } from './SearchPage';
import { AddRecordPanel } from '../components/AddRecordPanel';

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
            Text('      ').fontSize(18)  // 左侧占位，保持居中
            Text(getMonthLabel(this.y, this.m) + ' ▾').fontSize(17).fontWeight(FontWeight.Bold)
              .fontColor(this.col.textPrimary).layoutWeight(1).textAlign(TextAlign.Center)
              .onClick(() => this.showMonthPicker())
            Text('搜索').fontSize(14).fontColor(this.col.textHint)
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
                    onEdit: (record: RecordDisplay) => this.editRecord(record) })
                })
              }
            }.width('100%').margin({ bottom: 4 })
          })
        }
        }.width('100%')
        }.scrollBar(BarState.Off).layoutWeight(1)
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

}
