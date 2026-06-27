/**
 * 分类管理页面 - 查看/新增/编辑/删除分类
 */
import { IS_DARK_KEY, getThemeColors, ThemeColors } from '../common/ThemeManager';
import { Category, RECORD_TYPE_EXPENSE, RECORD_TYPE_INCOME } from '../models/FinanceModels';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { getCategoryEmoji } from '../common/IconHelper';

@Component
export struct CategoriesPage {
  @StorageLink(IS_DARK_KEY) isDark: boolean = false;

  @State selectedType: number = RECORD_TYPE_EXPENSE;
  @State parentCategories: Category[] = [];
  @State childCategories: Category[] = [];
  @State expandedParentId: number = 0;
  @State showAddDialog: boolean = false;
  @State showEditDialog: boolean = false;
  @State addingToParentId: number = 0;
  @State editingCat: Category | null = null;
  @State catName: string = '';
  @State addingType: number = RECORD_TYPE_EXPENSE;

  private db: DatabaseHelper = DatabaseHelper.getInstance();
  private colors: ThemeColors = getThemeColors();

  aboutToAppear(): void { this.loadCats(); }

  async loadCats(): Promise<void> {
    this.parentCategories = await this.db.getParentCategories(this.selectedType);
    if (this.expandedParentId > 0)
      this.childCategories = await this.db.getChildCategories(this.expandedParentId);
  }

  async toggleExpand(parentId: number): Promise<void> {
    if (this.expandedParentId === parentId) { this.expandedParentId = 0; this.childCategories = []; }
    else { this.expandedParentId = parentId; this.childCategories = await this.db.getChildCategories(parentId); }
  }

  async addCategory(): Promise<void> {
    if (!this.catName.trim()) return;
    const parentCat = this.parentCategories.find(c => c.id === this.addingToParentId);
    await this.db.addCategory(this.catName.trim(),
      parentCat ? parentCat.icon : 'more', this.addingType, this.addingToParentId);
    this.showAddDialog = false; this.catName = ''; this.loadCats();
  }

  async updateCategory(): Promise<void> {
    if (!this.editingCat || !this.catName.trim()) return;
    await this.db.updateCategory(this.editingCat.id, this.catName.trim(), this.editingCat.icon);
    this.showEditDialog = false; this.editingCat = null; this.catName = ''; this.loadCats();
  }

  async deleteCategory(cat: Category): Promise<void> {
    await this.db.deleteCategory(cat.id); this.loadCats();
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('分类管理').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.colors.textPrimary)
          Blank()
          Button('新增')
            .fontSize(14).fontColor(this.colors.primary)
            .backgroundColor(this.colors.primaryLight).borderRadius(16)
            .height(32).padding({ left: 14, right: 14 })
            .onClick(() => {
              this.catName = ''; this.addingToParentId = 0;
              this.addingType = this.selectedType; this.showAddDialog = true;
            })
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 8 })

        Row() {
          Button('支出分类')
            .fontSize(14)
            .fontWeight(this.selectedType === RECORD_TYPE_EXPENSE ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedType === RECORD_TYPE_EXPENSE ? Color.White : this.colors.textSecondary)
            .backgroundColor(this.selectedType === RECORD_TYPE_EXPENSE ? this.colors.expenseColor : Color.Transparent)
            .borderRadius(16).height(32).padding({ left: 20, right: 20 })
            .onClick(() => { this.selectedType = RECORD_TYPE_EXPENSE; this.expandedParentId = 0; this.loadCats(); })
          Button('收入分类')
            .fontSize(14)
            .fontWeight(this.selectedType === RECORD_TYPE_INCOME ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedType === RECORD_TYPE_INCOME ? Color.White : this.colors.textSecondary)
            .backgroundColor(this.selectedType === RECORD_TYPE_INCOME ? this.colors.incomeColor : Color.Transparent)
            .borderRadius(16).height(32).padding({ left: 20, right: 20 })
            .margin({ left: 12 })
            .onClick(() => { this.selectedType = RECORD_TYPE_INCOME; this.expandedParentId = 0; this.loadCats(); })
        }
        .width('100%').justifyContent(FlexAlign.Center).margin({ bottom: 12 })

        List({ space: 8 }) {
          ForEach(this.parentCategories, (cat: Category) => {
            ListItem() {
              Column() {
                Row() {
                  Text(getCategoryEmoji(cat.icon)).fontSize(20)
                  Text(cat.name)
                    .fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor(this.colors.textPrimary)
                    .layoutWeight(1).margin({ left: 10 })
                  Row({ space: 4 }) {
                    Button() {
                      Text('＋')
                        .fontSize(14).fontColor(this.colors.primary)
                    }
                    .width(28).height(28).backgroundColor(this.colors.primaryLight).borderRadius(14)
                    .onClick(() => {
                      this.addingToParentId = cat.id; this.addingType = this.selectedType;
                      this.catName = ''; this.showAddDialog = true;
                    })
                    if (!cat.isDefault) {
                      Button() {
                        Text('✎')
                          .fontSize(14).fontColor(this.colors.textSecondary)
                      }
                      .width(28).height(28).backgroundColor(this.colors.bgInput).borderRadius(14)
                      .onClick(() => { this.editingCat = cat; this.catName = cat.name; this.showEditDialog = true; })
                    }
                    Text(this.expandedParentId === cat.id ? '▴' : '▾')
                      .fontSize(18).fontColor(this.colors.textHint)
                  }
                }
                .width('100%').padding({ top: 14, bottom: 14 })
                .onClick(() => { this.toggleExpand(cat.id); })

                if (this.expandedParentId === cat.id) {
                  Column() {
                    ForEach(this.childCategories, (child: Category) => {
                      Row() {
                        Text('    ').fontSize(14).fontColor(this.colors.textHint)
                        Text(child.name)
                          .fontSize(14).fontColor(this.colors.textSecondary)
                          .layoutWeight(1)
                        if (!child.isDefault) {
                          Button() {
                            Text('✎')
                              .fontSize(13).fontColor(this.colors.textSecondary)
                          }
                          .width(26).height(26).backgroundColor(this.colors.bgInput).borderRadius(13)
                          .onClick(() => { this.editingCat = child; this.catName = child.name; this.showEditDialog = true; })
                          Button() {
                            Text('🗑')
                              .fontSize(13).fontColor(this.colors.expenseColor)
                          }
                          .width(26).height(26).backgroundColor(this.colors.bgInput).borderRadius(13)
                          .margin({ left: 4 })
                          .onClick(() => { this.deleteCategory(child); })
                        }
                      }
                      .width('100%').padding({ top: 8, bottom: 8 })
                    })
                  }
                  .width('100%').padding({ left: 12, bottom: 8 })
                  .backgroundColor(this.colors.bgInput).borderRadius(8)
                }
              }
              .width('100%').padding({ left: 16, right: 16 })
              .backgroundColor(this.colors.bgCard).borderRadius(12)
            }
          })
        }
        .width('100%').padding({ left: 16, right: 16 }).layoutWeight(1)
        Blank().height(80)
      }
      .width('100%').height('100%')

      if (this.showAddDialog || this.showEditDialog) {
        this.CatForm(
          this.showAddDialog ? '新增分类' : '编辑分类',
          () => { if (this.showAddDialog) this.addCategory(); else this.updateCategory(); },
          () => { this.showAddDialog = false; this.showEditDialog = false; }
        )
      }
    }
    .width('100%').height('100%').backgroundColor(this.colors.bgPage)
  }

  @Builder
  CatForm(title: string, onConfirm: () => void, onCancel: () => void) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%').height('100%')
        .backgroundColor(this.colors.overlay)
        .onClick(onCancel)
      Column() {
        Text(title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.colors.textPrimary).margin({ bottom: 16 })
        TextInput({ text: this.catName, placeholder: '分类名称' })
          .fontSize(15).backgroundColor(this.colors.bgInput).borderRadius(8).height(44).width('100%')
          .onChange((value: string) => { this.catName = value; })
        Row({ space: 12 }) {
          Button('取消')
            .layoutWeight(1).height(40)
            .fontColor(this.colors.textSecondary)
            .backgroundColor(this.colors.bgInput).borderRadius(20)
            .onClick(onCancel)
          Button('确定')
            .layoutWeight(1).height(40)
            .fontColor(Color.White)
            .backgroundColor(this.colors.primary).borderRadius(20)
            .onClick(onConfirm)
        }
        .width('100%').margin({ top: 20 })
      }
      .width('80%').padding(20).backgroundColor(this.colors.bgCard).borderRadius(20)
    }
    .width('100%').height('100%').zIndex(100)
  }
}
