# Define file names
PDF = paper.pdf
SRC = paper.md
BIB = references.json
CSL = chicago-author-date.csl
COVER_TEX = ntust_cover_page.tex
COVER_PDF = cover.pdf
PRINTED_PDF = printed.pdf
LOGO_FILE = ntust_logo.jpg
LOGO_URL = https://emrd.ntust.edu.tw/var/file/39/1039/img/2483/LOGO.jpg
TEMP_SRC = paper.tmp.md
COVER_TEMP_TEX = ntust_cover_page.tmp.tex

# Translation variables
LLM_MODEL = gemini-2.5-flash
API_KEY_FILE = .api_key
ZH_TW_DIR = zh_tw
ZH_TW_SRC = $(ZH_TW_DIR)/paper.md
ZH_TW_COVER = $(ZH_TW_DIR)/ntust_cover_page.tex
ZH_TW_PDF = $(ZH_TW_DIR)/paper.pdf
ZH_TW_COVER_PDF = $(ZH_TW_DIR)/cover.pdf

# Make 'printed' the default goal
.DEFAULT_GOAL := printed

# Detect OS and set fonts accordingly
# First check if we're on Windows (via environment variables, uname, or cmd.exe)
UNAME_S := $(shell uname -s 2>/dev/null || echo "Unknown")
# Check for Windows: uname contains "NT", or Windows env vars exist, or cmd.exe is available
IS_WINDOWS := $(shell if echo "$(UNAME_S)" | grep -qi "NT\|MINGW\|MSYS"; then echo "1"; elif [ -n "$$OS" ] && echo "$$OS" | grep -qi "windows"; then echo "1"; elif [ -n "$$COMSPEC" ] || [ -n "$$WINDIR" ]; then echo "1"; elif command -v cmd.exe >/dev/null 2>&1 || command -v cmd >/dev/null 2>&1; then echo "1"; else echo "0"; fi)

ifeq ($(IS_WINDOWS),1)
	OS_TYPE := Windows
	FONT_DETECT_SCRIPT := tools/detect-fonts-windows.ps1
	TRANSLATE_SCRIPT := tools/translate-windows.ps1
else ifeq ($(UNAME_S),Darwin)
	OS_TYPE := Darwin
	FONT_DETECT_SCRIPT := tools/detect-fonts-darwin.sh
	TRANSLATE_SCRIPT := tools/translate-darwin.sh
else ifeq ($(UNAME_S),Linux)
	OS_TYPE := Linux
	FONT_DETECT_SCRIPT := tools/detect-fonts-linux.sh
	TRANSLATE_SCRIPT := tools/translate-linux.sh
else
	OS_TYPE := Unix
	FONT_DETECT_SCRIPT := tools/detect-fonts-linux.sh
	TRANSLATE_SCRIPT := tools/translate-linux.sh
endif

# Detect fonts using OS-specific script
ifeq ($(IS_WINDOWS),1)
	CJK_FONT_SC := $(shell powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$(FONT_DETECT_SCRIPT)'" 2>/dev/null | grep "^CJK_FONT_SC=" | cut -d= -f2)
	CJK_FONT_TC := $(shell powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$(FONT_DETECT_SCRIPT)'" 2>/dev/null | grep "^CJK_FONT_TC=" | cut -d= -f2)
	MAIN_FONT := $(shell powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$(FONT_DETECT_SCRIPT)'" 2>/dev/null | grep "^MAIN_FONT=" | cut -d= -f2)
else
	CJK_FONT_SC := $(shell bash $(FONT_DETECT_SCRIPT) 2>/dev/null | grep "^CJK_FONT_SC=" | cut -d= -f2)
	CJK_FONT_TC := $(shell bash $(FONT_DETECT_SCRIPT) 2>/dev/null | grep "^CJK_FONT_TC=" | cut -d= -f2)
	MAIN_FONT := $(shell bash $(FONT_DETECT_SCRIPT) 2>/dev/null | grep "^MAIN_FONT=" | cut -d= -f2)
endif

# Fallback values if script fails
ifeq ($(CJK_FONT_SC),)
	CJK_FONT_SC := AR PL UMing CN
endif
ifeq ($(CJK_FONT_TC),)
	CJK_FONT_TC := AR PL UMing TW
endif
ifeq ($(MAIN_FONT),)
	ifeq ($(OS_TYPE),Windows)
		MAIN_FONT := Times New Roman
	else ifeq ($(OS_TYPE),Darwin)
		MAIN_FONT := Times New Roman
	else
		MAIN_FONT := Liberation Serif
	endif
endif

# The Pandoc command with all filters and options
# Note: This assumes you have downloaded a CSL file and named it chicago-author-date.csl
# You can get it from the Zotero Style Repository.
PANDOC_CMD = pandoc $(TEMP_SRC) \
	--standalone \
	--filter pandoc-crossref \
	--citeproc \
	--pdf-engine=xelatex \
	-o $(PDF)

# Build main paper PDF via Pandoc
pdf: $(PDF)

$(PDF): $(SRC) $(BIB) $(CSL)
	@echo "Detected OS: $(OS_TYPE), using CJK font: $(CJK_FONT_SC)"
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "(Get-Content '$(SRC)') -replace 'PingFang SC', '$(CJK_FONT_SC)' | Set-Content '$(TEMP_SRC)'"
else
	@sed -e 's/PingFang SC/$(CJK_FONT_SC)/g' $(SRC) > $(TEMP_SRC)
endif
	@pandoc $(TEMP_SRC) --standalone --filter pandoc-crossref --citeproc -o paper.tex
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "(Get-Content paper.tex) -replace '}\\% \\AtEndEnvironment{CSLReferences}', '}`n\AtEndEnvironment{CSLReferences}' | Set-Content paper.tex"
else
	@sed -i.bak 's/}\\% \\AtEndEnvironment{CSLReferences}/}\n\\AtEndEnvironment{CSLReferences}/' paper.tex && rm -f paper.tex.bak
endif
	@xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@if [ -f paper.pdf ]; then mv paper.pdf $(PDF); else exit 1; fi
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "Remove-Item -Force '$(TEMP_SRC)' -ErrorAction SilentlyContinue"
else
	@rm -f $(TEMP_SRC)
endif

# Build the cover page (XeLaTeX)
cover: $(COVER_PDF)

$(COVER_PDF): $(COVER_TEX) $(LOGO_FILE)
	@echo "Detected OS: $(OS_TYPE), using main font: $(MAIN_FONT), CJK font: $(CJK_FONT_TC)"
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "(Get-Content '$(COVER_TEX)') -replace 'Times New Roman', '$(MAIN_FONT)' -replace 'PingFang TC', '$(CJK_FONT_TC)' | Set-Content '$(COVER_TEMP_TEX)'"
else
	@sed -e 's/Times New Roman/$(MAIN_FONT)/g' -e 's/PingFang TC/$(CJK_FONT_TC)/g' $(COVER_TEX) > $(COVER_TEMP_TEX)
endif
	@xelatex -interaction=nonstopmode -jobname=cover $(COVER_TEMP_TEX)
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "Remove-Item -Force '$(COVER_TEMP_TEX)' -ErrorAction SilentlyContinue"
else
	@rm -f $(COVER_TEMP_TEX)
endif

# Download NTUST logo if missing
$(LOGO_FILE):
	@echo "Fetching NTUST logo..."
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File tools/download-logo-windows.ps1 -LogoFile $(LOGO_FILE) -LogoUrl $(LOGO_URL)
else ifeq ($(OS_TYPE),Darwin)
	@bash tools/download-logo-darwin.sh $(LOGO_FILE) $(LOGO_URL)
else ifeq ($(OS_TYPE),Linux)
	@bash tools/download-logo-linux.sh $(LOGO_FILE) $(LOGO_URL)
else
	@echo "Unsupported OS for logo download. Please download manually from $(LOGO_URL)" >&2
	@exit 1
endif

# Optionally create a single PDF with the cover in front (requires pdfunite from poppler)
$(PRINTED_PDF): $(COVER_PDF) $(PDF)
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File tools/merge-pdfs-windows.ps1 -CoverPdf $(COVER_PDF) -PaperPdf $(PDF) -Output $(PRINTED_PDF)
else ifeq ($(OS_TYPE),Darwin)
	@bash tools/merge-pdfs-darwin.sh $(COVER_PDF) $(PDF) $(PRINTED_PDF)
else ifeq ($(OS_TYPE),Linux)
	@bash tools/merge-pdfs-linux.sh $(COVER_PDF) $(PDF) $(PRINTED_PDF)
else
	@echo "Unsupported OS for PDF merging." >&2
	@exit 1
endif

printed: $(PRINTED_PDF)
	@true

# Translate to Traditional Chinese and build PDFs
zh_tw: $(ZH_TW_PDF) $(ZH_TW_COVER_PDF)
	@echo "Translation to Traditional Chinese completed. PDFs generated in $(ZH_TW_DIR)/"
	@echo "Updating progress tracking..."
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "$$content = Get-Content 'plans/make_translation_target.md' -ErrorAction SilentlyContinue -Raw; if ($$content) { $$content -replace 'Status:.*', 'Status: ✅ Completed' | Set-Content 'plans/make_translation_target.md' }"
else
	@if [ -f plans/make_translation_target.md ]; then sed -i.bak 's/Status:.*/Status: ✅ Completed/' plans/make_translation_target.md && rm -f plans/make_translation_target.md.bak; fi
endif

# Build PDF from translated markdown
$(ZH_TW_PDF): $(ZH_TW_SRC) $(BIB) $(CSL)
	@echo "Building PDF from translated markdown..."
	@echo "Detected OS: $(OS_TYPE), using CJK font: $(CJK_FONT_TC)"
	@cd $(ZH_TW_DIR) && if [ ! -f $(BIB) ]; then ln -sf ../$(BIB) .; fi
	@cd $(ZH_TW_DIR) && if [ ! -f $(CSL) ]; then ln -sf ../$(CSL) .; fi
	@cd $(ZH_TW_DIR) && if [ ! -f "Graduate Paper.json" ]; then ln -sf ../"Graduate Paper.json" . 2>/dev/null || true; fi
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "$$content = Get-Content '$(ZH_TW_SRC)' -Raw; $$content = $$content -replace 'PingFang SC', '$(CJK_FONT_TC)'; Set-Content -Path '$(ZH_TW_DIR)/paper.tmp.md' -Value $$content"
	@cd $(ZH_TW_DIR) && pandoc paper.tmp.md --standalone --filter pandoc-crossref --citeproc -o paper.tex
	@powershell -NoProfile -Command "$$content = Get-Content '$(ZH_TW_DIR)/paper.tex' -Raw; $$content = $$content -replace '}\\% \\AtEndEnvironment{CSLReferences}', '}`n\AtEndEnvironment{CSLReferences}'; Set-Content -Path '$(ZH_TW_DIR)/paper.tex' -Value $$content"
else
	@sed -e 's/PingFang SC/$(CJK_FONT_TC)/g' $(ZH_TW_SRC) > $(ZH_TW_DIR)/paper.tmp.md
	@cd $(ZH_TW_DIR) && pandoc paper.tmp.md --standalone --filter pandoc-crossref --citeproc -o paper.tex
	@sed -i.bak 's/}\\% \\AtEndEnvironment{CSLReferences}/}\n\\AtEndEnvironment{CSLReferences}/' $(ZH_TW_DIR)/paper.tex && rm -f $(ZH_TW_DIR)/paper.tex.bak
endif
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@if [ -f $(ZH_TW_DIR)/paper.pdf ]; then mv $(ZH_TW_DIR)/paper.pdf $(ZH_TW_PDF); else exit 1; fi
	@rm -f $(ZH_TW_DIR)/paper.tmp.md $(ZH_TW_DIR)/paper.tex $(ZH_TW_DIR)/paper.aux $(ZH_TW_DIR)/paper.log
	@rm -f $(ZH_TW_SRC)
	@echo "Cleaned up intermediate translation files"

# Build cover PDF from translated LaTeX
$(ZH_TW_COVER_PDF): $(ZH_TW_COVER) $(LOGO_FILE)
	@echo "Building cover PDF from translated LaTeX..."
	@echo "Detected OS: $(OS_TYPE), using main font: $(MAIN_FONT), CJK font: $(CJK_FONT_TC)"
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "if (-not (Test-Path '$(ZH_TW_DIR)/$(LOGO_FILE)')) { Copy-Item '$(LOGO_FILE)' '$(ZH_TW_DIR)/$(LOGO_FILE)' -ErrorAction SilentlyContinue }"
else
	@cd $(ZH_TW_DIR) && if [ ! -f $(LOGO_FILE) ]; then ln -sf ../$(LOGO_FILE) . 2>/dev/null || cp ../$(LOGO_FILE) . 2>/dev/null || true; fi
endif
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "$$content = Get-Content '$(ZH_TW_COVER)' -Raw; $$content = $$content -replace 'Times New Roman', '$(MAIN_FONT)' -replace 'PingFang TC', '$(CJK_FONT_TC)'; Set-Content -Path '$(ZH_TW_DIR)/ntust_cover_page.tmp.tex' -Value $$content"
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode -jobname=cover ntust_cover_page.tmp.tex
	@powershell -NoProfile -Command "Remove-Item -Force '$(ZH_TW_DIR)/ntust_cover_page.tmp.tex' -ErrorAction SilentlyContinue"
else
	@sed -e 's/Times New Roman/$(MAIN_FONT)/g' -e 's/PingFang TC/$(CJK_FONT_TC)/g' $(ZH_TW_COVER) > $(ZH_TW_DIR)/ntust_cover_page.tmp.tex
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode -jobname=cover ntust_cover_page.tmp.tex
	@rm -f $(ZH_TW_DIR)/ntust_cover_page.tmp.tex
endif
	@rm -f $(ZH_TW_DIR)/cover.aux $(ZH_TW_DIR)/cover.log
	@rm -f $(ZH_TW_COVER)
	@echo "Cleaned up intermediate translation files"

# Translate markdown file
$(ZH_TW_SRC): $(SRC)
	@echo "Translating $(SRC) to Traditional Chinese..."
	@mkdir -p $(ZH_TW_DIR)
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(TRANSLATE_SCRIPT) -InputFile $(SRC) -OutputFile $(ZH_TW_SRC) -SourceLang "English" -TargetLang "Traditional Chinese" -Model $(LLM_MODEL) -ApiKeyFile $(API_KEY_FILE)
else
	@bash $(TRANSLATE_SCRIPT) $(SRC) $(ZH_TW_SRC) "English" "Traditional Chinese" $(LLM_MODEL) $(API_KEY_FILE)
endif
	@echo "Post-processing translated markdown..."
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "$$content = Get-Content '$(ZH_TW_SRC)' -Raw; $$content = $$content -replace 'CJKmainfont: \"PingFang SC\"', 'CJKmainfont: \"$(CJK_FONT_TC)\"'; $$content = $$content -replace 'setCJKmainfont\{PingFang SC\}', 'setCJKmainfont{$(CJK_FONT_TC)}'; $$content = $$content -replace '\"Figure\"', '\"圖\"'; $$content = $$content -replace '\"Figures\"', '\"圖\"'; $$content = $$content -replace '\"Tab\.\"', '\"表\"'; $$lines = $$content -split \"`r?`n\"; $$inMultiline = $$false; for ($$i = 0; $$i -lt $$lines.Length; $$i++) { if ($$lines[$$i] -match '^- \|$$') { $$inMultiline = $$true; } elseif ($$inMultiline -and $$lines[$$i] -match '^\\usepackage\{etoolbox\}') { $$lines[$$i] = '    ' + $$lines[$$i]; } elseif ($$inMultiline -and $$lines[$$i] -match '^\\AtBeginEnvironment\{CSLReferences\}') { $$lines[$$i] = '    ' + $$lines[$$i]; } elseif ($$inMultiline -and $$lines[$$i] -match '^\\newpage\\section\*\{References\}') { $$lines[$$i] = '      ' + $$lines[$$i]; } elseif ($$inMultiline -and $$lines[$$i] -match '^\\setlength\{') { $$lines[$$i] = '      ' + $$lines[$$i]; } elseif ($$inMultiline -and $$lines[$$i] -match '^\}$$') { $$lines[$$i] = '    ' + $$lines[$$i]; $$inMultiline = $$false; } }; $$content = $$lines -join \"`r`n\"; Set-Content -Path '$(ZH_TW_SRC)' -Value $$content"
else
	@sed -i.bak -e 's/CJKmainfont: "PingFang SC"/CJKmainfont: "$(CJK_FONT_TC)"/' \
		-e 's/setCJKmainfont{PingFang SC}/setCJKmainfont{$(CJK_FONT_TC)}/' \
		-e 's/"Figure"/"圖"/' \
		-e 's/"Figures"/"圖"/' \
		-e 's/"Tab\."/"表"/' \
		$(ZH_TW_SRC) && rm -f $(ZH_TW_SRC).bak
	@python3 -c "import sys; \
content = open('$(ZH_TW_SRC)', 'r', encoding='utf-8').read(); \
lines = content.split('\n'); \
in_block = False; \
result = []; \
for line in lines: \
    if line.rstrip() == '- |': \
        in_block = True; \
        result.append(line); \
    elif in_block and line.startswith('\\usepackage{etoolbox}'): \
        result.append('    ' + line); \
    elif in_block and line.startswith('\\AtBeginEnvironment{CSLReferences}'): \
        result.append('    ' + line); \
    elif in_block and line.startswith('\\newpage\\section*{References}'): \
        result.append('      ' + line); \
    elif in_block and line.startswith('\\setlength{'): \
        result.append('      ' + line); \
    elif in_block and line.rstrip() == '}': \
        result.append('    ' + line); \
        in_block = False; \
    else: \
        result.append(line); \
open('$(ZH_TW_SRC)', 'w', encoding='utf-8').write('\n'.join(result));"
endif

# Translate cover LaTeX file
$(ZH_TW_COVER): $(COVER_TEX)
	@echo "Translating $(COVER_TEX) to Traditional Chinese..."
	@mkdir -p $(ZH_TW_DIR)
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(TRANSLATE_SCRIPT) -InputFile $(COVER_TEX) -OutputFile $(ZH_TW_COVER) -SourceLang "English" -TargetLang "Traditional Chinese" -Model $(LLM_MODEL) -ApiKeyFile $(API_KEY_FILE)
else
	@bash $(TRANSLATE_SCRIPT) $(COVER_TEX) $(ZH_TW_COVER) "English" "Traditional Chinese" $(LLM_MODEL) $(API_KEY_FILE)
endif
	@echo "Post-processing translated LaTeX..."
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -Command "$$content = Get-Content '$(ZH_TW_COVER)' -Raw; $$content = $$content -replace 'PingFang TC', '$(CJK_FONT_TC)'; Set-Content -Path '$(ZH_TW_COVER)' -Value $$content"
else
	@sed -i.bak -e 's/PingFang TC/$(CJK_FONT_TC)/g' $(ZH_TW_COVER) && rm -f $(ZH_TW_COVER).bak
endif

# Install required external tools (auto-detects OS)
deps:
	@echo "Detected OS: $(OS_TYPE)"
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File tools/deps-windows.ps1
else ifeq ($(OS_TYPE),Darwin)
	@bash tools/deps-darwin.sh
else ifeq ($(OS_TYPE),Linux)
	@bash tools/deps-linux.sh
else
	@echo "Unsupported OS: $(OS_TYPE)" >&2
	@exit 1
endif

# A clean rule to remove the generated file
clean:
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File tools/clean-windows.ps1 -Pdf $(PDF) -CoverPdf $(COVER_PDF) -PrintedPdf $(PRINTED_PDF) -TempSrc $(TEMP_SRC) -CoverTempTex $(COVER_TEMP_TEX)
else ifeq ($(OS_TYPE),Darwin)
	@bash tools/clean-darwin.sh $(PDF) $(COVER_PDF) $(PRINTED_PDF) $(TEMP_SRC) $(COVER_TEMP_TEX)
else ifeq ($(OS_TYPE),Linux)
	@bash tools/clean-linux.sh $(PDF) $(COVER_PDF) $(PRINTED_PDF) $(TEMP_SRC) $(COVER_TEMP_TEX)
else
	@echo "Unsupported OS for clean: $(OS_TYPE)" >&2
	@exit 1
endif

# Declare targets that are not files
.PHONY: pdf cover printed deps clean zh_tw