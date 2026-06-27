/**
 * 分类网格选择器 - 支持二级分类
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { Category } from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { getCategoryEmoji } from '../common/IconHelper';

@Component
export struct CategoryGrid {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;
  @Link selectedCategoryId: number;
  @Prop recordType: number;
  onCategorySelected?: () => void;
  @State parentCategories: Category[] = [];
  @State childCategories: Category[] = [];
  @State selectedParentId: number = 0;
  @State showChildLevel: boolean = false;

  private db: DatabaseHelper = DatabaseHelper.getInstance();
  private colors: ThemeColors = getThemeColors();

  aboutToAppear(): void { this.loadParents(); }

  async loadParents(): Promise<void> {
    this.parentCategories = await this.db.getParentCategories(this.recordType);
    if (this.parentCategories.length > 0) {
      this.selectedParentId = this.parentCategories[0].id;
      await this.loadChildren();
    }
  }

  async loadChildren(): Promise<void> {
    if (this.selectedParentId > 0)
      this.childCategories = await this.db.getChildCategories(this.selectedParentId);
  }

  async selectParent(parentId: number): Promise<void> {
    this.selectedParentId = parentId;
    this.showChildLevel = true;
    await this.loadChildren();
  }

  selectChild(catId: number): void {
    this.selectedCategoryId = catId;
    if (this.onCategorySelected) this.onCategorySelected();
  }

  build() {
    Column() {
      if (!this.showChildLevel) {
        this.GridView(this.parentCategories, (cat: Category) => { this.selectParent(cat.id); }, false)
      } else {
        Column() {
          Row() {
            Button() {
              Text('‹')
                .fontSize(22).fontColor(this.colors.textPrimary)
            }
            .width(36).height(36).backgroundColor(Color.Transparent)
            .onClick(() => { this.showChildLevel = false; })
            Text(this.getParentName())
              .fontSize(17).fontWeight(FontWeight.Medium)
              .fontColor(this.colors.textPrimary).margin({ left: 8 })
            Blank()
          }
          .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 12 })
          this.GridView(this.childCategories, (cat: Category) => {
            this.selectChild(cat.id);
          }, true)
        }
      }
    }.width('100%')
  }

  @Builder
  GridView(cats: Category[], onTap: (cat: Category) => void, showSelected: boolean) {
    Grid() {
      ForEach(cats, (cat: Category) => {
        GridItem() {
          this.CatItem(cat, onTap, showSelected && cat.id === this.selectedCategoryId)
        }
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
    .columnsGap(4).rowsGap(12)
    .width('100%').padding({ left: 12, right: 12 })
  }

  @Builder
  CatItem(cat: Category, onTap: (c: Category) => void, isSel: boolean) {
    Column() {
      Column() {
        Text(getCategoryEmoji(cat.icon)).fontSize(24)
      }
      .width(48).height(48).borderRadius(24)
      .backgroundColor(isSel ? this.getCatColor() : this.getCatColor() + '18')
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      Text(cat.name)
        .fontSize(11).fontColor(this.colors.textSecondary)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Center)
    .onClick(() => onTap(cat))
  }

  getParentName(): string {
    const f = this.parentCategories.find(c => c.id === this.selectedParentId);
    return f ? f.name : '';
  }

  getCatColor(): string {
    return this.recordType === 0 ? this.colors.expenseColor : this.colors.incomeColor;
  }
}
