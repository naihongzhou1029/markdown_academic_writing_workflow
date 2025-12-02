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
# Prefer simple Make/Windows detection to avoid shell-specific logic.

# Default to "not Windows"; override below when we detect Windows.
IS_WINDOWS := 0

# On Windows with cmd/PowerShell, the standard env var is OS=Windows_NT.
ifeq ($(OS),Windows_NT)
	IS_WINDOWS := 1
	OS_TYPE := Windows
	FONT_DETECT_SCRIPT := tools/detect-fonts-windows.ps1
	TRANSLATE_SCRIPT := tools/translate-windows.ps1
	REPLACE_FONTS_SCRIPT := tools/replace-fonts-windows.ps1
	FIX_LATEX_CSL_SCRIPT := tools/fix-latex-csl-windows.ps1
	CREATE_SYMLINKS_SCRIPT := tools/create-symlinks-windows.ps1
	COPY_LOGO_SCRIPT := tools/copy-logo-windows.ps1
	POSTPROCESS_MD_SCRIPT := tools/postprocess-translated-md-windows.ps1
	POSTPROCESS_TEX_SCRIPT := tools/postprocess-translated-tex-windows.ps1
	CLEANUP_TEMP_SCRIPT := tools/cleanup-temp-windows.ps1
else
	# Non-Windows: we can safely call uname in a POSIX shell.
	UNAME_S := $(shell uname -s 2>/dev/null || echo "Unknown")

	ifeq ($(UNAME_S),Darwin)
		OS_TYPE := Darwin
		FONT_DETECT_SCRIPT := tools/detect-fonts-darwin.sh
		TRANSLATE_SCRIPT := tools/translate-darwin.sh
		REPLACE_FONTS_SCRIPT := tools/replace-fonts-darwin.sh
		FIX_LATEX_CSL_SCRIPT := tools/fix-latex-csl-darwin.sh
		CREATE_SYMLINKS_SCRIPT := tools/create-symlinks-darwin.sh
		COPY_LOGO_SCRIPT := tools/copy-logo-darwin.sh
		POSTPROCESS_MD_SCRIPT := tools/postprocess-translated-md-darwin.sh
		POSTPROCESS_TEX_SCRIPT := tools/postprocess-translated-tex-darwin.sh
		CLEANUP_TEMP_SCRIPT := tools/cleanup-temp-darwin.sh
	else ifeq ($(UNAME_S),Linux)
		OS_TYPE := Linux
		FONT_DETECT_SCRIPT := tools/detect-fonts-linux.sh
		TRANSLATE_SCRIPT := tools/translate-linux.sh
		REPLACE_FONTS_SCRIPT := tools/replace-fonts-linux.sh
		FIX_LATEX_CSL_SCRIPT := tools/fix-latex-csl-linux.sh
		CREATE_SYMLINKS_SCRIPT := tools/create-symlinks-linux.sh
		COPY_LOGO_SCRIPT := tools/copy-logo-linux.sh
		POSTPROCESS_MD_SCRIPT := tools/postprocess-translated-md-linux.sh
		POSTPROCESS_TEX_SCRIPT := tools/postprocess-translated-tex-linux.sh
		CLEANUP_TEMP_SCRIPT := tools/cleanup-temp-linux.sh
	else
		# Fallback for unknown Unix-like systems: reuse Linux tooling.
		OS_TYPE := Unix
		FONT_DETECT_SCRIPT := tools/detect-fonts-linux.sh
		TRANSLATE_SCRIPT := tools/translate-linux.sh
		REPLACE_FONTS_SCRIPT := tools/replace-fonts-linux.sh
		FIX_LATEX_CSL_SCRIPT := tools/fix-latex-csl-linux.sh
		CREATE_SYMLINKS_SCRIPT := tools/create-symlinks-linux.sh
		COPY_LOGO_SCRIPT := tools/copy-logo-linux.sh
		POSTPROCESS_MD_SCRIPT := tools/postprocess-translated-md-linux.sh
		POSTPROCESS_TEX_SCRIPT := tools/postprocess-translated-tex-linux.sh
		CLEANUP_TEMP_SCRIPT := tools/cleanup-temp-linux.sh
	endif
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

# Fallback values if detection script fails
ifeq ($(CJK_FONT_SC),)
	ifeq ($(OS_TYPE),Windows)
		# Common Simplified Chinese UI font on Windows
		CJK_FONT_SC := Microsoft YaHei
	else
		CJK_FONT_SC := AR PL UMing CN
	endif
endif
ifeq ($(CJK_FONT_TC),)
	ifeq ($(OS_TYPE),Windows)
		# Common Traditional Chinese UI font on Windows
		CJK_FONT_TC := Microsoft JhengHei
	else
		CJK_FONT_TC := AR PL UMing TW
	endif
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
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$(REPLACE_FONTS_SCRIPT)' -InputFile '$(SRC)' -OutputFile '$(TEMP_SRC)' -Replacements @('PingFang SC','$(CJK_FONT_SC)')"
else
	@bash $(REPLACE_FONTS_SCRIPT) $(SRC) $(TEMP_SRC) "PingFang SC" "$(CJK_FONT_SC)"
endif
	@pandoc $(TEMP_SRC) --standalone --filter pandoc-crossref --citeproc -o paper.tex
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(FIX_LATEX_CSL_SCRIPT) -LatexFile paper.tex
else
	@bash $(FIX_LATEX_CSL_SCRIPT) paper.tex
endif
	@xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@if [ -f paper.pdf ]; then \
		if [ "paper.pdf" != "$(PDF)" ]; then mv paper.pdf "$(PDF)"; fi; \
	else \
		exit 1; \
	fi
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(CLEANUP_TEMP_SCRIPT) -Files $(TEMP_SRC)
else
	@bash $(CLEANUP_TEMP_SCRIPT) $(TEMP_SRC)
endif

# Build the cover page (XeLaTeX)
cover: $(COVER_PDF)

$(COVER_PDF): $(COVER_TEX) $(LOGO_FILE)
	@echo "Detected OS: $(OS_TYPE), using main font: $(MAIN_FONT), CJK font: $(CJK_FONT_TC)"
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$(REPLACE_FONTS_SCRIPT)' -InputFile '$(COVER_TEX)' -OutputFile '$(COVER_TEMP_TEX)' -Replacements @('Times New Roman','$(MAIN_FONT)','PingFang TC','$(CJK_FONT_TC)')"
else
	@bash $(REPLACE_FONTS_SCRIPT) $(COVER_TEX) $(COVER_TEMP_TEX) "Times New Roman" "$(MAIN_FONT)" "PingFang TC" "$(CJK_FONT_TC)"
endif
	@xelatex -interaction=nonstopmode -jobname=cover $(COVER_TEMP_TEX)
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(CLEANUP_TEMP_SCRIPT) -Files $(COVER_TEMP_TEX)
else
	@bash $(CLEANUP_TEMP_SCRIPT) $(COVER_TEMP_TEX)
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
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(CREATE_SYMLINKS_SCRIPT) -TargetDir $(ZH_TW_DIR) -Files $(BIB) $(CSL) "Graduate Paper.json"
	@if (Test-Path images) { \
		if (Test-Path $(ZH_TW_DIR)/images) { Remove-Item -Recurse -Force $(ZH_TW_DIR)/images }; \
		cd $(ZH_TW_DIR); New-Item -ItemType SymbolicLink -Path images -Target ../images | Out-Null \
	}
else
	@bash $(CREATE_SYMLINKS_SCRIPT) $(ZH_TW_DIR) $(BIB) $(CSL) "Graduate Paper.json"
	@if [ -d images ]; then \
		if [ -e $(ZH_TW_DIR)/images ]; then rm -rf $(ZH_TW_DIR)/images; fi; \
		cd $(ZH_TW_DIR) && ln -sf ../images images; \
	fi
endif
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$(REPLACE_FONTS_SCRIPT)' -InputFile '$(ZH_TW_SRC)' -OutputFile '$(ZH_TW_DIR)/paper.tmp.md' -Replacements @('PingFang SC','$(CJK_FONT_TC)')"
else
	@bash $(REPLACE_FONTS_SCRIPT) $(ZH_TW_SRC) $(ZH_TW_DIR)/paper.tmp.md "PingFang SC" "$(CJK_FONT_TC)"
endif
	@cd $(ZH_TW_DIR) && pandoc paper.tmp.md --standalone --filter pandoc-crossref --citeproc -o paper.tex
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(FIX_LATEX_CSL_SCRIPT) -LatexFile $(ZH_TW_DIR)/paper.tex
else
	@bash $(FIX_LATEX_CSL_SCRIPT) $(ZH_TW_DIR)/paper.tex
endif
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@if [ -f $(ZH_TW_DIR)/paper.pdf ]; then mv $(ZH_TW_DIR)/paper.pdf $(ZH_TW_PDF); else exit 1; fi
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(CLEANUP_TEMP_SCRIPT) -Files $(ZH_TW_DIR)/paper.tmp.md $(ZH_TW_DIR)/paper.tex $(ZH_TW_DIR)/paper.aux $(ZH_TW_DIR)/paper.log $(ZH_TW_SRC)
else
	@bash $(CLEANUP_TEMP_SCRIPT) $(ZH_TW_DIR)/paper.tmp.md $(ZH_TW_DIR)/paper.tex $(ZH_TW_DIR)/paper.aux $(ZH_TW_DIR)/paper.log $(ZH_TW_SRC)
endif
	@echo "Cleaned up intermediate translation files"

# Build cover PDF from translated LaTeX
$(ZH_TW_COVER_PDF): $(ZH_TW_COVER) $(LOGO_FILE)
	@echo "Building cover PDF from translated LaTeX..."
	@echo "Detected OS: $(OS_TYPE), using main font: $(MAIN_FONT), CJK font: $(CJK_FONT_TC)"
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(COPY_LOGO_SCRIPT) -SourceLogo $(LOGO_FILE) -TargetDir $(ZH_TW_DIR)
else
	@bash $(COPY_LOGO_SCRIPT) $(LOGO_FILE) $(ZH_TW_DIR)
endif
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -Command "& '$(REPLACE_FONTS_SCRIPT)' -InputFile '$(ZH_TW_COVER)' -OutputFile '$(ZH_TW_DIR)/ntust_cover_page.tmp.tex' -Replacements @('Times New Roman','$(MAIN_FONT)','PingFang TC','$(CJK_FONT_TC)')"
else
	@bash $(REPLACE_FONTS_SCRIPT) $(ZH_TW_COVER) $(ZH_TW_DIR)/ntust_cover_page.tmp.tex "Times New Roman" "$(MAIN_FONT)" "PingFang TC" "$(CJK_FONT_TC)"
endif
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode -jobname=cover ntust_cover_page.tmp.tex
ifeq ($(IS_WINDOWS),1)
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(CLEANUP_TEMP_SCRIPT) -Files $(ZH_TW_DIR)/ntust_cover_page.tmp.tex $(ZH_TW_DIR)/cover.aux $(ZH_TW_DIR)/cover.log $(ZH_TW_COVER)
else
	@bash $(CLEANUP_TEMP_SCRIPT) $(ZH_TW_DIR)/ntust_cover_page.tmp.tex $(ZH_TW_DIR)/cover.aux $(ZH_TW_DIR)/cover.log $(ZH_TW_COVER)
endif
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
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(POSTPROCESS_MD_SCRIPT) -TranslatedMdFile $(ZH_TW_SRC) -CjkFont "$(CJK_FONT_TC)"
else
	@bash $(POSTPROCESS_MD_SCRIPT) $(ZH_TW_SRC) "$(CJK_FONT_TC)"
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
	@powershell -NoProfile -ExecutionPolicy Bypass -File $(POSTPROCESS_TEX_SCRIPT) -LatexFile $(ZH_TW_COVER) -OldFont "PingFang TC" -NewFont "$(CJK_FONT_TC)"
else
	@bash $(POSTPROCESS_TEX_SCRIPT) $(ZH_TW_COVER) "PingFang TC" "$(CJK_FONT_TC)"
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
	@if exist $(ZH_TW_DIR) powershell -NoProfile -Command "Remove-Item -Recurse -Force '$(ZH_TW_DIR)'" 2>nul || true
else ifeq ($(OS_TYPE),Darwin)
	@bash tools/clean-darwin.sh $(PDF) $(COVER_PDF) $(PRINTED_PDF) $(TEMP_SRC) $(COVER_TEMP_TEX)
	@rm -rf $(ZH_TW_DIR) 2>/dev/null || true
else ifeq ($(OS_TYPE),Linux)
	@bash tools/clean-linux.sh $(PDF) $(COVER_PDF) $(PRINTED_PDF) $(TEMP_SRC) $(COVER_TEMP_TEX)
	@rm -rf $(ZH_TW_DIR) 2>/dev/null || true
else
	@echo "Unsupported OS for clean: $(OS_TYPE)" >&2
	@exit 1
endif

# Declare targets that are not files
.PHONY: pdf cover printed deps clean zh_tw