# Mark Paper

[English](README.md) | 繁體中文

---

本專案是一個自給自足、可重現的現代純文字學術寫作工作流程範例，圍繞 **Markdown** 、 **Pandoc** 與 **LaTeX** 構建。核心理念是將內容與呈現分離：您在 `paper.md` 中以純文字撰寫論文初稿，而格式設定、排版與輸出細節則由 Pandoc、LaTeX 以及少量的設定檔自動處理。

`main` 分支本身即是該範例：`paper.md` 是一篇教學與方法論論文，解釋了 **為什麼** 以及 **如何** 使用純文字、Pandoc、LaTeX 與 Git 來撰寫學術論文或學位論文，而非使用 Microsoft Word 或 Google Docs 等文字處理軟體。它以自身作為實際範例，端到端展示了完整的作業流程（引文、參考文獻、表格、交叉引用、Mermaid 圖表、多語言排版、自訂頁面版面、獨立封面頁面以及 AI 輔助工作流程）。

**備註** ：作者實際完成的學位論文（使用此工具鏈的早期版本建置）已歸檔於 `M11326915` 分支以供參考，並未保留在 `main` 分支中。

### 核心理念

- 永續性與耐久性：與專有的文書處理格式相比，純文字 Markdown 檔案具有長久保存的優勢。它們具備高度可讀性、便於比較差異（diff-friendly），並且能自然地與 Git 整合。
- 關注點分離：論文手稿（`paper.md`）僅包含語意內容與結構；視覺外觀則交由 LaTeX 範本與 YAML 詮釋資料區塊中定義的 Pandoc 設定處理。
- 可重現性：從 Markdown 與參考文獻資料到最終 PDF 的整個流程均已腳本化且可重複執行。任何人只要擁有相同的工具鏈，即可產生完全相同的輸出成果。
- 透明度與可除錯性：每個階段（Markdown → Pandoc → LaTeX → PDF）皆可被檢視。可以檢查產生的 `.tex` 等中繼檔案，以對排版或過濾器問題進行除錯。
- Git 友善的寫作方式：由於所有內容都是純文字（手稿、詮釋資料、參考文獻），完整的研究與寫作歷程都可以透過標準版本控制實踐進行追蹤、分支與合併。
- 降低工具鏈學習曲線：AI 助理與自動化編程工具可充當編譯副駕駛，將高階寫作與排版意圖轉譯為精確的 Pandoc YAML 與 LaTeX 巨集，無需作者精通晦澀的 TeX 語法。

### `paper.md` 中展示的元件

- Pandoc：核心文件轉換器，將 `paper.md` 轉換為 LaTeX，隨後編譯為 PDF。
- LaTeX 發行版（TeX Live / XeLaTeX）：提供支援 Unicode 的排版引擎與套件，用於進階版面配置、微排版（micro-typography）與多語言文字。
- 純文字編輯器：任何用於編寫 Markdown 原始碼的現代編輯器（VS Code、Zettlr 等）。
- 參考文獻管理工具（Zotero + Better BibTeX）：管理書目資料，並自動匯出為 `references.bib` 供 Pandoc 使用（選用；作者亦可直接手動建立與維護書目檔案）。
- CSL 樣式：引文樣式語言定義（例如 `chicago-author-date.csl`），規範正文引文與參考文獻清單的格式。
- Pandoc 過濾器：
  - `--citeproc` 用於自動化引文處理與參考文獻清單產生。
  - `pandoc-crossref` 用於圖表、表格與公式的編號及交叉引用。
- Mermaid.js 與 Puppeteer：自動無頭渲染程式碼圖表為高解析度圖片（`images/mermaid-*.png`）。
- 獨立 LaTeX 封面頁（`cover_page.tex`）：專用的封面頁範本，包含官方標誌 `images/scholarship_logo.jpg` 與雙語詮釋資料。

### 特色展示

- YAML 詮釋資料區塊作為控制面板：在 `paper.md` 頂端，豐富的 YAML 標頭可設定：
  - 文件詮釋資料（標題、作者、摘要）。
  - 書目檔案（`references.bib`）與 CSL 樣式（`chicago-author-date.csl`）。
  - PDF 引擎（`xelatex`）與 LaTeX 標頭引入項目（`header-includes`）。
  - 交叉引用前綴（`figPrefix`、`tblPrefix`、`eqnPrefix`）與格式規範。
  - 章節編號（`numbersections: true`）、目錄（`toc`）與頁碼行為。
  - 完整書目收錄（`nocite: '@*'`）。
- 自動化引文與參考文獻格式化：文中引文使用 Pandoc 語法（例如 `[@key]`、`@key`、`[-@key]`），並在論文末尾解析為整齊的項目清單，列出完整作者姓名。
- 表格與交叉引用：語意標籤（例如 `{#tbl:workbench}`、`{#fig:my-plot}`、`{#eq:relativity}`）搭配 `pandoc-crossref`，實現自動編號與內部引用（如 `@tbl:workbench`）。
- 使用 Mermaid 進行程式化繪圖：直接在 `paper.md` 中撰寫的流程圖會自動渲染為清晰的 3 倍解析度圖片，並在 Pandoc 編譯前進行替換。
- 多語言排版：使用 XeLaTeX 與 CJK 字型設定（`Noto Sans CJK TC` / `PingFang SC`），支援高品質繁體中文與英文並陳排版。
- 自訂外觀與範本：將 Pandoc 銜接至 LaTeX 範本（如 Eisvogel），完全透過 YAML 進行深度版面自訂。
- 專用封面頁與文件封裝：`cover_page.tex` 提供專用封面頁，使用 XeLaTeX 編譯後，透過 `./devops.sh printed` 與主論文合併為 `printed.pdf`。
- 動態日期注入：日期在建置時自動注入，而非寫死在原始檔中：
  - 論文 PDF 使用 `YYYY-MM-DD` 格式的當前日期（透過 Pandoc 的 `-V date` 旗標注入）。
  - 封面 PDF 使用 `Month DD, YYYY` 格式的當前日期（透過 `tools/inject-date.sh` 注入）。
- AI 輔助寫作與自動化驗證：整合大型語言模型（LLM）進行草稿潤飾、引文稽核與結構感知自動翻譯（`./devops.sh translate`）。

### 專案結構

```
├── paper.md                    # 主要論文手稿（包含內嵌範例）
├── cover_page.tex              # 獨立 LaTeX 封面頁範本
├── references.bib              # BibTeX 格式的書目資料庫
├── chicago-author-date.csl     # CSL 樣式定義（Chicago author-date）
├── zh-tw.ini                   # 翻譯流程的單一設定檔
├── devops.sh                   # 主要建置與 Docker 協調整合指令碼（macOS/Linux/WSL）
├── devops.ps1                  # devops.sh 的 Windows PowerShell 包裝指令碼
├── Dockerfile                  # 擴充 pandocker 並預先安裝 jq、curl 與各項工具
├── images/
│   └── scholarship_logo.jpg    # 封面頁使用的高解析度向量校徽/標誌
└── tools/                      # 建置、字型偵測與翻譯輔助指令碼
    ├── detect-fonts.sh         # 偵測主機/容器中可用的 CJK 字型
    ├── inject-date.sh          # 將當前日期注入 cover_page.tex
    ├── merge-pdfs.sh           # 合併封面、行政表單與論文 PDF
    ├── process-mermaid.sh      # 透過 Puppeteer 擷取並渲染 Mermaid 程式碼區塊
    ├── translate.sh            # LLM 翻譯引擎（具結構感知能力）
    └── validate-and-fix-translated-md.sh # AI 語法驗證與修復指令碼
```

### 工具鏈需求

本專案使用 **Docker** 提供一致且可重現的建置環境。所有工具鏈均在容器內運行，其中包含：

- Pandoc（內建 `--citeproc`）與 `pandoc-crossref` 過濾器
- 包含 XeLaTeX 與標準套件的 LaTeX 發行版（TeX Live）
- 包含無頭 Chromium / Puppeteer 的 Mermaid CLI（`mmdc`），用於圖表編譯
- 所有必要的 CJK 字型與相依套件

**先決條件** ：

- 系統中已安裝並正在執行 **Docker**
- `PATH` 中可使用 **bash** （Windows 上需有 Git for Windows / WSL）— `devops.ps1` 會調用 `devops.sh`
- 用於版本控制的 **純文字編輯器** 與 **Git**

### 快速入門

使用本框架撰寫論文非常直接且直覺：

1. 撰寫論文內文：開啟 `paper.md`，在頂部 YAML 標頭下方找到內文區段，使用標準 Markdown 語法開始撰寫論文內容。執行 `./devops.sh pdf`（Windows 則執行 `./devops.ps1 pdf`）編譯並預覽產生的 PDF，確認排版與內容無誤。
2. 插入與交叉引用圖片：將圖片檔案放入 `images/`（或直接撰寫 Mermaid 圖表程式碼區塊），並參考 `paper.md` 自身的語法範例（如 `![說明](images/foo.png){#fig:foo}` 與 `@fig:foo`）進行插入與引用。
3. 加入引文與文獻：將書目資料加入至 `references.bib`（可手動維護或由 Zotero + BBT 匯出），並依照 `paper.md` 中的範例在文中以 `[@key]` 語法進行引用。
4. 交由框架處理其餘排版：熟悉上述最常見的論文寫作步驟後，其餘學術排版細節均由框架自動完成，包含章節標題自動編號、圖表標籤與交叉引用、腳註、頁碼以及參考文獻清單產生等。

### 基本用法：建置範例 PDF

所有建置、翻譯與工具操作均由單一的 **開發營運中心（Development Operations Center）** 指令碼驅動：

- Linux/macOS/WSL：`./devops.sh <operation>`
- Windows PowerShell：`./devops.ps1 <operation>`（轉發至 `bash ./devops.sh` — 需要 Git Bash 或 WSL）

```bash
# Linux/macOS/WSL
./devops.sh pdf

# Windows PowerShell
./devops.ps1 pdf
```

執行操作時將會：

1. 檢查基礎映像檔 `dalibo/pandocker:latest-full` 並在需要時拉取。
2. 若尚未存在，則根據 `Dockerfile` 建置衍生映像檔 `pandocker-with-tools:latest`（已預先安裝 `jq` 與 `curl`）。
3. 在臨時容器中執行請求的操作，並將當前目錄掛載至 `/workspace`。
4. 操作完成後自動移除容器。

**備註** ：初次執行時會建置衍生映像檔，可能需要幾分鐘時間。後續執行將重複使用快取的映像檔。

執行 `./devops.sh help`（或 `./devops.ps1 help`）可檢視所有可用操作：

| 操作 | 說明 |
| --- | --- |
| `pdf` | 建置主論文 PDF（`paper.pdf`） |
| `pdf_date` | 建置帶有 `YYYYMMDD` 日期後綴的論文 PDF |
| `cover` | 建置獨立封面頁 PDF（`cover.pdf`） |
| `printed` | 建置印刷版本（合併封面與論文） |
| `translate [step] [-f]` | 執行翻譯工作流程（預設跳過已存在檔案以節省 Token，使用 `--force` 強制重新翻譯） |
| `set-api-key [key]` | 將 Gemini API 金鑰安全儲存至作業系統憑證管理員 |
| `get-api-key` | 檢查作業系統憑證管理員中的 Gemini API 金鑰設定狀態 |
| `delete-api-key` | 從作業系統憑證管理員移除 Gemini API 金鑰 |
| `tags` | 從所有 Markdown 檔案產生 `.tags` |
| `ref-list` | 從 PDF 擷取參考文獻清單至剪貼簿 |
| `toc-list` | 從 PDF 擷取目錄至剪貼簿 |
| `clean` | 清除所有產生的中繼檔案與 PDF 檔案 |
| `deps` | 顯示本機（非 Docker）相依性套件資訊 |
| `env` | 檢查環境並引導安裝所需工具鏈與 Docker |

### 選用功能：翻譯至其他語言（`translate` 目標）

本專案展示如何利用由 `devops.sh` 全程驅動的 LLM 輔助翻譯工作流程，為任何目標語言產生論文與封面頁的翻譯版本。

- 原始來源：位於 `paper.md` 的原始英文手稿與位於 `cover_page.tex` 的封面頁。
- 設定：翻譯目標定義於專案根目錄的單一 INI 設定檔 `zh-tw.ini` 中（來源/目標語言名稱、輸出目錄、LLM 模型以及選用的 pandoc-crossref 標籤覆寫）。
- LLM 翻譯與快取機制：`./devops.sh translate` 會呼叫 `tools/translate.sh`，使用安全儲存於原生作業系統憑證管理員（macOS 鑰匙圈、Windows 認證管理員或 Linux Secret Service，可透過 `./devops.sh set-api-key` 設定）或 `GEMINI_API_KEY` 環境變數中的 API 金鑰調用大型語言模型（預設為 `gemini-2.5-flash`，可在 `zh-tw.ini` 中設定）。若目標目錄中已存在翻譯檔案（`paper.md`、`cover_page.tex`），系統會自動跳過 LLM 翻譯以節省 API Token 費用並避免覆寫手動潤飾的內容（使用 `--force` 或 `-f` 可強制重新翻譯）。
- AI 驅動驗證：初步翻譯完成後，`tools/validate-and-fix-translated-md.sh` 會自動檢查翻譯後的 Markdown 是否有格式錯誤（格式不良的表格、損毀的語法、異常的 YAML），並在保留翻譯內容的同時進行修復。
- 後處理與排版：附加腳本會修正字型與 crossref 標籤，隨後 Pandoc 與 XeLaTeX 會將翻譯後的原始檔編譯為排版完整的 PDF 與封面頁。

```bash
./devops.sh translate                # 執行翻譯流程（若已有翻譯檔則重用並直接編譯 PDF，節省 Token）
./devops.sh translate --force        # 強制整份重新呼叫 LLM 翻譯並重新建置
./devops.sh translate pdf            # 僅重新建置翻譯後的論文 PDF（重跑單一步驟）
```

`step` 可以是 `all`（預設）、`markdown`、`cover`、`pdf`、`cover_pdf` 或 `printed`。選用參數 `--force`（或 `-f`）可強制重新執行 LLM 翻譯。

產生的檔案將寫入所設定的 `DIR`（例如 `translated-zh-tw/`），其結構與原始英文流程相同。

### 工作流程概念概述

- 輸入層：`paper.md`（手稿）+ BibTeX 書目檔案（`references.bib`）+ CSL 樣式 + `cover_page.tex`。
- 處理層：
  - `tools/process-mermaid.sh` 將 Mermaid 圖表渲染為高解析度 PNG。
  - Pandoc 解析 Markdown 與 YAML 詮釋資料。
  - `--citeproc` 解析引文並格式化項目符號參考文獻清單。
  - `pandoc-crossref` 解析編號與交叉引用。
  - Pandoc 產生 LaTeX，並由 XeLaTeX 進行編譯。
  - `tools/merge-pdfs.sh` 將封面頁與論文手稿融合成 `printed.pdf`。
- 輸出層：適合機構典藏與學術發表的完整排版 PDF 套件。
