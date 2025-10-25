# Define file names
PDF = paper.pdf
SRC = paper.md
BIB = references.json
CSL = chicago-author-date.csl

# The Pandoc command with all filters and options
# Note: This assumes you have downloaded a CSL file and named it chicago-author-date.csl
# You can get it from the Zotero Style Repository.
PANDOC_CMD = pandoc $(SRC) \
	--standalone \
	--filter pandoc-crossref \
	--citeproc \
	--pdf-engine=xelatex \
	-o $(PDF)

# The default target: running 'make' or 'make pdf' will create the PDF
pdf: $(PDF)

$(PDF): $(SRC) $(BIB) $(CSL)
	$(PANDOC_CMD)

# A clean rule to remove the generated file
clean:
	rm -f $(PDF)

# Declare targets that are not files
.PHONY: pdf clean