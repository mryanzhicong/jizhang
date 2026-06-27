import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { HomePage } from './HomePage';
import { StatisticsPage } from './StatisticsPage';
import { CategoriesPage } from './CategoriesPage';
import { SettingsPage } from './SettingsPage';
import { AddRecordPanel } from '../components/AddRecordPanel';

@Entry
@Component
struct Index {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @State curTab: number = 0;
  @State showAddPanel: boolean = false;
  private c = getThemeColors();

  aboutToAppear(): void { AppStorage.setOrCreate<number>('refreshTrigger', 0); }
  onSaved(): void {
    this.showAddPanel = false;
    AppStorage.set<number>('refreshTrigger', (AppStorage.get<number>('refreshTrigger') ?? 0) + 1);
  }

  build() {
    Stack() {
      Column() {
        Column() {
          if (this.curTab === 0) { HomePage() }
          else if (this.curTab === 1) { StatisticsPage() }
          else if (this.curTab === 2) { CategoriesPage() }
          else { SettingsPage() }
        }.width('100%').layoutWeight(1).padding({ top: 42 })

        Row() {
          this.Nav(0, '🏠', '首页')
          this.Nav(1, '📊', '统计')
          Column().width(56).height(56)
          this.Nav(2, '📂', '分类')
          this.Nav(3, '⚙', '设置')
        }.width('100%').height(56)
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
        Text('记账').fontSize(10).fontColor(this.c.textSecondary)
      }
      .position({ x: '50%', y: '100%' }).translate({ x: -28, y: -80 })
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
      Text(icon).fontSize(22).fontColor(this.curTab === idx ? this.c.primary : this.c.textHint)
      Text(title).fontSize(10).fontColor(this.curTab === idx ? this.c.primary : this.c.textHint).margin({ top: 2 })
    }.onClick(() => { this.curTab = idx; })
  }
}
