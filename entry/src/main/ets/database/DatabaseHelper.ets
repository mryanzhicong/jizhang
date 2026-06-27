/**
 * 数据库单例 - 全局数据库访问（统一账本）
 * 3 张表：categories, records, budgets
 */
import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import {
  Category, RecordItem, Budget,
  RecordDisplay, DayGroup, MonthStats,
  CategoryStats, MonthTrend,
  RECORD_TYPE_EXPENSE, RECORD_TYPE_INCOME,
  PRESET_EXPENSE_CATEGORIES, PRESET_INCOME_CATEGORIES,
  PresetCategoryDef,
  getMonthStart, getMonthEnd
} from '../models/FinanceModels';

const DB_NAME = 'JianJiZhang.db';

interface RawStatEntry {
  parentId: number;
  count: number;
  amount: number;
  sampleCatId: number;
}

export class DatabaseHelper {
  private static instance: DatabaseHelper | null = null;
  private store: relationalStore.RdbStore | null = null;

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) DatabaseHelper.instance = new DatabaseHelper();
    return DatabaseHelper.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.store = await relationalStore.getRdbStore(context, config);
    await this.createTables();
    await this.insertPresetData();
  }

  private ensureStore(): relationalStore.RdbStore {
    if (!this.store) throw new Error('Database not initialized.');
    return this.store;
  }

  // ==================== 建表 ====================
  private async createTables(): Promise<void> {
    const store = this.ensureStore();

    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        type INTEGER NOT NULL,
        parent_id INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 1
      )
    `);

    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT DEFAULT '',
        date INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    `);

    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        amount REAL NOT NULL
      )
    `);

    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_records_date ON records(date)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type)');
  }

  // ==================== 预设数据 ====================
  private async insertPresetData(): Promise<void> {
    const store = this.ensureStore();
    const rs = await store.query(new relationalStore.RdbPredicates('categories'));
    const hasData = rs.rowCount > 0;
    rs.close();

    if (!hasData) {
      const allPresets = [...PRESET_EXPENSE_CATEGORIES, ...PRESET_INCOME_CATEGORIES];
      let sortIdx = 0;
      for (const preset of allPresets) {
        const parentId = await store.insert('categories', {
          'name': preset.name, 'icon': preset.icon, 'type': preset.type,
          'parent_id': 0, 'sort_order': sortIdx++, 'is_default': 1
        } as ValuesBucket);
        for (let i = 0; i < preset.children.length; i++) {
          await store.insert('categories', {
            'name': preset.children[i], 'icon': preset.icon, 'type': preset.type,
            'parent_id': parentId, 'sort_order': i, 'is_default': 1
          } as ValuesBucket);
        }
      }
    }
  }

  // ==================== 分类 CRUD ====================
  async getCategories(type?: number): Promise<Category[]> {
    const store = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('categories');
    if (type !== undefined) pred.equalTo('type', type);
    pred.orderByAsc('sort_order');
    const rs = await store.query(pred);
    const cats: Category[] = [];
    while (rs.goToNextRow()) {
      cats.push({ id: rs.getLong(rs.getColumnIndex('id')),
        name: rs.getString(rs.getColumnIndex('name')),
        icon: rs.getString(rs.getColumnIndex('icon')),
        type: rs.getLong(rs.getColumnIndex('type')),
        parentId: rs.getLong(rs.getColumnIndex('parent_id')),
        sortOrder: rs.getLong(rs.getColumnIndex('sort_order')),
        isDefault: rs.getLong(rs.getColumnIndex('is_default')) });
    }
    rs.close();
    return cats;
  }

  async getParentCategories(type: number): Promise<Category[]> {
    const store = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('categories');
    pred.equalTo('type', type).equalTo('parent_id', 0).orderByAsc('sort_order');
    const rs = await store.query(pred);
    const cats: Category[] = [];
    while (rs.goToNextRow()) {
      cats.push({ id: rs.getLong(rs.getColumnIndex('id')),
        name: rs.getString(rs.getColumnIndex('name')),
        icon: rs.getString(rs.getColumnIndex('icon')),
        type: rs.getLong(rs.getColumnIndex('type')),
        parentId: 0, sortOrder: rs.getLong(rs.getColumnIndex('sort_order')),
        isDefault: rs.getLong(rs.getColumnIndex('is_default')) });
    }
    rs.close();
    return cats;
  }

  async getChildCategories(parentId: number): Promise<Category[]> {
    const store = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('categories');
    pred.equalTo('parent_id', parentId).orderByAsc('sort_order');
    const rs = await store.query(pred);
    const cats: Category[] = [];
    while (rs.goToNextRow()) {
      cats.push({ id: rs.getLong(rs.getColumnIndex('id')),
        name: rs.getString(rs.getColumnIndex('name')),
        icon: rs.getString(rs.getColumnIndex('icon')),
        type: rs.getLong(rs.getColumnIndex('type')),
        parentId: rs.getLong(rs.getColumnIndex('parent_id')),
        sortOrder: rs.getLong(rs.getColumnIndex('sort_order')),
        isDefault: rs.getLong(rs.getColumnIndex('is_default')) });
    }
    rs.close();
    return cats;
  }

  async getCategoryById(catId: number): Promise<Category | null> {
    const store = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('categories');
    pred.equalTo('id', catId);
    const rs = await store.query(pred);
    let cat: Category | null = null;
    if (rs.goToNextRow()) {
      cat = { id: rs.getLong(rs.getColumnIndex('id')),
        name: rs.getString(rs.getColumnIndex('name')),
        icon: rs.getString(rs.getColumnIndex('icon')),
        type: rs.getLong(rs.getColumnIndex('type')),
        parentId: rs.getLong(rs.getColumnIndex('parent_id')),
        sortOrder: rs.getLong(rs.getColumnIndex('sort_order')),
        isDefault: rs.getLong(rs.getColumnIndex('is_default')) };
    }
    rs.close();
    return cat;
  }

  async addCategory(name: string, icon: string, type: number, parentId: number): Promise<number> {
    const store = this.ensureStore();
    return await store.insert('categories', {
      'name': name, 'icon': icon, 'type': type,
      'parent_id': parentId, 'sort_order': 0, 'is_default': 0
    } as ValuesBucket);
  }

  async updateCategory(catId: number, name: string, icon: string): Promise<number> {
    const store = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('categories');
    pred.equalTo('id', catId);
    return await store.update({ 'name': name, 'icon': icon } as ValuesBucket, pred);
  }

  async deleteCategory(catId: number): Promise<void> {
    const store = this.ensureStore();
    const cat = await this.getCategoryById(catId);
    if (cat && cat.parentId > 0) {
      await store.executeSql('UPDATE records SET category_id = ? WHERE category_id = ?',
        [cat.parentId.toString(), catId.toString()]);
    }
    await store.executeSql('DELETE FROM categories WHERE parent_id = ?', [catId.toString()]);
    const pred = new relationalStore.RdbPredicates('categories');
    pred.equalTo('id', catId);
    await store.delete(pred);
  }

  // ==================== 记录 ====================
  async addRecord(type: number, categoryId: number, amount: number,
    note: string, date: number): Promise<number> {
    return await this.ensureStore().insert('records', {
      'type': type, 'category_id': categoryId,
      'amount': amount, 'note': note, 'date': date
    } as ValuesBucket);
  }

  async updateRecord(recordId: number, type: number, categoryId: number,
    amount: number, note: string, date: number): Promise<number> {
    const pred = new relationalStore.RdbPredicates('records');
    pred.equalTo('id', recordId);
    return await this.ensureStore().update({
      'type': type, 'category_id': categoryId,
      'amount': amount, 'note': note, 'date': date
    } as ValuesBucket, pred);
  }

  async deleteRecord(recordId: number): Promise<void> {
    const pred = new relationalStore.RdbPredicates('records');
    pred.equalTo('id', recordId);
    await this.ensureStore().delete(pred);
  }

  async getRecordsGroupedByDay(year: number, month: number): Promise<DayGroup[]> {
    const store = this.ensureStore();
    const monthStart = getMonthStart(year, month);
    const monthEnd = getMonthEnd(year, month);
    const sql = `
      SELECT r.id, r.type, r.category_id, r.amount, r.note, r.date,
             c.name as cat_name, c.icon as cat_icon, c.parent_id as cat_parent_id,
             COALESCE(pc.name, '') as parent_name
      FROM records r
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN categories pc ON c.parent_id = pc.id
      WHERE r.date >= ? AND r.date <= ?
      ORDER BY r.date DESC, r.id DESC
    `;
    const rs = await store.querySql(sql, [monthStart.toString(), monthEnd.toString()]);
    const records: RecordDisplay[] = [];
    while (rs.goToNextRow()) {
      records.push({
        id: rs.getLong(rs.getColumnIndex('id')),
        type: rs.getLong(rs.getColumnIndex('type')),
        categoryId: rs.getLong(rs.getColumnIndex('category_id')),
        categoryName: rs.getString(rs.getColumnIndex('cat_name')),
        categoryIcon: rs.getString(rs.getColumnIndex('cat_icon')),
        categoryParentId: rs.getLong(rs.getColumnIndex('cat_parent_id')),
        parentCategoryName: rs.getString(rs.getColumnIndex('parent_name')),
        amount: rs.getDouble(rs.getColumnIndex('amount')),
        note: rs.getString(rs.getColumnIndex('note')),
        date: rs.getLong(rs.getColumnIndex('date'))
      });
    }
    rs.close();
    return this.groupByDay(records);
  }

  private groupByDay(records: RecordDisplay[]): DayGroup[] {
    const groupMap = new Map<string, DayGroup>();
    for (const r of records) {
      const d = new Date(r.date);
      const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
      if (!groupMap.has(key)) {
        const m = d.getMonth() + 1;
        const day = d.getDate();
        groupMap.set(key, {
          dateLabel: `${m.toString().padStart(2,'0')}月${day.toString().padStart(2,'0')}日`,
          dayIncome: 0, dayExpense: 0, records: []
        });
      }
      const g = groupMap.get(key)!;
      if (r.type === RECORD_TYPE_INCOME) g.dayIncome += r.amount;
      else g.dayExpense += r.amount;
      g.records.push(r);
    }
    return Array.from(groupMap.values());
  }

  async getAllRecords(): Promise<RecordDisplay[]> {
    const store = this.ensureStore();
    const sql = `
      SELECT r.id, r.type, r.category_id, r.amount, r.note, r.date,
             c.name as cat_name, c.icon as cat_icon, c.parent_id as cat_parent_id,
             COALESCE(pc.name, '') as parent_name
      FROM records r
      LEFT JOIN categories c ON r.category_id = c.id
      LEFT JOIN categories pc ON c.parent_id = pc.id
      ORDER BY r.date DESC
    `;
    const rs = await store.querySql(sql, []);
    const records: RecordDisplay[] = [];
    while (rs.goToNextRow()) {
      records.push({
        id: rs.getLong(rs.getColumnIndex('id')),
        type: rs.getLong(rs.getColumnIndex('type')),
        categoryId: rs.getLong(rs.getColumnIndex('category_id')),
        categoryName: rs.getString(rs.getColumnIndex('cat_name')),
        categoryIcon: rs.getString(rs.getColumnIndex('cat_icon')),
        categoryParentId: rs.getLong(rs.getColumnIndex('cat_parent_id')),
        parentCategoryName: rs.getString(rs.getColumnIndex('parent_name')),
        amount: rs.getDouble(rs.getColumnIndex('amount')),
        note: rs.getString(rs.getColumnIndex('note')),
        date: rs.getLong(rs.getColumnIndex('date'))
      });
    }
    rs.close();
    return records;
  }

  // ==================== 统计 ====================
  async getMonthStats(year: number, month: number): Promise<MonthStats> {
    const store = this.ensureStore();
    const ms = getMonthStart(year, month);
    const me = getMonthEnd(year, month);

    const incRs = await store.querySql(
      'SELECT COALESCE(SUM(amount),0) as t FROM records WHERE type=1 AND date>=? AND date<=?',
      [ms.toString(), me.toString()]);
    let ti = 0; if (incRs.goToNextRow()) ti = incRs.getDouble(incRs.getColumnIndex('t')); incRs.close();

    const expRs = await store.querySql(
      'SELECT COALESCE(SUM(amount),0) as t FROM records WHERE type=0 AND date>=? AND date<=?',
      [ms.toString(), me.toString()]);
    let te = 0; if (expRs.goToNextRow()) te = expRs.getDouble(expRs.getColumnIndex('t')); expRs.close();

    const budRs = await store.querySql(
      'SELECT amount FROM budgets WHERE year=? AND month=?',
      [year.toString(), month.toString()]);
    let ba = 0; if (budRs.goToNextRow()) ba = budRs.getDouble(budRs.getColumnIndex('amount')); budRs.close();

    return {
      totalIncome: ti, totalExpense: te, balance: ti - te,
      budgetAmount: ba, budgetUsed: ba > 0 ? (te / ba) * 100 : 0
    };
  }

  async getCategoryStats(year: number, month: number, recordType: number): Promise<CategoryStats[]> {
    const store = this.ensureStore();
    const ms = getMonthStart(year, month);
    const me = getMonthEnd(year, month);
    const sql = `
      SELECT CASE WHEN c.parent_id > 0 THEN c.parent_id ELSE c.id END as pid,
             COUNT(r.id) as cnt, SUM(r.amount) as ta
      FROM records r LEFT JOIN categories c ON r.category_id=c.id
      WHERE r.type=? AND r.date>=? AND r.date<=?
      GROUP BY CASE WHEN c.parent_id > 0 THEN c.parent_id ELSE c.id END
      ORDER BY ta DESC
    `;
    const rs = await store.querySql(sql, [recordType.toString(), ms.toString(), me.toString()]);
    let totalAmount = 0;
    const rawStats: RawStatEntry[] = [];
    while (rs.goToNextRow()) {
      const amt = rs.getDouble(rs.getColumnIndex('ta'));
      totalAmount += amt;
      const entry: RawStatEntry = {
        parentId: rs.getLong(rs.getColumnIndex('pid')),
        count: rs.getLong(rs.getColumnIndex('cnt')),
        amount: amt,
        sampleCatId: 0
      };
      rawStats.push(entry);
    }
    rs.close();

    const stats: CategoryStats[] = [];
    for (const raw of rawStats) {
      let cn = '其他';
      let ci = 'more';
      if (raw.parentId > 0) {
        const cat = await this.getCategoryById(raw.parentId);
        if (cat) { cn = cat.name; ci = cat.icon; }
      }
      const cs: CategoryStats = {
        categoryId: raw.parentId,
        categoryName: cn,
        categoryIcon: ci,
        parentCategoryId: raw.parentId,
        parentCategoryName: '',
        amount: raw.amount,
        percent: totalAmount > 0 ? (raw.amount / totalAmount) * 100 : 0,
        count: raw.count
      };
      stats.push(cs);
    }
    return stats;
  }

  async getFullMonthTrends(): Promise<MonthTrend[]> {
    const store = this.ensureStore();
    const trends: MonthTrend[] = [];
    const now = new Date();
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const y = d.getFullYear(), m = d.getMonth();
      const ms = getMonthStart(y, m), me = getMonthEnd(y, m);

      const incRs = await store.querySql(
        'SELECT COALESCE(SUM(amount),0) as t FROM records WHERE type=1 AND date>=? AND date<=?',
        [ms.toString(), me.toString()]);
      let inc = 0; if (incRs.goToNextRow()) inc = incRs.getDouble(incRs.getColumnIndex('t')); incRs.close();

      const expRs = await store.querySql(
        'SELECT COALESCE(SUM(amount),0) as t FROM records WHERE type=0 AND date>=? AND date<=?',
        [ms.toString(), me.toString()]);
      let exp = 0; if (expRs.goToNextRow()) exp = expRs.getDouble(expRs.getColumnIndex('t')); expRs.close();

      trends.push({ year: y, month: m, label: `${m+1}月`, income: inc, expense: exp });
    }
    return trends;
  }

  // ==================== 周期统计 ====================

  async getPeriodCategoryStats(startMs: number, endMs: number, recordType: number): Promise<CategoryStats[]> {
    const store = this.ensureStore();
    const sql = `
      SELECT CASE WHEN c.parent_id > 0 THEN c.parent_id ELSE c.id END as pid,
             COUNT(r.id) as cnt, SUM(r.amount) as ta
      FROM records r LEFT JOIN categories c ON r.category_id=c.id
      WHERE r.type=? AND r.date>=? AND r.date<=?
      GROUP BY CASE WHEN c.parent_id > 0 THEN c.parent_id ELSE c.id END
      ORDER BY ta DESC
    `;
    const rs = await store.querySql(sql, [recordType.toString(), startMs.toString(), endMs.toString()]);
    let totalAmount = 0;
    const rawStats: RawStatEntry[] = [];
    while (rs.goToNextRow()) {
      const amt = rs.getDouble(rs.getColumnIndex('ta'));
      totalAmount += amt;
      rawStats.push({
        parentId: rs.getLong(rs.getColumnIndex('pid')),
        count: rs.getLong(rs.getColumnIndex('cnt')),
        amount: amt,
        sampleCatId: 0
      });
    }
    rs.close();
    const stats: CategoryStats[] = [];
    for (const raw of rawStats) {
      let cn = '其他', ci = 'more';
      if (raw.parentId > 0) {
        const cat = await this.getCategoryById(raw.parentId);
        if (cat) { cn = cat.name; ci = cat.icon; }
      }
      stats.push({
        categoryId: raw.parentId, categoryName: cn, categoryIcon: ci,
        parentCategoryId: raw.parentId, parentCategoryName: '',
        amount: raw.amount, percent: totalAmount > 0 ? (raw.amount / totalAmount) * 100 : 0,
        count: raw.count
      });
    }
    return stats;
  }

  async getDayBars(startMs: number, endMs: number, recordType: number, groupBy: string): Promise<MonthTrend[]> {
    const store = this.ensureStore();
    const format = groupBy === 'day' ? "strftime('%Y-%m-%d', r.date/1000, 'unixepoch')" :
      "strftime('%Y-%m', r.date/1000, 'unixepoch')";
    const sql = `SELECT ${format} as label, r.type,
      SUM(r.amount) as ta FROM records r
      WHERE r.date>=? AND r.date<=?
      GROUP BY ${format}, r.type ORDER BY label`;
    const rs = await store.querySql(sql, [startMs.toString(), endMs.toString()]);
    const map = new Map<string, MonthTrend>();
    while (rs.goToNextRow()) {
      const key = rs.getString(rs.getColumnIndex('label'));
      if (!map.has(key)) {
        map.set(key, { year: 0, month: 0, label: key, income: 0, expense: 0 });
      }
      const entry = map.get(key)!;
      const type = rs.getLong(rs.getColumnIndex('type'));
      const amt = rs.getDouble(rs.getColumnIndex('ta'));
      if (type === 1) { entry.income = amt; } else { entry.expense = amt; }
    }
    rs.close();
    const items = Array.from(map.values());
    items.sort((a: MonthTrend, b: MonthTrend) => a.label.localeCompare(b.label));
    return items;
  }

  // ==================== 预算 ====================
  async getBudget(year: number, month: number): Promise<Budget | null> {
    const store = this.ensureStore();
    const pred = new relationalStore.RdbPredicates('budgets');
    pred.equalTo('year', year).equalTo('month', month);
    const rs = await store.query(pred);
    let budget: Budget | null = null;
    if (rs.goToNextRow()) {
      budget = { id: rs.getLong(rs.getColumnIndex('id')),
        year: rs.getLong(rs.getColumnIndex('year')),
        month: rs.getLong(rs.getColumnIndex('month')),
        amount: rs.getDouble(rs.getColumnIndex('amount')) };
    }
    rs.close();
    return budget;
  }

  async setBudget(year: number, month: number, amount: number): Promise<void> {
    const store = this.ensureStore();
    const existing = await this.getBudget(year, month);
    if (existing) {
      const pred = new relationalStore.RdbPredicates('budgets');
      pred.equalTo('id', existing.id);
      await store.update({ 'amount': amount } as ValuesBucket, pred);
    } else {
      await store.insert('budgets', {
        'year': year, 'month': month, 'amount': amount
      } as ValuesBucket);
    }
  }

  // ==================== 导出 ====================
  async exportToCSV(): Promise<string> {
    const records = await this.getAllRecords();
    let csv = '﻿日期,类型,分类,金额,备注\n';
    for (const r of records) {
      const ds = new Date(r.date).toLocaleDateString('zh-CN');
      const ts = r.type === RECORD_TYPE_INCOME ? '收入' : '支出';
      const cs = r.parentCategoryName ? `${r.parentCategoryName}-${r.categoryName}` : r.categoryName;
      csv += `${ds},${ts},${cs},${r.amount.toFixed(2)},${r.note}\n`;
    }
    return csv;
  }
}
