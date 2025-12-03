---
title: "Sustainable Scholarship: A Robust Academic Workflow with Markdown, Pandoc, and LaTeX"
author: An Old-Fashioned Researcher
date: 2025-10-25
abstract: This document serves as a complete, self-referential example of the Pandoc academic workflow. It demonstrates the use of a YAML metadata block for configuration, automated citations with pandoc-citeproc, cross-references for figures, tables, and equations with pandoc-crossref, and advanced customization for multilingual typesetting and page numbering through LaTeX.
bibliography:
  - references.json
  - "Graduate Paper.json" 
csl: chicago-author-date.csl 
link-citations: true
pdf-engine: xelatex
CJKmainfont: "PingFang SC"
toc: true
toc-depth: 2
lof: true
lot: true
header-includes:
- \pagenumbering{arabic}
- \setcounter{page}{1}
- \usepackage{xeCJK}
- \setCJKmainfont{PingFang SC}
- \usepackage[a4paper,margin=1in]{geometry}
- |
    \usepackage{etoolbox}
    \AtBeginEnvironment{CSLReferences}{%
      \newpage\section*{References}%
      \setlength{\parindent}{0pt}%
    }
    \pretocmd{\tableofcontents}{\clearpage}{}{}
    \pretocmd{\listoffigures}{\clearpage}{}{}
    \pretocmd{\listoftables}{\clearpage}{}{}
    \apptocmd{\listoftables}{\clearpage}{}{}
figPrefix:
-   "Figure"
-   "Figures" 
tblPrefix: "Tab."
rangeDelim: "–"
numbersections: true
---

# Introduction: The Philosophy of Plain-Text Academia

The choice of writing tools in academic work is not merely a matter of technical preference; it is a philosophical commitment to a particular mode of scholarship. The modern plain-text workflow, centered on Markdown, Pandoc, and LaTeX, represents a deliberate move towards a more robust, transparent, and durable scholarly practice [@healy2018plain]. This approach is founded on a set of core principles that stand in stark contrast to the opaque, proprietary nature of traditional word processors.

At its heart is the principle of **sustainability**. Plain-text files, such as those written in Markdown, are the most resilient digital format. Unlike the complex binary structures of `.docx` files, which can become corrupted or obsolete as software changes, plain text will remain readable and accessible for decades, ensuring the long-term viability of one's intellectual output [@healy2018plain; @macfarlane2022pandoc]. This is coupled with the powerful concept of **separation of concerns**, where the semantic content of a document—the text, its structure, and its meaning—is written in Markdown, completely divorced from its final visual presentation, which is handled independently by LaTeX templates or other styling mechanisms. This modularity allows for radical changes in output format with zero alteration to the source manuscript.

Furthermore, this workflow is uniquely suited for the rigorous demands of modern research. Plain-text files integrate seamlessly with **version control systems** like Git, enabling meticulous tracking of every change, non-destructive experimentation with drafts, and transparent collaboration among authors—a process notoriously fraught with difficulty when using binary files [@healy2018plain]. The entire process, from the initial draft to the final PDF, can be automated with simple scripts, ensuring perfect **reproducibility** at any point in the future, a cornerstone of scientific and scholarly integrity.

This system is best understood not as a collection of disparate tools, but as a linear, modular data processing pipeline. The raw manuscript (`.md`) and bibliographic data (`.json` or `.bib`) serve as the initial inputs. These inputs are then passed through a chain of specialized filters and transformers: Zotero and its Better BibTeX extension manage and export bibliographic data; Pandoc parses the source text [@macfarlane2022pandoc]; `pandoc-citeproc` resolves citation markers; `pandoc-crossref` numbers figures and equations [@lierdakil2021crossref]; and finally, a LaTeX engine like XeLaTeX performs the final typesetting to produce a PDF. Each stage is discrete and transparent. This contrasts fundamentally with the monolithic, "black box" environment of a word processor, where these processes are intertwined and hidden from the user. The power of this workflow lies in the ability to control this pipeline, to swap out components, insert new processing stages, and debug any issue by inspecting the intermediate output at any point—for instance, by generating the intermediate `.tex` file to diagnose a LaTeX error. This level of control and transparency is the key to solving the complex, bespoke formatting challenges inherent in academic writing.

# Part I: The Core Toolchain

## Section 1: Assembling Your Digital Workbench

Before embarking on the plain-text writing process, a one-time setup of the core toolchain is required. This digital workbench forms the foundation of the entire workflow.

**Pandoc: The Universal Document Converter** At the heart of the workflow is Pandoc, a command-line utility often described as the "swiss army knife" for document conversion [@macfarlane2022pandoc]. It is responsible for parsing the source Markdown file and orchestrating its transformation into the final output format.

**A LaTeX Distribution: The Typesetting Engine** Pandoc does not create PDF files directly. Instead, it generates LaTeX source code (`.tex`), which is then compiled by a dedicated LaTeX engine to produce the final, professionally typeset PDF. To ensure all necessary packages for advanced features, complex layouts, and multilingual support are available, it is strongly recommended to install a full LaTeX distribution, such as TeX Live.

**A Plain-Text Editor: The Writing Environment** The writing itself is done in a plain-text editor. Modern, extensible editors like Visual Studio Code (VSCode), Atom, or the academic-focused Zettlr are ideal choices.

**Zotero: The Reference Manager** Robust reference management is handled by Zotero, a powerful, open-source application. For this workflow, the installation of the **Better BibTeX for Zotero (BBT)** extension is non-negotiable. BBT provides two essential features: the automatic generation of stable, human-readable citation keys and a highly reliable, automated export process that keeps the bibliography file synchronized with the Zotero library.

The components are summarized in @tbl:workbench.

| Component          | Purpose                                                  | Recommended Software | Key Configuration Notes                                                               |
| ------------------ | -------------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------------- |
| Document Converter | Parses Markdown and orchestrates the conversion process. | Pandoc               | Install via OS-specific package manager (e.g., Homebrew for macOS).                   |
| Typesetting Engine | Compiles LaTeX code generated by Pandoc into a PDF.      | TeX Live             | Install the full distribution to avoid missing package errors.                        |
| Text Editor        | The environment for writing in plain-text Markdown.      | VSCode               | Install extensions: Markdown Preview Enhanced and Pandoc Citer.                       |
| Reference Manager  | Manages bibliographic data and exports it for Pandoc.    | Zotero               | Install the Better BibTeX for Zotero (BBT) extension for stable keys and auto-export. |

: The Digital Scholar's Workbench. {#tbl:workbench}

## Section 2: The Pandoc Conversion Engine: From Markdown to PDF

With the toolchain installed, the conversion process is driven by the Pandoc command-line interface, configured primarily through a metadata block within the Markdown file itself, as seen at the top of this very document.

**The Basic Conversion Command** The fundamental command to convert a Markdown file to a PDF is straightforward: `pandoc input.md -o output.pdf`. Pandoc typically infers the input and output formats from the file extensions.

**The YAML Metadata Block: The Document's Control Panel** Rather than relying on long and cumbersome command-line flags, Pandoc configurations are best managed within a YAML metadata block at the very top of the Markdown file, delimited by `---` on either side. This approach is superior because it keeps the document's essential metadata and its compilation settings version-controlled alongside the content itself.

**The Standalone Flag (`-s`)** A critical option for generating a complete document is `--standalone` (or its shorthand, `-s`). This flag instructs Pandoc to use a template to wrap the converted content with the necessary header and footer material—for example, the `\documentclass{...}` and `\begin{document}...\end{document}` commands in LaTeX—to create a self-contained, compilable file rather than a mere fragment.

# Part II: Managing Scholarly Apparatus

## Section 3: Automated Citations and Bibliographies with `pandoc-citeproc`

A cornerstone of academic writing is the correct management of citations and bibliographies. The Pandoc workflow automates this process with exceptional precision using its citation processor, `pandoc-citeproc`.

**The Role of `pandoc-citeproc`** The citation processor, invoked with the `--citeproc` flag in modern Pandoc versions, is the filter responsible for parsing Markdown citation syntax, transforming it into fully formatted in-text citations, and automatically generating a bibliography at the end of the document.

**Step 1: Configuring Zotero and Better BibTeX (BBT)** The process begins with the reference manager. Within Zotero, the Better BibTeX extension should be configured to automatically export the desired library or collection to a file whenever an entry is added or modified.

**Step 2: Choosing the Bibliography Format: CSL JSON vs. BibTeX** To ensure the highest possible fidelity between the reference manager and the final document, it is strongly recommended to export directly from Zotero to a CSL-native format, such as **Better CSL JSON** or **Better CSL YAML**. This eliminates the "man-in-the-middle" conversion and preserves the integrity of the bibliographic data.

**Step 3: Specifying Bibliography and Style in YAML** The connection between the Markdown document and the bibliographic data is made in the YAML metadata block. Two keys are required: `bibliography:` and `csl:`. Thousands of CSL styles for various journals and conventions are available for download from the official Zotero Style Repository.

**Step 4: Mastering Pandoc Citation Syntax** With the setup complete, citing sources in Markdown is simple and expressive. The syntax supports a wide range of scholarly conventions.

-   **Standard Parenthetical Citations:** `...as has been shown [@knuth1984tex; @lamport1986latex]`.
    
-   **Narrative (Author-in-Text) Citations:** `@macfarlane2022pandoc argues that...` renders as "MacFarlane (2022) argues that...".
    
-   **Suppressing the Author:** When an author is already mentioned, their name can be suppressed in the citation by adding a minus sign: `Healy's research [-@healy2018plain] confirms...` renders as "Healy's research (2018) confirms...".
    
-   **Prefixes, Locators, and Suffixes:** `[see @knuth1984tex, chap. 3]`.
    

## Section 4: Cross-Referencing Figures, Tables, and Equations with `pandoc-crossref`

While vanilla Markdown lacks a native method for numbering and cross-referencing, this critical academic function is seamlessly added by using the `pandoc-crossref` filter [@lierdakil2021crossref].

**Installation and Activation** First, the `pandoc-crossref` executable must be installed. The filter is then activated by adding the `--filter pandoc-crossref` flag to the Pandoc command. If also using the citation processor, this flag must appear _before_ the `--citeproc` flag.

**Labeling and Referencing Syntax** The syntax for labeling and referencing elements is designed to be intuitive. For example, we can reference the table of tools from earlier: @tbl:workbench. We can also reference the plot in @fig:my-plot and the famous equation in @eq:relativity.

$$E=mc^2$$ {#eq:relativity}

![Example plot](images/2025-11-17-19-47-43.png){#fig:my-plot width=20%}

**Customization via YAML** The appearance of cross-references can be customized through YAML metadata variables, as demonstrated in the header of this file.

# Part III: Advanced Customization and Multilingual Typesetting

## Section 5: Mastering Document Appearance with LaTeX Templates

The visual appearance of the final PDF is controlled almost entirely by LaTeX. Pandoc provides a powerful and flexible system for interfacing with LaTeX templates.

**Using a Custom Template** For any serious academic work, a custom template is usually required. A custom template is specified using the `--template` flag: `pandoc mydoc.md -o mydoc.pdf --template=eisvogel`. High-quality templates can be found on publisher websites, in large community repositories like Overleaf, and on code-hosting platforms like GitHub [@wandmalfarbe2020eisvogel].

**Case Study: The Eisvogel Template for a Custom Cover Page** The popular Eisvogel template provides a clear example of how template-specific variables, set in the YAML block, can be used for deep customization [@wandmalfarbe2020eisvogel].

## Section 6: A Guide to Traditional Chinese Typesetting

Producing high-quality documents in Traditional Chinese requires specific configuration. The Pandoc and LaTeX toolchain is exceptionally capable in this regard.

**The Engine Requirement: `pdflatex` vs. `xelatex`** For any work involving non-Latin scripts, it is essential to use a modern, Unicode-aware engine like **XeLaTeX**.

**Configuring Pandoc for `xelatex`** To instruct Pandoc to use XeLaTeX, one can set `pdf-engine: xelatex` in the document's YAML block.

**Font Selection for Traditional Chinese** The second critical requirement is to specify a font that contains the necessary glyphs for Traditional Chinese characters. This is also done via a variable in the YAML block: `CJKmainfont: "Source Han Serif TC"`.

This configuration allows for seamless typesetting of Traditional Chinese text, like this: 這是傳統中文的範例文字。

## Section 7: Granular Control over Page Numbering

Page numbering is a feature of the final typeset document, and as such, its control resides entirely at the LaTeX level. Pandoc provides several mechanisms to pass the necessary LaTeX commands from the Markdown source to the final compilation stage. The cleanest method is using the `header-includes` YAML field, as shown in this document's metadata, to inject raw LaTeX commands like `\setcounter{page}{1}`.

# Part IV: Historical Context and Modern Practice

## Section 8: The 'Old-Fashioned' Workflow: From Hot Metal to Typewriters

Understanding the power of the modern plain-text workflow is enhanced by appreciating the profound technical challenges it solves. Before the advent of TeX and LaTeX, academic typesetting was a highly specialized, manual process defined by severe physical and mechanical constraints. The era of **hot metal typesetting** and later **"typewriter" composition** involved immense manual effort to produce complex documents.

The development of TeX by Knuth in the late 1970s and LaTeX by Lamport in the early 1980s marked a revolutionary shift [@knuth1984tex; @lamport1986latex]. They introduced the concept of programmatic, algorithmic typesetting based on semantic commands. The modern Pandoc user operates at an even higher level of abstraction, using a simple, universal syntax that can be compiled to LaTeX or other formats entirely.

## Section 9: Synthesis and Recommendations: Building Your Sustainable Workflow

This report has detailed a comprehensive academic workflow. The very file you are reading is a tangible example of this process. By combining this Markdown file with the accompanying bibliography and `Makefile`, you can reproduce the final PDF with a single command. This demonstrates the power of a plain-text academic workflow: unparalleled control, robust versioning, seamless collaboration, and the assurance of future access to one's own work [@rowleyWisdomHierarchyRepresentations2007].