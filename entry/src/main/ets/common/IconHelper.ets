/**
 * 图标工具 - 用 Emoji 替代不确定的系统图标名称
 * 只对确定存在的系统图标使用 SymbolGlyph
 * 避免 sys.symbol.XXX 资源名不存在导致的编译错误
 */

/** 分类 icon 名 → emoji 映射 */
const CATEGORY_EMOJI: Record<string, string> = {
  'restaurant': '🍽️', 'car': '🚗', 'cart': '🛒', 'home': '🏠',
  'game': '🎮', 'heart': '❤️', 'book': '📖', 'mail': '📧',
  'people': '👥', 'more': '⋯', 'payroll': '💰', 'freelance': '💼',
  'stock': '📈', 'refund': '↩️', 'daily': '🧴', 'veg': '🥬',
  'fruit': '🍎', 'snack': '🍿', 'cloth': '👕', 'beauty': '💄', 'medical': '🏥',
  'house': '🏡', 'digital': '📱', 'study': '📚', 'office': '🖊️',
  'express': '📦', 'gift': '🎁',
};

/** 账本 icon 名 → emoji 映射 */
const BOOK_EMOJI: Record<string, string> = {
  'book': '📒',
  'house': '🏠',
  'car': '🚗',
  'heart': '❤️',
  'star': '⭐',
  'airplane': '✈️',
};

export function getCategoryEmoji(icon: string): string {
  return CATEGORY_EMOJI[icon] ?? '📌';
}

export function getBookEmoji(icon: string): string {
  return BOOK_EMOJI[icon] ?? '📒';
}
