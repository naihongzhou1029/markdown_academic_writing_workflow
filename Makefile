# Define file names
PDF = paper.pdf
SRC = paper.md
BIB = references.json
CSL = chicago-author-date.csl
COVER_TEX = cover_page.tex
COVER_PDF = cover.pdf
PRINTED_PDF = printed.pdf
LOGO_FILE = ntust_logo.jpg
LOGO_URL = https://emrd.ntust.edu.tw/var/file/39/1039/img/2483/LOGO.jpg
TEMP_SRC = paper.tmp.md
MERMAID_TEMP_SRC = paper.mermaid.tmp.md
COVER_TEMP_TEX = cover_page.tmp.tex

# Translation variables
LLM_MODEL = gemini-2.5-flash
API_KEY_FILE = .api_key
ZH_TW_DIR = zh_tw
ZH_TW_SRC = $(ZH_TW_DIR)/paper.md
ZH_TW_COVER = $(ZH_TW_DIR)/cover_page.tex
ZH_TW_PDF = $(ZH_TW_DIR)/paper.pdf
ZH_TW_COVER_PDF = $(ZH_TW_DIR)/cover.pdf
ZH_TW_PRINTED_PDF = $(ZH_TW_DIR)/printed.pdf

# Make 'printed' the default goal
.DEFAULT_GOAL := printed

# Script paths (all Linux scripts, works in Docker container)
FONT_DETECT_SCRIPT := tools/detect-fonts.sh
TRANSLATE_SCRIPT := tools/translate.sh
VALIDATE_TRANSLATED_MD_SCRIPT := tools/validate-and-fix-translated-md.sh
REPLACE_FONTS_SCRIPT := tools/replace-fonts.sh
FIX_LATEX_CSL_SCRIPT := tools/fix-latex-csl.sh
CREATE_SYMLINKS_SCRIPT := tools/create-symlinks.sh
COPY_LOGO_SCRIPT := tools/copy-logo.sh
POSTPROCESS_MD_SCRIPT := tools/postprocess-translated-md.sh
POSTPROCESS_TEX_SCRIPT := tools/postprocess-translated-tex.sh
CLEANUP_TEMP_SCRIPT := tools/cleanup-temp.sh
PROCESS_MERMAID_SCRIPT := tools/process-mermaid.sh

# Detect fonts using Linux script (works in Docker container)
CJK_FONT_SC := $(shell bash $(FONT_DETECT_SCRIPT) 2>/dev/null | grep "^CJK_FONT_SC=" | cut -d= -f2)
CJK_FONT_TC := $(shell bash $(FONT_DETECT_SCRIPT) 2>/dev/null | grep "^CJK_FONT_TC=" | cut -d= -f2)
MAIN_FONT := $(shell bash $(FONT_DETECT_SCRIPT) 2>/dev/null | grep "^MAIN_FONT=" | cut -d= -f2)

# Fallback values if detection script fails
ifeq ($(CJK_FONT_SC),)
	CJK_FONT_SC := AR PL UMing CN
endif
ifeq ($(CJK_FONT_TC),)
	CJK_FONT_TC := AR PL UMing TW
endif
ifeq ($(MAIN_FONT),)
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
	@echo "Processing Mermaid diagrams..."
	@mkdir -p images
	@bash $(PROCESS_MERMAID_SCRIPT) $(SRC) $(MERMAID_TEMP_SRC) images
	@echo "Using CJK font: $(CJK_FONT_TC)"
	@bash $(REPLACE_FONTS_SCRIPT) $(MERMAID_TEMP_SRC) $(TEMP_SRC) "PingFang SC" "$(CJK_FONT_TC)" "PingFang TC" "$(CJK_FONT_TC)"
	@pandoc $(TEMP_SRC) --standalone --filter pandoc-crossref --citeproc -V date=$(shell date +%Y-%m-%d) -o paper.tex
	@bash $(FIX_LATEX_CSL_SCRIPT) paper.tex
	@xelatex -interaction=nonstopmode paper.tex 2>&1 | tail -50
	@xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@if [ -f paper.pdf ]; then \
		if [ "paper.pdf" != "$(PDF)" ]; then mv paper.pdf "$(PDF)"; fi; \
	else \
		exit 1; \
	fi
	@bash $(CLEANUP_TEMP_SCRIPT) $(MERMAID_TEMP_SRC) $(TEMP_SRC)

# Build the cover page (XeLaTeX)
cover: $(COVER_PDF)

$(COVER_PDF): $(COVER_TEX) $(LOGO_FILE)
	@echo "Using main font: $(MAIN_FONT), CJK font: $(CJK_FONT_TC)"
	@bash $(REPLACE_FONTS_SCRIPT) $(COVER_TEX) $(COVER_TEMP_TEX) "Times New Roman" "$(MAIN_FONT)" "PingFang TC" "$(CJK_FONT_TC)"
	@bash tools/inject-date.sh $(COVER_TEMP_TEX)
	@xelatex -interaction=nonstopmode -jobname=cover $(COVER_TEMP_TEX)
	@bash $(CLEANUP_TEMP_SCRIPT) $(COVER_TEMP_TEX)

# Download NTUST logo if missing
$(LOGO_FILE):
	@echo "Fetching NTUST logo..."
	@bash tools/download-logo.sh $(LOGO_FILE) $(LOGO_URL)

# Optionally create a single PDF with the cover in front (requires pdfunite from poppler)
$(PRINTED_PDF): $(COVER_PDF) $(PDF)
	@bash tools/merge-pdfs.sh $(COVER_PDF) $(PDF) $(PRINTED_PDF)

printed: $(PRINTED_PDF)
	@true

# Translate to Traditional Chinese and build PDFs
zh_tw: $(ZH_TW_PRINTED_PDF)
	@echo "Translation to Traditional Chinese completed. PDFs generated in $(ZH_TW_DIR)/"
	@echo "Updating progress tracking..."
	@if [ -f plans/make_translation_target.md ]; then sed -i.bak 's/Status:.*/Status: ✅ Completed/' plans/make_translation_target.md && rm -f plans/make_translation_target.md.bak; fi

# Build PDF from translated markdown
$(ZH_TW_PDF): $(ZH_TW_SRC) $(BIB) $(CSL)
	@echo "Building PDF from translated markdown..."
	@echo "Processing Mermaid diagrams..."
	@mkdir -p images
	@bash $(CREATE_SYMLINKS_SCRIPT) $(ZH_TW_DIR) $(BIB) $(CSL) "bibliography.json"
	@if [ -d images ]; then \
		if [ -e $(ZH_TW_DIR)/images ]; then rm -rf $(ZH_TW_DIR)/images; fi; \
		cd $(ZH_TW_DIR) && ln -sf ../images images; \
	fi
	@bash $(PROCESS_MERMAID_SCRIPT) $(ZH_TW_SRC) $(ZH_TW_DIR)/paper.mermaid.tmp.md images
	@echo "Using CJK font: $(CJK_FONT_TC)"
	@bash $(REPLACE_FONTS_SCRIPT) $(ZH_TW_DIR)/paper.mermaid.tmp.md $(ZH_TW_DIR)/paper.tmp.md "PingFang SC" "$(CJK_FONT_TC)"
	@cd $(ZH_TW_DIR) && pandoc paper.tmp.md --standalone --filter pandoc-crossref --citeproc --bibliography=references.json --bibliography="bibliography.json" --csl=chicago-author-date.csl -V date=$(shell date +%Y-%m-%d) -o paper.tex
	@bash $(FIX_LATEX_CSL_SCRIPT) $(ZH_TW_DIR)/paper.tex
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode paper.tex >/dev/null 2>&1
	@if [ ! -f "$(ZH_TW_PDF)" ]; then exit 1; fi
	@bash $(CLEANUP_TEMP_SCRIPT) $(ZH_TW_DIR)/paper.mermaid.tmp.md $(ZH_TW_DIR)/paper.tmp.md $(ZH_TW_DIR)/paper.tex $(ZH_TW_DIR)/paper.aux $(ZH_TW_DIR)/paper.log
	@echo "Cleaned up intermediate translation files"

# Build cover PDF from translated LaTeX
$(ZH_TW_COVER_PDF): $(ZH_TW_COVER) $(LOGO_FILE)
	@echo "Building cover PDF from translated LaTeX..."
	@echo "Using main font: $(MAIN_FONT), CJK font: $(CJK_FONT_TC)"
	@bash $(COPY_LOGO_SCRIPT) $(LOGO_FILE) $(ZH_TW_DIR)
	@bash $(REPLACE_FONTS_SCRIPT) $(ZH_TW_COVER) $(ZH_TW_DIR)/cover_page.tmp.tex "Times New Roman" "$(MAIN_FONT)" "PingFang TC" "$(CJK_FONT_TC)"
	@bash tools/inject-date.sh $(ZH_TW_DIR)/cover_page.tmp.tex
	@cd $(ZH_TW_DIR) && xelatex -interaction=nonstopmode -jobname=cover cover_page.tmp.tex
	@bash $(CLEANUP_TEMP_SCRIPT) $(ZH_TW_DIR)/cover_page.tmp.tex $(ZH_TW_DIR)/cover.aux $(ZH_TW_DIR)/cover.log
	@echo "Cleaned up intermediate translation files"

# Translate markdown file
$(ZH_TW_SRC): $(SRC)
	@echo "Translating $(SRC) to Traditional Chinese..."
	@mkdir -p $(ZH_TW_DIR)
	@bash $(TRANSLATE_SCRIPT) $(SRC) $(ZH_TW_SRC) "English" "Traditional Chinese" $(LLM_MODEL) $(API_KEY_FILE)
	@echo "Validating and fixing formatting errors in translation..."
	@bash $(VALIDATE_TRANSLATED_MD_SCRIPT) $(SRC) $(ZH_TW_SRC) $(LLM_MODEL) $(API_KEY_FILE)
	@echo "Post-processing translated markdown..."
	@bash $(POSTPROCESS_MD_SCRIPT) $(ZH_TW_SRC) "$(CJK_FONT_TC)"

# Translate cover LaTeX file
$(ZH_TW_COVER): $(COVER_TEX)
	@echo "Translating $(COVER_TEX) to Traditional Chinese..."
	@mkdir -p $(ZH_TW_DIR)
	@bash $(TRANSLATE_SCRIPT) $(COVER_TEX) $(ZH_TW_COVER) "English" "Traditional Chinese" $(LLM_MODEL) $(API_KEY_FILE)
	@echo "Post-processing translated LaTeX..."
	@bash $(POSTPROCESS_TEX_SCRIPT) $(ZH_TW_COVER) "PingFang TC" "$(CJK_FONT_TC)"

# Merge cover and paper PDFs for Traditional Chinese version
$(ZH_TW_PRINTED_PDF): $(ZH_TW_COVER_PDF) $(ZH_TW_PDF)
	@bash tools/merge-pdfs.sh $(ZH_TW_COVER_PDF) $(ZH_TW_PDF) $(ZH_TW_PRINTED_PDF)

# Install required external tools (for local development; not needed in Docker)
deps:
	@echo "Note: This target is for local development. In Docker, all tools are pre-installed."
	@bash tools/deps.sh

# A clean rule to remove the generated file
clean:
	@bash tools/clean.sh $(PDF) $(COVER_PDF) $(PRINTED_PDF) $(TEMP_SRC) $(COVER_TEMP_TEX)
	@rm -f images/mermaid-*.png 2>/dev/null || true
	@rm -f $(MERMAID_TEMP_SRC) 2>/dev/null || true
	@rm -rf $(ZH_TW_DIR) 2>/dev/null || true

# Declare targets that are not files
.PHONY: pdf cover printed deps clean zh_tw