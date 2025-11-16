# Define file names
PDF = paper.pdf
SRC = paper.md
BIB = references.json
CSL = chicago-author-date.csl
COVER_TEX = ntust_cover_page.tex
COVER_PDF = cover.pdf
THESIS_PDF = thesis.pdf
LOGO_FILE = ntust_logo.jpg
LOGO_URL = https://emrd.ntust.edu.tw/var/file/39/1039/img/2483/LOGO.jpg

# Make 'thesis' the default goal
.DEFAULT_GOAL := thesis

# The Pandoc command with all filters and options
# Note: This assumes you have downloaded a CSL file and named it chicago-author-date.csl
# You can get it from the Zotero Style Repository.
PANDOC_CMD = pandoc $(SRC) \
	--standalone \
	--filter pandoc-crossref \
	--citeproc \
	--pdf-engine=xelatex \
	-o $(PDF)

# Build main paper PDF via Pandoc
pdf: $(PDF)

$(PDF): $(SRC) $(BIB) $(CSL)
	$(PANDOC_CMD)

# Build the cover page (XeLaTeX)
cover: $(COVER_PDF)

$(COVER_PDF): $(COVER_TEX) $(LOGO_FILE)
	xelatex -interaction=nonstopmode -jobname=cover $(COVER_TEX)

# Download NTUST logo if missing
$(LOGO_FILE):
	@echo "Fetching NTUST logo..."
	@curl -fsSL -o $(LOGO_FILE) $(LOGO_URL)

# Optionally create a single PDF with the cover in front (requires pdfunite from poppler)
$(THESIS_PDF): $(COVER_PDF) $(PDF)
	@if command -v pdfunite >/dev/null 2>&1; then \
		pdfunite $(COVER_PDF) $(PDF) $(THESIS_PDF); \
		echo "Created $(THESIS_PDF) (cover + paper) with pdfunite."; \
	elif command -v gs >/dev/null 2>&1; then \
		gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$(THESIS_PDF) $(COVER_PDF) $(PDF); \
		echo "Created $(THESIS_PDF) (cover + paper) with Ghostscript (gs)."; \
	else \
		echo "Neither pdfunite nor gs found. Install poppler (pdfunite) with 'brew install poppler'"; \
		echo "or Ghostscript with 'brew install ghostscript' to enable 'make thesis'."; \
		exit 1; \
	fi

thesis: $(THESIS_PDF)
	@true

# Install required external tools (macOS Homebrew)
deps:
	@echo "Installing required CLI tools with Homebrew (if missing)..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Homebrew not found. Install it from https://brew.sh and re-run 'make deps'."; \
		exit 1; \
	fi
	@brew list --formula poppler >/dev/null 2>&1 || brew install poppler
	@brew list --formula ghostscript >/dev/null 2>&1 || brew install ghostscript
	@brew list --formula pandoc-crossref >/dev/null 2>&1 || brew install pandoc-crossref
	@echo "All dependencies are installed."

# A clean rule to remove the generated file
clean:
	rm -f $(PDF)
	rm -f $(COVER_PDF) thesis.pdf
	rm -f *.aux *.log *.out *.toc *.bbl *.blg *.bcf *.run.xml *.synctex.gz
	rm -f *.fdb_latexmk *.fls *.xdv *.nav *.snm *.vrb *.lof *.lot *.loa *.lol
	rm -rf _minted*
	@echo "Cleaned build outputs and LaTeX intermediates."

# Declare targets that are not files
.PHONY: pdf cover thesis deps clean