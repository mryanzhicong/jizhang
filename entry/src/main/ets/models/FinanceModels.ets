/**
 * 数据模型 & 预设分类常量
 * 极简记账 - HarmonyOS 6.0
 */

// ==================== 接口定义 ====================

/** 分类 */
export interface Category {
  id: number;
  name: string;
  icon: string;
  type: number;        // 0=支出, 1=收入
  parentId: number;    // 0=一级分类
  sortOrder: number;
  isDefault: number;
}

/** 交易记录 */
export interface RecordItem {
  id: number;
  type: number;        // 0=支出, 1=收入
  categoryId: number;
  amount: number;
  note: string;
  date: number;        // 时间戳(ms)
}

/** 记录列表项（带分类信息，用于展示） */
export interface RecordDisplay {
  id: number;
  type: number;
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  categoryParentId: number;
  parentCategoryName: string;
  amount: number;
  note: string;
  date: number;
}

/** 按日分组 */
export interface DayGroup {
  dateLabel: string;          // "今天" / "昨天" / "06月27日"
  dayIncome: number;
  dayExpense: number;
  records: RecordDisplay[];
}

/** 月度统计 */
export interface MonthStats {
  totalIncome: number;
  totalExpense: number;
  balance: number;
}

/** 分类统计 */
export interface CategoryStats {
  categoryId: number;
  categoryName: string;
  categoryIcon: string;
  parentCategoryId: number;
  parentCategoryName: string;
  amount: number;
  percent: number;
  count: number;
}

/** 月度趋势数据点 */
export interface MonthTrend {
  year: number;
  month: number;
  label: string;              // "1月" ...
  income: number;
  expense: number;
}

// ==================== 记录类型常量 ====================

export const RECORD_TYPE_EXPENSE = 0;
export const RECORD_TYPE_INCOME = 1;

// ==================== 主题常量 ====================

export const THEME_LIGHT = 0;
export const THEME_DARK = 1;
export const THEME_SYSTEM = 2;

// ==================== 预设分类数据 ====================

export interface PresetCategoryDef {
  name: string;
  icon: string;
  type: number;
  children: string[];
}

/** 支出大类及子分类 */
export const PRESET_EXPENSE_CATEGORIES: PresetCategoryDef[] = [
  { name: '餐饮', icon: 'restaurant', type: 0, children: ['早餐', '午餐', '晚餐', '外卖', '聚餐'] },
  { name: '购物', icon: 'cart', type: 0, children: ['日常购物'] },
  { name: '日用', icon: 'daily', type: 0, children: ['日用品'] },
  { name: '交通', icon: 'car', type: 0, children: ['公交', '地铁', '打车', '加油', '停车'] },
  { name: '蔬菜', icon: 'veg', type: 0, children: ['蔬菜'] },
  { name: '医疗', icon: 'medical', type: 0, children: ['门诊', '药品', '体检'] },
  { name: '零食', icon: 'snack', type: 0, children: ['零食'] },
  { name: '娱乐', icon: 'game', type: 0, children: ['电影', '游戏', '运动', '旅游'] },
  { name: '通讯', icon: 'mail', type: 0, children: ['话费', '宽带'] },
  { name: '服饰', icon: 'cloth', type: 0, children: ['衣服', '鞋子'] },
  { name: '美容', icon: 'beauty', type: 0, children: ['护肤', '化妆', '美发'] },
  { name: '住房', icon: 'home', type: 0, children: ['房租', '水电', '物业'] },
  { name: '居家', icon: 'house', type: 0, children: ['家居用品', '维修'] },
  { name: '社交', icon: 'people', type: 0, children: ['礼物', '红包', '聚会'] },
  { name: '数码', icon: 'digital', type: 0, children: ['手机', '电脑', '配件'] },
  { name: '书籍', icon: 'book', type: 0, children: ['书籍'] },
  { name: '学习', icon: 'study', type: 0, children: ['培训', '课程', '考试'] },
  { name: '办公', icon: 'office', type: 0, children: ['办公用品'] },
  { name: '快递', icon: 'express', type: 0, children: ['快递'] },
  { name: '其他', icon: 'more', type: 0, children: ['其他支出'] }
];

/** 收入大类及子分类 */
export const PRESET_INCOME_CATEGORIES: PresetCategoryDef[] = [
  { name: '工资', icon: 'payroll', type: 1, children: ['工资'] },
  { name: '兼职', icon: 'freelance', type: 1, children: ['兼职收入'] },
  { name: '理财', icon: 'stock', type: 1, children: ['理财收益'] },
  { name: '礼金', icon: 'gift', type: 1, children: ['礼金'] },
  { name: '其他', icon: 'more', type: 1, children: ['其他收入'] }
];

// ==================== 工具函数 ====================

/** 获取今天的零时时间戳 */
export function getTodayStart(): number {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

/** 获取本月起始时间戳 */
export function getMonthStart(year?: number, month?: number): number {
  const d = new Date();
  if (year !== undefined) d.setFullYear(year);
  if (month !== undefined) d.setMonth(month);
  d.setDate(1);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

/** 获取本月结束时间戳 */
export function getMonthEnd(year?: number, month?: number): number {
  const d = new Date();
  if (year !== undefined) d.setFullYear(year);
  if (month !== undefined) d.setMonth(month + 1);
  d.setDate(0);
  d.setHours(23, 59, 59, 999);
  return d.getTime();
}

/** 格式化金额 */
export function formatAmount(amount: number): string {
  return amount.toFixed(2);
}

/** 格式化金额（带正负号） */
export function formatAmountWithSign(amount: number, type: number): string {
  const sign = type === RECORD_TYPE_INCOME ? '+' : '-';
  return `${sign}${amount.toFixed(2)}`;
}

/** 日期转友好标签 */
export function getDateLabel(timestamp: number): string {
  const d = new Date(timestamp);
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const yesterdayStart = todayStart - 86400000;
  const recordStart = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();

  if (recordStart === todayStart) {
    return '今天';
  } else if (recordStart === yesterdayStart) {
    return '昨天';
  } else {
    const month = d.getMonth() + 1;
    const day = d.getDate();
    return `${month.toString().padStart(2, '0')}月${day.toString().padStart(2, '0')}日`;
  }
}

/** 获取月份标签 */
export function getMonthLabel(year: number, month: number): string {
  return `${year}年${(month + 1).toString().padStart(2, '0')}月`;
}

/** 获取简短月份标签 */
export function getShortMonthLabel(month: number): string {
  return `${month + 1}月`;
}

/** 时间戳转日期字符串 */
export function timestampToDateStr(timestamp: number): string {
  const d = new Date(timestamp);
  const y = d.getFullYear();
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export interface YearMonth {
  year: number;
  month: number;
}

/** 当前年月 */
export function getCurrentYearMonth(): YearMonth {
  const d = new Date();
  const result: YearMonth = { year: d.getFullYear(), month: d.getMonth() };
  return result;
}
