# Remarcademic (Researcher's Markdown Academic) Writing Framework

這是一個基於 **Markdown**、**Pandoc** 與 **LaTeX** 的現代學術寫作框架。旨在分離內容與呈現，並透過 Docker 提供完全可重複產生的建置環境。

## 專案概觀

- **核心目標**：建立可持續的學術寫作工作流，支援多語言（英文與繁體中文）、自動化引用、圖表交叉引用及 Mermaid 圖示。
- **主要技術棧**：
  - **Pandoc**: 文件轉換核心，處理 Markdown、YAML 元數據、引用與交叉引用。
  - **LaTeX (XeLaTeX)**：排版引擎，支援進階佈局與中文字型。
  - **Docker**：提供一致的建置環境 (`dalibo/pandocker`)。
  - **LLM (Gemini)**：用於自動化翻譯（英翻繁中）與 Markdown 格式驗證。
  - **Zotero + Better BibTeX**：管理書目數據。

## 目錄結構與關鍵檔案

- `paper.md`: **單一事實來源**。主要的英文手稿，包含控制整份文件排版與配置的 YAML Header。
- `devops.sh` / `devops.ps1`: 統一的開發運維腳本，負責 Docker 映像檔管理與建置流程。
- `AGENTS.md`: **AI 代理指令規範**。定義了在修改此專案時必須遵守的約束與慣例。
- `tools/`: 各種輔助腳本（翻譯、字型檢測、Mermaid 處理、PDF 合併等）。
- `solutions/paddlepaddle/`: 補充技術組件，用於文件版面分割與內容描述。
- `images/`: 存放論文圖表，包括自動產生的 Mermaid PNG。
- `zh_tw/`: 自動產生的繁體中文翻譯版本（手稿、封面、PDF）。

## 建置與執行

所有建置作業應透過 `./devops.sh`（Linux/macOS）或 `./devops.ps1`（Windows）執行，這將確保指令在 Docker 容器內運行。

| 指令 | 說明 |
| :--- | :--- |
| `./devops.sh` | 預設建置完整版本（封面 + 論文）。 |
| `./devops.sh pdf` | 僅建置主論文 PDF。 |
| `./devops.sh cover` | 僅建置封面 PDF。 |
| `./devops.sh printed` | 建置合併封面、審查確認單與論文的最終版本。 |
| `./devops.sh zh_tw` | 執行完整的繁體中文翻譯與建置流程（需 `.api_key`）。 |
| `./devops.sh ref-list` | 提取 PDF 最後的參考文獻清單並複製到剪貼簿。 |
| `./devops.sh toc-list` | 提取 PDF 最後的目錄清單並複製到剪貼簿。 |
| `./devops.sh clean` | 清除所有產生的臨時檔案與 PDF。 |

## 開發與 AI 代理規範

在協助開發或修改此專案時，請嚴格遵守 `AGENTS.md` 中的規定：

- **YAML 配置優先**：除非明確要求，否則不要更改 `paper.md` 的 YAML 結構，它是文件的配置核心。
- **Docker 環境**：所有腳本必須能在 `pandocker-with-tools` 容器（基於 Linux）中執行。
- **秘密管理**：絕不硬編碼或洩漏 `.api_key` 中的金鑰。
- **提交訊息**：使用**雙語（英文 + 繁體中文）**，並採用結構化的列表格式。
- **翻譯驗證**：修改翻譯腳本時，確保 `tools/validate-and-fix-translated-md.sh` 仍能有效修復格式錯誤。

## 特色工作流

- **Mermaid 支援**：在 Markdown 中使用 `mermaid` 代碼塊，建置時會自動轉換為高品質 PNG。
- **自動化日期注入**：封面與論文的日期在建置時動態注入，無需手動更新。
- **交叉引用**：使用 `pandoc-crossref` 語法（如 `{#fig:id}` 和 `@fig:id`）自動處理圖表編號。
