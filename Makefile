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
else ifeq ($(UNAME_S),Darwin)
	OS_TYPE := Darwin
	FONT_DETECT_SCRIPT := tools/detect-fonts-darwin.sh
else ifeq ($(UNAME_S),Linux)
	OS_TYPE := Linux
	FONT_DETECT_SCRIPT := tools/detect-fonts-linux.sh
else
	OS_TYPE := Unix
	FONT_DETECT_SCRIPT := tools/detect-fonts-linux.sh
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
.PHONY: pdf cover printed deps clean