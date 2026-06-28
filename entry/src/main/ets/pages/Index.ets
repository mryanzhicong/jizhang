import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { HomePage } from './HomePage';
import { StatisticsPage } from './StatisticsPage';
import { SettingsPage } from './SettingsPage';
import { AddRecordPanel } from '../components/AddRecordPanel';
import { CalendarPanel } from '../components/CalendarPanel';

@Entry
@Component
struct Index {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @State curTab: number = 0;
  @State showAddPanel: boolean = false;
  private c = getThemeColors();

  aboutToAppear(): void {
    AppStorage.setOrCreate<number>('refreshTrigger', 0);
    AppStorage.setOrCreate<number>('showCategories', 0);
    AppStorage.setOrCreate<number>('showMonthPicker', 0);
    AppStorage.setOrCreate<number>('showAmtKey', 0);
    AppStorage.setOrCreate<number>('showCatPicker', 0);
    AppStorage.setOrCreate<number>('showEditPanel', 0);
    AppStorage.setOrCreate<number>('showHomeSearch', 0);
    AppStorage.setOrCreate<number>('showCalMonthPicker', 0);
  }
  onBackPress(): boolean | void {
    if (this.showAddPanel) { this.showAddPanel = false; return true; }
    if (AppStorage.get<number>('showMonthPicker') === 1) {
      AppStorage.set<number>('showMonthPicker', 0); return true;
    }
    if (AppStorage.get<number>('showAmtKey') === 1) {
      AppStorage.set<number>('showAmtKey', 0); return true;
    }
    if (AppStorage.get<number>('showCatPicker') === 1) {
      AppStorage.set<number>('showCatPicker', 0); return true;
    }
    if (AppStorage.get<number>('showEditPanel') === 1) {
      AppStorage.set<number>('showEditPanel', 0); return true;
    }
    if (AppStorage.get<number>('showHomeSearch') === 1) {
      AppStorage.set<number>('showHomeSearch', 0); return true;
    }
    if (AppStorage.get<number>('showCalMonthPicker') === 1) {
      AppStorage.set<number>('showCalMonthPicker', 0); return true;
    }
    if (AppStorage.get<number>('showCategories') === 1) {
      AppStorage.set<number>('showCategories', 0); return true;
    }
    return false;
  }
  onSaved(): void {
    this.showAddPanel = false;
    AppStorage.set<number>('refreshTrigger', (AppStorage.get<number>('refreshTrigger') ?? 0) + 1);
  }

  @Builder PageContent() {
    if (this.curTab === 0) { HomePage() }
    else if (this.curTab === 1) {
      Column() {
        CalendarPanel({ initYear: new Date().getFullYear(), initMonth: new Date().getMonth() })
      }.width('100%').height('100%')
    }
    else if (this.curTab === 2) { StatisticsPage() }
    else { SettingsPage() }
  }

  build() {
    Stack() {
      Column() {
        Column() {
          this.PageContent()
        }.width('100%').layoutWeight(1).padding({ top: 42 })

        Row() {
          this.Nav(0, '🏠', '明细')
          this.Nav(1, '📅', '日历')
          Column().width(56).height(56)
          this.Nav(2, '📊', '统计')
          this.Nav(3, '⚙', '设置')
        }.width('100%').height(76)
        .backgroundColor(this.c.tabBarBg)
        .justifyContent(FlexAlign.SpaceAround).alignItems(VerticalAlign.Center)
      }
      .width('100%').height('100%')

      Column() {
        Column() {
          Text('＋').fontSize(28).fontColor(Color.White)
        }.width(56).height(56).borderRadius(28)
        .backgroundColor(this.c.primary)
        .shadow({ radius: 8, color: '#4A90D960', offsetX: 0, offsetY: 4 })
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .margin({ bottom: 4 })
        Text('记账').fontSize(10).fontColor(this.c.textHint)
      }
      .position({ x: '50%', y: '100%' }).translate({ x: -28, y: -87 })
      .alignItems(HorizontalAlign.Center)
      .onClick(() => { this.showAddPanel = true; })

      if (this.showAddPanel) {
        AddRecordPanel({ showPanel: this.showAddPanel, onRecordAdded: () => this.onSaved() })
      }
    }
    .width('100%').height('100%').backgroundColor(this.c.bgPage)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  @Builder Nav(idx: number, icon: string, title: string) {
    Column() {
      Text(icon).fontSize(26).fontColor(this.curTab === idx ? this.c.primary : this.c.textHint)
      Text(title).fontSize(10).fontColor(this.curTab === idx ? this.c.primary : this.c.textHint).margin({ top: 2 })
    }.onClick(() => { this.curTab = idx; })
  }
}
