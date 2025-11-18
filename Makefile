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
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	CJK_FONT_SC := PingFang SC
	CJK_FONT_TC := PingFang TC
	MAIN_FONT := Times New Roman
else ifeq ($(UNAME_S),Linux)
	MAIN_FONT := Liberation Serif
	# Try to detect available CJK fonts, prioritizing Noto (installed via deps_ubuntu)
	# Note: Run 'make deps_ubuntu' to install fonts-noto-cjk package
	# Check if Noto Sans CJK SC is available, fallback to commonly available fonts
	CJK_FONT_SC := $(shell fc-list 2>/dev/null | grep -i "Noto Sans CJK SC" | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
	ifeq ($(CJK_FONT_SC),)
		# Fallback: try to find any Simplified Chinese font
		CJK_FONT_SC := $(shell fc-list :lang=zh-cn 2>/dev/null | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
	endif
	ifeq ($(CJK_FONT_SC),)
		# Final fallback to commonly available font
		CJK_FONT_SC := AR PL UMing CN
	endif
	# Same for Traditional Chinese
	CJK_FONT_TC := $(shell fc-list 2>/dev/null | grep -i "Noto Sans CJK TC" | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
	ifeq ($(CJK_FONT_TC),)
		# Fallback: try to find any Traditional Chinese font
		CJK_FONT_TC := $(shell fc-list :lang=zh-tw 2>/dev/null | head -1 | cut -d: -f2 | cut -d, -f1 | xargs)
	endif
	ifeq ($(CJK_FONT_TC),)
		# Final fallback to commonly available font
		CJK_FONT_TC := AR PL UMing TW
	endif
else
	CJK_FONT_SC := AR PL UMing CN
	CJK_FONT_TC := AR PL UMing TW
	MAIN_FONT := Liberation Serif
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
	@echo "Detected OS: $(UNAME_S), using CJK font: $(CJK_FONT_SC)"
	@sed -e 's/PingFang SC/$(CJK_FONT_SC)/g' $(SRC) > $(TEMP_SRC)
	@$(PANDOC_CMD)
	@rm -f $(TEMP_SRC)

# Build the cover page (XeLaTeX)
cover: $(COVER_PDF)

$(COVER_PDF): $(COVER_TEX) $(LOGO_FILE)
	@echo "Detected OS: $(UNAME_S), using main font: $(MAIN_FONT), CJK font: $(CJK_FONT_TC)"
	@sed -e 's/Times New Roman/$(MAIN_FONT)/g' -e 's/PingFang TC/$(CJK_FONT_TC)/g' $(COVER_TEX) > $(COVER_TEMP_TEX)
	@xelatex -interaction=nonstopmode -jobname=cover $(COVER_TEMP_TEX)
	@rm -f $(COVER_TEMP_TEX)

# Download NTUST logo if missing
$(LOGO_FILE):
	@echo "Fetching NTUST logo..."
	@curl -fsSL -o $(LOGO_FILE) $(LOGO_URL)

# Optionally create a single PDF with the cover in front (requires pdfunite from poppler)
$(PRINTED_PDF): $(COVER_PDF) $(PDF)
	@if command -v pdfunite >/dev/null 2>&1; then \
		pdfunite $(COVER_PDF) $(PDF) $(PRINTED_PDF); \
		echo "Created $(PRINTED_PDF) (cover + paper) with pdfunite."; \
	elif command -v gs >/dev/null 2>&1; then \
		gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$(PRINTED_PDF) $(COVER_PDF) $(PDF); \
		echo "Created $(PRINTED_PDF) (cover + paper) with Ghostscript (gs)."; \
	else \
		echo "Neither pdfunite nor gs found. Install poppler (pdfunite) with 'brew install poppler'"; \
		echo "or Ghostscript with 'brew install ghostscript' to enable 'make printed'."; \
		exit 1; \
	fi

printed: $(PRINTED_PDF)
	@true

# Install required external tools (macOS Homebrew)
deps_macos:
	@echo "Installing required CLI tools with Homebrew (if missing)..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Homebrew not found. Install it from https://brew.sh and re-run 'make deps_macos'."; \
		exit 1; \
	fi
	@brew list --formula poppler >/dev/null 2>&1 || brew install poppler
	@brew list --formula ghostscript >/dev/null 2>&1 || brew install ghostscript
	@brew list --formula pandoc-crossref >/dev/null 2>&1 || brew install pandoc-crossref
	@echo "All dependencies are installed."

# Install required external tools (Ubuntu 20.04+)
deps_ubuntu:
	@echo "Installing required CLI tools with apt (if missing)..."
	@if ! command -v apt-get >/dev/null 2>&1; then \
		echo "apt-get not found. This target is for Ubuntu/Debian systems."; \
		exit 1; \
	fi
	@sudo apt-get update
	@dpkg -l | grep -q "^ii.*poppler-utils" || sudo apt-get install -y poppler-utils
	@dpkg -l | grep -q "^ii.*ghostscript" || sudo apt-get install -y ghostscript
	@dpkg -l | grep -q "^ii.*fonts-noto-cjk" || sudo apt-get install -y fonts-noto-cjk
	@dpkg -l | grep -q "^ii.*fonts-liberation" || sudo apt-get install -y fonts-liberation
	@if ! command -v pandoc-crossref >/dev/null 2>&1; then \
		if command -v cabal >/dev/null 2>&1; then \
			echo "Installing pandoc-crossref via cabal..."; \
			cabal update && cabal install pandoc-crossref; \
		else \
			echo "pandoc-crossref not found. Install it via:"; \
			echo "  sudo apt-get install -y cabal-install"; \
			echo "  cabal update && cabal install pandoc-crossref"; \
			echo "Or download a binary release from: https://github.com/lierdakil/pandoc-crossref/releases"; \
			exit 1; \
		fi; \
	else \
		PANDOC_VER=$$(pandoc --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""); \
		CROSSREF_VER=$$(pandoc-crossref --version 2>&1 | grep -oE 'Pandoc v[0-9]+\.[0-9]+\.[0-9]+' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo ""); \
		if [ -n "$$PANDOC_VER" ] && [ -n "$$CROSSREF_VER" ] && [ "$$PANDOC_VER" != "$$CROSSREF_VER" ]; then \
			echo "Warning: pandoc-crossref (built with pandoc $$CROSSREF_VER) doesn't match installed pandoc ($$PANDOC_VER)"; \
			echo "Reinstalling pandoc-crossref to match pandoc version..."; \
			if command -v cabal >/dev/null 2>&1; then \
				cabal update && cabal install pandoc-crossref; \
			else \
				echo "cabal not found. Please install cabal-install and reinstall pandoc-crossref:"; \
				echo "  sudo apt-get install -y cabal-install"; \
				echo "  cabal update && cabal install pandoc-crossref"; \
			fi; \
		fi; \
	fi
	@echo "All dependencies are installed."

# A clean rule to remove the generated file
clean:
	rm -f $(PDF)
	rm -f $(COVER_PDF) $(PRINTED_PDF)
	rm -f $(TEMP_SRC) $(COVER_TEMP_TEX)
	rm -f *.aux *.log *.out *.toc *.bbl *.blg *.bcf *.run.xml *.synctex.gz
	rm -f *.fdb_latexmk *.fls *.xdv *.nav *.snm *.vrb *.lof *.lot *.loa *.lol
	rm -rf _minted*
	@echo "Cleaned build outputs and LaTeX intermediates."

# Declare targets that are not files
.PHONY: pdf cover printed deps_macos deps_ubuntu clean