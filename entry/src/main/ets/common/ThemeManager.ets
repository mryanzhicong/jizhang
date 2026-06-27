/**
 * 主题管理器
 * 支持浅色/深色/跟随系统三种模式
 * 使用 AppStorage + @StorageLink 实现全局主题切换
 */

// 主题模式枚举
export const THEME_MODE_LIGHT = 0;
export const THEME_MODE_DARK = 1;
export const THEME_MODE_SYSTEM = 2;

// AppStorage Key
export const THEME_MODE_KEY = 'theme_mode';
export const IS_DARK_KEY = 'is_dark_mode';

/**
 * 初始化主题（在 EntryAbility.onCreate 中调用）
 */
export function initTheme(): void {
  // 默认浅色模式
  AppStorage.setOrCreate<number>(THEME_MODE_KEY, THEME_MODE_LIGHT);
  AppStorage.setOrCreate<boolean>(IS_DARK_KEY, false);
}

/**
 * 切换主题模式
 */
export function setThemeMode(mode: number): void {
  AppStorage.set<number>(THEME_MODE_KEY, mode);

  if (mode === THEME_MODE_LIGHT) {
    AppStorage.set<boolean>(IS_DARK_KEY, false);
    // HarmonyOS 可通过上下文设置系统颜色模式
  } else if (mode === THEME_MODE_DARK) {
    AppStorage.set<boolean>(IS_DARK_KEY, true);
  } else {
    // 跟随系统 - 获取系统颜色模式
    const sysDark = getSystemDarkMode();
    AppStorage.set<boolean>(IS_DARK_KEY, sysDark);
  }
}

/**
 * 获取系统是否为深色模式
 * 注：在真实设备上可通过 configuration 获取
 */
function getSystemDarkMode(): boolean {
  // 在真实 HarmonyOS 设备上，可通过
  // context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
  // 这里返回 false 作为默认值
  return false;
}

/**
 * 获取当前实际是否深色模式
 */
export function isDarkMode(): boolean {
  return AppStorage.get<boolean>(IS_DARK_KEY) ?? false;
}

/**
 * 获取当前主题模式设置
 */
export function getThemeMode(): number {
  return AppStorage.get<number>(THEME_MODE_KEY) ?? THEME_MODE_LIGHT;
}

// ==================== 主题颜色定义 ====================

export interface ThemeColors {
  // 主色
  primary: string;
  primaryLight: string;

  // 背景
  bgPage: string;
  bgCard: string;
  bgInput: string;

  // 文字
  textPrimary: string;
  textSecondary: string;
  textHint: string;
  textOnPrimary: string;

  // 收支颜色
  expenseColor: string;
  incomeColor: string;
  balanceColor: string;

  // 分割线
  divider: string;

  // Tab 栏
  tabBarBg: string;
  tabBarBorder: string;

  // 遮罩
  overlay: string;

  // 图表色板
  chartColors: string[];
}

/** 浅色主题颜色 */
export const LightColors: ThemeColors = {
  primary: '#4A90D9',
  primaryLight: '#E8F0FB',

  bgPage: '#F5F6F8',
  bgCard: '#FFFFFF',
  bgInput: '#F5F5F5',

  textPrimary: '#1A1A1A',
  textSecondary: '#8E8E93',
  textHint: '#C7C7CC',
  textOnPrimary: '#FFFFFF',

  expenseColor: '#E8554A',
  incomeColor: '#4CAF50',
  balanceColor: '#4A90D9',

  divider: '#EEEEEE',

  tabBarBg: '#FFFFFF',
  tabBarBorder: '#E0E0E0',

  overlay: 'rgba(0, 0, 0, 0.5)',

  chartColors: [
    '#4A90D9', '#E8554A', '#4CAF50', '#FF9800', '#9C27B0',
    '#00BCD4', '#FF5722', '#607D8B', '#795548', '#CDDC39'
  ]
};

/** 深色主题颜色 */
export const DarkColors: ThemeColors = {
  primary: '#5BA0E8',
  primaryLight: '#1E3A5F',

  bgPage: '#121212',
  bgCard: '#1E1E1E',
  bgInput: '#2C2C2C',

  textPrimary: '#E5E5E5',
  textSecondary: '#8E8E93',
  textHint: '#5C5C5C',
  textOnPrimary: '#FFFFFF',

  expenseColor: '#FF6B60',
  incomeColor: '#66BB6A',
  balanceColor: '#5BA0E8',

  divider: '#2C2C2C',

  tabBarBg: '#1E1E1E',
  tabBarBorder: '#2C2C2C',

  overlay: 'rgba(0, 0, 0, 0.7)',

  chartColors: [
    '#5BA0E8', '#FF6B60', '#66BB6A', '#FFB74D', '#CE93D8',
    '#4DD0E1', '#FF8A65', '#90A4AE', '#A1887F', '#DCE775'
  ]
};

/**
 * 获取当前主题颜色
 */
export function getThemeColors(): ThemeColors {
  return isDarkMode() ? DarkColors : LightColors;
}
