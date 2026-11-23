---
name: 《<專案名稱>》(<專案代號>)
description: <一句話描述>
colors:
  background: "#131313"
  surface: "#131313"
  surface-container-lowest: "#0e0e0e"
  surface-container-low: "#1b1b1c"
  surface-container-high: "#2a2a2a"
  surface-container-highest: "#353535"
  surface-bright: "#393939"
  on-background: "#e5e2e1"
  on-surface: "#e5e2e1"
  on-surface-variant: "#c0c7d3"
  outline-variant: "#404751"
  primary: "#9fcaff"
  primary-container: "#007acc"
  on-primary-container: "#ffffff"
  tertiary: "#66dd8b"
  error: "#ffb4ab"
  level-debug: "#8a94a3"
  level-info: "#9fcaff"
  level-warn: "#fcd34d"
  level-error: "#ffb4ab"
  status-success: "#66dd8b"
typography:
  headline:
    fontFamily: "system-ui, -apple-system, Segoe UI, Microsoft JhengHei, PingFang TC, sans-serif"
    fontSize: "16px"
    fontWeight: 700
    lineHeight: 1.2
  title:
    fontFamily: "system-ui, -apple-system, Segoe UI, Microsoft JhengHei, PingFang TC, sans-serif"
    fontSize: "14px"
    fontWeight: 500
    lineHeight: 1.4
  body:
    fontFamily: "system-ui, -apple-system, Segoe UI, Microsoft JhengHei, PingFang TC, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "system-ui, -apple-system, Segoe UI, Microsoft JhengHei, PingFang TC, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
  caption:
    fontFamily: "system-ui, -apple-system, Segoe UI, Microsoft JhengHei, PingFang TC, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.5
  mono:
    fontFamily: "ui-monospace, Cascadia Mono, Consolas, Microsoft JhengHei, monospace"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.6
rounded:
  control: "6px"
spacing:
  window-edge: "20px"
  block-gap: "12px"
  control-gap: "8px"
  label-gap: "6px"
  block-padding: "10px"
components:
  button-primary:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    height: "36px"
    padding: "0 12px"
  button-secondary:
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    height: "36px"
    padding: "0 12px"
  input:
    backgroundColor: "{colors.surface-container-lowest}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    height: "36px"
    padding: "0 12px"
  button-compact:
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    height: "28px"
    padding: "0 8px"
---

<!-- 本檔放在 docs/DESIGN.md。撰寫規則見 rules/DESIGN_RULES.md。
     frontmatter 是 token 的正本，預填的是 rules/tokens.css 的預設值與建議共用的字級、間距；
     照本專案實際用到的改，用不到的鍵整個刪掉。
     H1、八個 H2、Creative North Star、Key Characteristics、The … Rule、Do:/Don't: 這些英文標記不得翻譯。
     沒用到的章節或表列寫「未使用」，不要刪。
     已有畫面時建議直接跑 /impeccable document，它會從程式碼抽值並產生 .impeccable/design.json。
     填完刪除所有 HTML 註解。 -->

# Design System: 《<專案名稱>》(<專案代號>)

## Overview

**Creative North Star: "<具名的比喻>"**

<兩三段：整體性格、密度、美學取向。從北極星出發往外寫；只寫使用者確認過的拒絕對象。>

| 項目 | 值 |
| :--- | :--- |
| 畫面型態 | <例：單一視窗的桌面小工具 / 多面板工作站 / 網頁> |
| 預設尺寸 | <寬> × <高>（邏輯像素） |
| 最小尺寸 | <寬> × <高> |
| 可否縮放 | <可 / 不可> |
| 視窗標題 | 《<專案名稱>》(<專案代號>) v<版本號> |
| 系列 | <獨立專案 / 屬於 <系列名稱>，token 檔來源：<路徑>> |

<!-- 尺寸一律以邏輯像素為準。高 DPI 下量測時，工具本身必須是 DPI 感知的，
     否則會量到實體像素而誤判版面溢出。 -->

**Key Characteristics:**

- <特徵>
- <特徵>

## Colors

<一句話描述整體色彩性格。>

沿用 [rules/tokens.css](rules/tokens.css) 的共用 token（**必須共用**，不得自訂）。

### Primary

| Token | 描述名 | 色值 | 用在哪 |
| :--- | :--- | :--- | :--- |
| `primary` | <描述名> | `#9fcaff` | <焦點框、連結、強調文字> |
| `primary-container` | <描述名> | `#007acc` | <主要按鈕底色> |

### Tertiary

| Token | 描述名 | 色值 | 用在哪 |
| :--- | :--- | :--- | :--- |
| `tertiary` | <描述名> | `#66dd8b` | <用途> |

### Neutral

| Token | 描述名 | 色值 | 用在哪 |
| :--- | :--- | :--- | :--- |
| `background` | <描述名> | `#131313` | <視窗底色> |
| `surface-container-low` | <描述名> | `#1b1b1c` | <用途> |
| `on-surface` | <描述名> | `#e5e2e1` | <主要文字> |
| `outline-variant` | <描述名> | `#404751` | <分隔線、次要按鈕描邊> |
| … | … | … | … |

### 日誌與狀態色

| Token | 色值 | 用在哪 |
| :--- | :--- | :--- |
| `level-debug` | `#8a94a3` | `DEBUG` |
| `level-info` | `#9fcaff` | `INFO` |
| `level-warn` | `#fcd34d` | `WARN` |
| `level-error` | `#ffb4ab` | `ERROR` |
| `status-success` | `#66dd8b` | 動作成功完成的提示（不是日誌等級） |

**本專案額外定義的色**：<沒有就寫「無」>

### Named Rules

**The <英文名> Rule.** <一句話的色彩守則。>

## Typography

**Body Font:** <字體>（後備 <後備字體>）
**Mono Font:** <字體>

**Character:** <一兩句描述字體搭配的性格。>

字體堆疊沿用共用 token（**必須共用**）。字級表屬**建議共用**。

| 用途 | Token | 字級 | 字重 | 行距 | 字體 |
| :--- | :--- | ---: | ---: | ---: | :--- |
| H1 應用程式標題 | `headline` | 16px | 700 | 1.2 | sans |
| H2 區塊標題 | `title` | 14px | 500 | 1.4 | sans |
| 內文／按鈕 | `body` | 14px | 400 | 1.5 | sans |
| 欄位標籤 | `label` | 12px | 400 | 1.4 | sans |
| 次要說明 | `caption` | 11px | 400 | 1.5 | sans |
| 路徑／日誌 | `mono` | 11px | 400 | 1.6 | mono |

- 同一列的控制項字級必須相同。
- 不得使用表外的字級。
- 等寬字體只用於路徑、雜湊、日誌、程式碼、數字欄位。

### Named Rules

**The <英文名> Rule.** <一句話的字體守則。>

## Layout

<一段：空間模型、密度、容器行為。>

### 語意間距

| 名稱 | Token | 值 | 用於 |
| :--- | :--- | ---: | :--- |
| 視窗外緣 | `window-edge` | 20px | 內容距視窗四邊（上下左右一律相同） |
| 區塊間 | `block-gap` | 12px | <哪些區塊之間> |
| 控制項間 | `control-gap` | 8px | 同一列的控制項之間 |
| 標籤與欄位 | `label-gap` | 6px | 欄位標籤與其輸入框之間 |
| 區塊內邊距 | `block-padding` | 10px | <哪個區塊的內容距邊框> |

- **四邊外緣必須相等**，不得單獨加大某一邊。
- 不得使用表外的值；真的需要就先改這張表與 frontmatter。

### 畫面結構

<!-- 版型屬「各自決定」，不得與其他專案互相套用。建議用 ASCII 示意，不用截圖。 -->

```text
<在這裡畫版型示意>
```

| 區塊 | 職責 |
| :--- | :--- |
| <區塊> | <做什麼> |

### 斷點

<斷點與各斷點的變化；不縮放的桌面工具寫「未使用」。>

## Elevation & Depth

<一段：層次靠陰影、色階還是兩者混用。>

層次一律靠 `surface` 色階表現：越上層的元素用越亮的階。

### 不透明度

只使用共用 token 的五檔（**必須共用**）：

| 檔位 | 值 | 用於 |
| :--- | ---: | :--- |
| 主要 | 100% | 主要文字、實心元件 |
| 次要 | 70% | 次要文字 |
| 提示 | 50% | 提示文字、placeholder |
| 停用 | 40% | 停用狀態 |
| 分隔 | 25% | 分隔線、邊框 |

### 光暈／模糊／漸層／陰影

| 效果 | 是否使用 | 用途與強度 |
| :--- | :--- | :--- |
| 光暈（box-shadow 發光） | <使用 / 未使用> | <用在哪、色值與模糊半徑> |
| 陰影（box-shadow） | <使用 / 未使用> | <用在哪、完整的 box-shadow 值> |
| 高斯模糊（backdrop-filter） | <使用 / 未使用> | <用在哪、模糊半徑> |
| 漸層 | <使用 / 未使用> | <用在哪、起訖色與方向> |

<!-- 沒用到就寫「未使用」，不要刪掉列——這樣才分得出「刻意不用」與「忘了寫」。 -->

### Named Rules

**The <英文名> Rule.** <一句話的層次守則，例如「表面在靜止時是平的，陰影只回應狀態」。>

## Shapes

<一段：圓角策略、邊框、外框語言。>

| 檔位 | Token | 值 | 用於 |
| :--- | :--- | ---: | :--- |
| 控制項 | `control` | 6px | 輸入框、下拉、按鈕 |

## Components

<一句話描述元件整體手感，例如「沉穩、可預期」。>

### 控制項尺寸

| 項目 | 值 |
| :--- | :--- |
| 標準高度 | 36px（輸入框、下拉、按鈕一律） |
| 緊湊高度 | 28px（工具列、表格內） |
| 圓角 | 控制項圓角（6px） |
| 水平內邊距 | 至少 12px |

同一列的控制項**必須等高、字級相同**，寬度可不同。

### Buttons

| 角色 | Token | 外觀 | 用於 |
| :--- | :--- | :--- | :--- |
| 主要 | `button-primary` | 實心，`primary-container` 底，無框 | <該畫面唯一的主要動作> |
| 次要 | `button-secondary` | 透明底，`outline-variant` 描邊 | <其餘動作> |

每個畫面**最多一個**主要按鈕。按鈕文字用動詞。

| 狀態 | 表現 |
| :--- | :--- |
| hover | 主要提亮 10%；次要底色加深一階 |
| active | 不做位移，只加深 |
| disabled | 不透明度 40% + 禁止游標 |
| 進行中 | 改文字（如「執行中…」）並停用 |

### Inputs

| 項目 | 表現 |
| :--- | :--- |
| 外觀 | <底色、描邊、圓角> |
| 焦點 | 共用焦點樣式（見下表） |
| 錯誤 | <說明> |
| 停用 | 不透明度 40% + 禁止游標 |

### 狀態與回饋

| 狀態 | 表現 |
| :--- | :--- |
| 焦點 | 2px `primary` 外框、偏移 2px，走 `:focus-visible`（**必須共用**） |
| hover | <說明> |
| 停用 | 不透明度 40% + 禁止游標（**必須共用**） |
| 載入／進行中 | <說明> |
| 錯誤 | <說明> |

<!-- 焦點樣式不得省略：所有可以 Tab 走到的元件都必須看得見焦點。
     禁止只寫 outline:none 而不補替代樣式。 -->

### 日誌與訊息

<!-- 沒有日誌或訊息輸出就寫「未使用」。 -->

等級名稱與配色屬**必須共用**，識別字串逐字照 `DESIGN_RULES.md` §4.8：

| 等級 | 識別字串 | 顏色 | 預設顯示 |
| :--- | :--- | :--- | :--- |
| debug | `DEBUG` | `level-debug` | 否 |
| info | `INFO` | `level-info` | 是 |
| warn | `WARN` | `level-warn` | 是 |
| error | `ERROR` | `level-error` | 是 |

每則訊息都帶識別字串或文字前綴；顏色只是增強。「成功」用 `status-success`，不是等級。

### Motion

<!-- 選用。沒有動畫就寫「未使用」。 -->

| 用途 | 時間 | 曲線 |
| :--- | ---: | :--- |
| <狀態切換> | <150ms> | <ease-out> |

尊重 `prefers-reduced-motion`。

### <招牌元件>

<!-- 選用。本專案獨有、會反覆出現的元件，一個一個 H3。 -->

<描述、尺寸、狀態。>

## Do's and Don'ts

### Do:

- **Do** <具體的做法，附精確值或守則名>。
- **Do** <…>。

### Don't:

- **Don't** <程式碼現況或使用者確認過的禁止事項>。
- **Don't** <…>。
