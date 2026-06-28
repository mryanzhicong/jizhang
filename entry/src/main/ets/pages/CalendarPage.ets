import { CalendarPanel } from '../components/CalendarPanel';

@Component
export struct CalendarPage {
  build() {
    Stack() {
      Column() {
        CalendarPanel({ initYear: new Date().getFullYear(), initMonth: new Date().getMonth() })
      }.width('100%').height('100%')
      // 保底：确保和 HomePage 一样的布局结构
      Column().width(1).height(1).position({ x: 0, y: -48 })
    }.width('100%').height('100%').clip(false)
  }
}

