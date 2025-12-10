#!/usr/bin/env python3
"""
Convert Google Docs HTML export to framework format.
Converts HTML to Markdown, extracts metadata, handles images, and generates
paper.md, cover_page.tex, and bibliography.json.
"""

import re
import json
import html
import shutil
from pathlib import Path
from html.parser import HTMLParser
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime

# Try to import BeautifulSoup, fall back to html.parser if not available
try:
    from bs4 import BeautifulSoup
    HAS_BS4 = True
except ImportError:
    HAS_BS4 = False
    print("Warning: BeautifulSoup4 not available, using basic html.parser")


class GoogleDocsHTMLParser:
    """Parse Google Docs HTML and convert to Markdown."""
    
    def __init__(self, html_file: Path, images_dir: Path, collections_json: Path):
        self.html_file = html_file
        self.images_dir = images_dir
        self.collections_json = collections_json
        self.metadata = {}
        self.content = []
        self.image_counter = 0
        self.citation_lookup = {}
        
    def load_citations(self):
        """Load citation lookup from collections.json."""
        if not self.collections_json.exists():
            print(f"Warning: {self.collections_json} not found")
            return
            
        with open(self.collections_json, 'r', encoding='utf-8') as f:
            entries = json.load(f)
            
        for entry in entries:
            if 'id' in entry and 'author' in entry and 'issued' in entry:
                citation_id = entry['id']
                # Build lookup by first author surname + year
                if entry['author'] and len(entry['author']) > 0:
                    first_author = entry['author'][0]
                    if 'family' in first_author:
                        surname = first_author['family']
                        if entry['issued'] and 'date-parts' in entry['issued']:
                            if entry['issued']['date-parts'] and len(entry['issued']['date-parts']) > 0:
                                year = str(entry['issued']['date-parts'][0][0])
                                key = f"{surname.lower()}_{year}"
                                self.citation_lookup[key] = citation_id
                                
    def parse_html(self):
        """Parse HTML file using BeautifulSoup or basic parser."""
        with open(self.html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
            
        if HAS_BS4:
            # BeautifulSoup automatically decodes HTML entities, but ensure it does
            soup = BeautifulSoup(html_content, 'html.parser')
            # Verify Chinese characters are present
            test_text = soup.get_text()
            chinese_count = len([c for c in test_text if '\u4e00' <= c <= '\u9fff'])
            if chinese_count == 0:
                # If no Chinese found, try manual entity decoding
                import html as html_lib
                html_content = html_lib.unescape(html_content)
                soup = BeautifulSoup(html_content, 'html.parser')
            self._parse_with_bs4(soup)
        else:
            self._parse_with_basic_parser(html_content)
            
    def _parse_with_bs4(self, soup):
        """Parse HTML using BeautifulSoup."""
        # Extract metadata from cover page (usually in first table)
        tables = soup.find_all('table')
        if tables:
            cover_table = tables[0]
            self._extract_metadata_from_table(cover_table)
            # Mark cover table to skip it in content conversion
            cover_table['data-skip'] = 'true'
        
        # Find abstract section first (case-insensitive) to avoid marking it as title
        abstract_text, abstract_h1 = self._find_abstract(soup)
        
        # Extract title from first two h1 tags (Chinese and English), excluding ABSTRACT
        h1_tags = soup.find_all('h1')
        title_h1s = [h1 for h1 in h1_tags if h1 != abstract_h1]
        
        if title_h1s and len(title_h1s) >= 2:
            # First h1 is Chinese title, second is English title
            self.metadata['title'] = title_h1s[0].get_text(strip=True)
            self.metadata['title_en'] = title_h1s[1].get_text(strip=True)
            # Mark these h1s to skip in content
            title_h1s[0]['data-skip'] = 'true'
            title_h1s[1]['data-skip'] = 'true'
        elif title_h1s:
            self.metadata['title'] = title_h1s[0].get_text(strip=True)
            title_h1s[0]['data-skip'] = 'true'
        
        # Store abstract text in metadata
        if abstract_text:
            self.metadata['abstract'] = abstract_text
            # Ensure ABSTRACT h1 is NOT skipped (it should appear in markdown)
            if abstract_h1:
                # Remove any skip flag that might have been set
                if abstract_h1.get('data-skip'):
                    del abstract_h1['data-skip']
            
        # Convert body content to Markdown, skipping cover page elements
        body = soup.find('body') or soup
        self._convert_element_to_markdown(body)
        
    def _parse_with_basic_parser(self, html_content):
        """Basic HTML parsing using regex and string operations."""
        # This is a fallback - less robust but works without dependencies
        # Extract title
        h1_match = re.search(r'<h1[^>]*>(.*?)</h1>', html_content, re.DOTALL | re.IGNORECASE)
        if h1_match:
            title = self._clean_html_text(h1_match.group(1))
            self.metadata['title'] = title
            
        # Extract cover page info from first table
        table_match = re.search(r'<table[^>]*>(.*?)</table>', html_content, re.DOTALL | re.IGNORECASE)
        if table_match:
            table_content = table_match.group(1)
            self._extract_metadata_from_text(table_content)
            
        # Find abstract
        abstract_match = re.search(r'摘要[^<]*</p>', html_content)
        if abstract_match:
            # Try to extract abstract text
            abstract_text = self._extract_abstract_text(html_content)
            if abstract_text:
                self.metadata['abstract'] = abstract_text
                
        # Convert HTML to Markdown (basic conversion)
        self._convert_html_to_markdown_basic(html_content)
        
    def _extract_metadata_from_table(self, table):
        """Extract metadata from cover page table."""
        # Use space separator but then normalize spaces
        text = table.get_text(separator=' ', strip=True)
        # Normalize multiple spaces to single space, but preserve student ID
        text = re.sub(r'\s+', ' ', text)
        # Fix student ID if it was split (M113269 15 -> M11326915)
        text = re.sub(r'M(\d+)\s+(\d+)', r'M\1\2', text)
        self._extract_metadata_from_text(text)
        
    def _extract_metadata_from_text(self, text):
        """Extract metadata from text patterns."""
        # Author: 研究生：周乃宏
        author_match = re.search(r'研究生[：:]\s*([^指]+?)(?=\s+指導|$)', text)
        if author_match:
            self.metadata['author'] = author_match.group(1).strip()
            
        # Advisor: 指導教授：鄭正元，戴文凱 博士
        advisor_match = re.search(r'指導教授[：:]\s*([^中]+?)(?=\s+中|$)', text)
        if advisor_match:
            self.metadata['advisor'] = advisor_match.group(1).strip()
            
        # Student ID: 學號：M11326915 (match full ID, handle spaces)
        student_id_match = re.search(r'學號[：:]\s*(M\d+(?:\s+\d+)?)', text)
        if student_id_match:
            student_id = student_id_match.group(1).replace(' ', '').strip()
            self.metadata['student_id'] = student_id
            
        # Date: 115年 6月 (handle spaces)
        date_match = re.search(r'(\d+)\s*年\s*(\d+)\s*月', text)
        if date_match:
            roc_year = int(date_match.group(1))
            month = int(date_match.group(2))
            # Convert ROC year to AD year (ROC year 115 = AD 2026)
            ad_year = roc_year + 1911
            self.metadata['date_roc'] = f"{roc_year}年 {month}月"
            # Convert to English date format
            month_names = ['January', 'February', 'March', 'April', 'May', 'June',
                          'July', 'August', 'September', 'October', 'November', 'December']
            self.metadata['date'] = f"{month_names[month-1]} 1, {ad_year}"
            
    def _find_abstract(self, soup) -> Tuple[Optional[str], Any]:
        """Find abstract section in HTML. Returns (abstract_text, abstract_h1_element)."""
        # Look for "摘要" or "Abstract" heading (case-insensitive) followed by paragraphs
        for element in soup.find_all(['h1', 'h2', 'h3', 'p']):
            text = element.get_text(strip=True)
            text_lower = text.strip().lower()
            # Match "摘要", "Abstract", or "ABSTRACT" (case-insensitive)
            if text_lower == '摘要' or text_lower == 'abstract':
                # Get following paragraphs until we hit another heading or "關鍵字"
                abstract_parts = []
                next_elem = element.find_next_sibling()
                while next_elem:
                    if next_elem.name in ['h1', 'h2', 'h3', 'h4']:
                        break
                    if next_elem.name == 'p':
                        para_text = next_elem.get_text(strip=True)
                        # Stop at keywords section
                        if '關鍵字' in para_text or 'Keywords' in para_text or 'keywords' in para_text.lower():
                            break
                        if para_text:
                            abstract_parts.append(para_text)
                    next_elem = next_elem.find_next_sibling()
                if abstract_parts:
                    # Return both the abstract text and the h1 element (if it's an h1)
                    abstract_h1 = element if element.name == 'h1' else None
                    return (' '.join(abstract_parts), abstract_h1)
        return (None, None)
        
    def _extract_abstract_text(self, html_content: str) -> Optional[str]:
        """Extract abstract text using regex."""
        # Look for abstract section
        abstract_pattern = r'摘要[^<]*</p>\s*<p[^>]*>(.*?)</p>'
        match = re.search(abstract_pattern, html_content, re.DOTALL)
        if match:
            return self._clean_html_text(match.group(1))
        return None
        
    def _convert_element_to_markdown(self, element):
        """Convert HTML element to Markdown recursively."""
        if HAS_BS4:
            self._convert_with_bs4(element)
        else:
            # Fallback to text extraction
            text = element.get_text(separator='\n', strip=True)
            self.content.append(text)
            
    def _convert_with_bs4(self, element):
        """Convert HTML to Markdown using BeautifulSoup."""
        for child in element.children:
            if hasattr(child, 'name'):
                # Skip cover page elements
                if child.get('data-skip') == 'true':
                    continue
                    
                if child.name == 'h1':
                    self.content.append(f"\n# {child.get_text(strip=True)}\n")
                elif child.name == 'h2':
                    self.content.append(f"\n## {child.get_text(strip=True)}\n")
                elif child.name == 'h3':
                    self.content.append(f"\n### {child.get_text(strip=True)}\n")
                elif child.name == 'h4':
                    self.content.append(f"\n#### {child.get_text(strip=True)}\n")
                # This is now handled in the image check above
                elif child.name == 'ul' or child.name == 'ol':
                    self._convert_list(child)
                elif child.name == 'table':
                    # Skip cover page table
                    if child.get('data-skip') != 'true':
                        self._convert_table(child)
                elif child.name == 'img':
                    self._convert_image(child)
                # Also check for images in paragraphs
                elif child.name == 'p':
                    # Check if paragraph contains an image
                    img_in_p = child.find('img')
                    if img_in_p:
                        # Convert image first
                        self._convert_image(img_in_p)
                        # Then process remaining paragraph text
                        para_text = self._process_paragraph(child)
                        # Remove image alt text from paragraph if it's duplicated
                        if para_text.strip():
                            self.content.append(f"{para_text}\n\n")
                    else:
                        text = self._process_paragraph(child)
                        if text.strip():
                            self.content.append(f"{text}\n\n")
                elif child.name in ['div', 'span', 'body']:
                    # Recursively process children
                    self._convert_with_bs4(child)
                    
    def _process_paragraph(self, p_elem) -> str:
        """Process paragraph element, handling inline formatting and citations."""
        text = ""
        for item in p_elem.descendants:
            # Skip images (they're handled separately)
            if hasattr(item, 'name') and item.name == 'img':
                continue
            if isinstance(item, str):
                text += item
            elif hasattr(item, 'name'):
                if item.name in ['b', 'strong']:
                    text += f"**{item.get_text(strip=True)}**"
                elif item.name in ['i', 'em']:
                    text += f"*{item.get_text(strip=True)}*"
                elif item.name == 'a':
                    href = item.get('href', '')
                    link_text = item.get_text(strip=True)
                    # Check if link contains a Pandoc citation (starts with [@)
                    # If so, extract just the citation and skip the link wrapper
                    if link_text.strip().startswith('[@') and ']' in link_text:
                        # Extract citation from link text
                        citation_match = re.search(r'\[@[^\]]+\]', link_text)
                        if citation_match:
                            text += citation_match.group(0)
                        else:
                            text += link_text
                    # Check if link is a Zotero/google-docs citation URL
                    # In this case, the link text might be the citation, so use it directly
                    elif 'zotero.org' in href or 'google-docs' in href:
                        # If link text looks like a citation, use it; otherwise skip the link
                        if link_text.strip().startswith('[@') or '(' in link_text:
                            text += link_text
                        else:
                            text += f"[{link_text}]({href})"
                    else:
                        text += f"[{link_text}]({href})"
                    
        # Convert citations
        text = self._convert_citations(text)
        # Remove duplicate citations with links: [[@citation]](url)[@citation] -> [@citation]
        text = re.sub(r'\[\[(@[^\]]+)\]\]\([^\)]+\)\[@[^\]]+\]', r'[\1]', text)
        # Remove consecutive duplicate citations: [@citation][@citation] -> [@citation]
        text = re.sub(r'(\[@[^\]]+\])\1', r'\1', text)
        # Remove duplicate author-date citations with links: [(Author, Year)](url)(Author, Year) -> (Author, Year)
        text = re.sub(r'\[\(([^)]+)\)\]\([^\)]+\)\1', r'(\1)', text)
        # Remove consecutive duplicate author-date citations: (Author, Year)(Author, Year) -> (Author, Year)
        text = re.sub(r'(\([^)]*(?:et al\.|&|,)\s*(?:19|20)\d{2}[^)]*\))\1', r'\1', text)
        # Remove empty citation pattern: []()
        text = re.sub(r'\[\]\(\)', '', text)
        # Remove duplicate figure/table references: [「圖N」](#link)「圖N」 -> [「圖N」](#link)
        text = re.sub(r'(\[「(圖|表)\d+」\]\([^\)]+\))「\2\d+」', r'\1', text)
        # Remove duplicate figure/table references: [圖N：](#link)圖N：： -> [圖N：](#link)
        text = re.sub(r'(\[(圖|表)\d+：\]\([^\)]+\))\2\d+：：', r'\1', text)
        # Remove duplicate table references: [表N：](#link)表N：： -> [表N：](#link)
        text = re.sub(r'(\[表\d+：\]\([^\)]+\))表\d+：：', r'\1', text)
        # Remove duplicate figure/table references with single colon: [圖N：](#link)圖N： -> [圖N：](#link)
        text = re.sub(r'(\[(圖|表)\d+：\]\([^\)]+\))\2\d+：\s*', r'\1 ', text)
        return text.strip()
        
    def _convert_citations(self, text: str) -> str:
        """Convert author-date citations to Pandoc format."""
        # Pattern: (Author et al., Year) or (Author, Year) or (Author & Author, Year)
        citation_pattern = r'\(([^)]*(?:et al\.|&|,)\s*(?:19|20)\d{2}[^)]*)\)'
        
        def replace_citation(match):
            citation_text = match.group(1)
            # Extract author surname and year
            year_match = re.search(r'(19|20)\d{2}', citation_text)
            if not year_match:
                return match.group(0)  # Return original if no year found
                
            year = year_match.group(0)
            # Extract first author surname
            author_match = re.match(r'([A-Z][a-z]+)', citation_text)
            if not author_match:
                return match.group(0)
                
            surname = author_match.group(1)
            lookup_key = f"{surname.lower()}_{year}"
            
            if lookup_key in self.citation_lookup:
                citation_id = self.citation_lookup[lookup_key]
                return f"[@{citation_id}]"
            else:
                # Return original if no match found
                return match.group(0)
                
        return re.sub(citation_pattern, replace_citation, text)
        
    def _convert_list(self, list_elem):
        """Convert list to Markdown."""
        items = list_elem.find_all('li', recursive=False)
        is_ordered = list_elem.name == 'ol'
        
        for i, item in enumerate(items, 1):
            # Check if list item contains a heading
            heading = item.find(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
            if heading:
                # Extract heading level and text
                level = int(heading.name[1])
                heading_text = heading.get_text(strip=True)
                # Convert heading to Markdown
                self.content.append(f"\n{'#' * level} {heading_text}\n\n")
                # Get remaining text in list item (excluding heading)
                # Create a copy to avoid modifying the original
                item_copy = BeautifulSoup(str(item), 'html.parser')
                heading_copy = item_copy.find(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])
                if heading_copy:
                    heading_copy.decompose()
                remaining_text = item_copy.get_text(strip=True)
                if remaining_text:
                    self.content.append(f"{remaining_text}\n\n")
            else:
                item_text = item.get_text(strip=True)
                if is_ordered:
                    self.content.append(f"{i}. {item_text}\n")
                else:
                    self.content.append(f"- {item_text}\n")
        self.content.append("\n")
        
    def _convert_table(self, table_elem):
        """Convert HTML table to Pandoc pipe table."""
        rows = table_elem.find_all('tr')
        if not rows:
            return
            
        markdown_rows = []
        for row in rows:
            cells = row.find_all(['td', 'th'])
            cell_texts = [cell.get_text(strip=True) for cell in cells]
            markdown_rows.append("| " + " | ".join(cell_texts) + " |")
            
        if markdown_rows:
            # Add separator after header
            if len(markdown_rows) > 0:
                num_cols = len(markdown_rows[0].split('|')) - 2
                separator = "| " + " | ".join(["---"] * num_cols) + " |"
                markdown_rows.insert(1, separator)
                
            self.content.append("\n" + "\n".join(markdown_rows) + "\n\n")
            
    def _convert_image(self, img_elem):
        """Convert image to Markdown format."""
        src = img_elem.get('src', '')
        alt = img_elem.get('alt', '')
        
        # Extract image filename
        if 'images/' in src:
            filename = src.split('images/')[-1].split('?')[0]  # Remove query params if any
            self.image_counter += 1
            label = f"fig:image{self.image_counter}"
            # Use alt text or generate default
            if not alt:
                alt = f"Figure {self.image_counter}"
            # Copy image will be handled separately
            self.content.append(f"\n![{alt}](images/{filename}){{#{label} width=80%}}\n\n")
            
    def _convert_html_to_markdown_basic(self, html_content: str):
        """Basic HTML to Markdown conversion without BeautifulSoup."""
        # Remove style and script tags
        html_content = re.sub(r'<style[^>]*>.*?</style>', '', html_content, flags=re.DOTALL | re.IGNORECASE)
        html_content = re.sub(r'<script[^>]*>.*?</script>', '', html_content, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert headings
        html_content = re.sub(r'<h1[^>]*>(.*?)</h1>', r'\n# \1\n\n', html_content, flags=re.DOTALL | re.IGNORECASE)
        html_content = re.sub(r'<h2[^>]*>(.*?)</h2>', r'\n## \1\n\n', html_content, flags=re.DOTALL | re.IGNORECASE)
        html_content = re.sub(r'<h3[^>]*>(.*?)</h3>', r'\n### \1\n\n', html_content, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert images
        def replace_image(match):
            src = match.group(1)
            alt = match.group(2) if match.group(2) else ""
            if 'images/' in src:
                filename = src.split('images/')[-1]
                self.image_counter += 1
                label = f"fig:image{self.image_counter}"
                return f"\n![{alt}](images/{filename}){{#{label} width=80%}}\n\n"
            return match.group(0)
            
        html_content = re.sub(r'<img[^>]*src=["\']([^"\']*)["\'][^>]*alt=["\']([^"\']*)["\']', replace_image, html_content, flags=re.IGNORECASE)
        html_content = re.sub(r'<img[^>]*src=["\']([^"\']*)["\']', replace_image, html_content, flags=re.IGNORECASE)
        
        # Convert paragraphs
        html_content = re.sub(r'<p[^>]*>(.*?)</p>', r'\1\n\n', html_content, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert lists
        html_content = re.sub(r'<li[^>]*>(.*?)</li>', r'- \1\n', html_content, flags=re.DOTALL | re.IGNORECASE)
        html_content = re.sub(r'<ul[^>]*>|</ul>', '', html_content, flags=re.IGNORECASE)
        html_content = re.sub(r'<ol[^>]*>|</ol>', '', html_content, flags=re.IGNORECASE)
        
        # Convert bold/italic
        html_content = re.sub(r'<b[^>]*>(.*?)</b>', r'**\1**', html_content, flags=re.DOTALL | re.IGNORECASE)
        html_content = re.sub(r'<strong[^>]*>(.*?)</strong>', r'**\1**', html_content, flags=re.DOTALL | re.IGNORECASE)
        html_content = re.sub(r'<i[^>]*>(.*?)</i>', r'*\1*', html_content, flags=re.DOTALL | re.IGNORECASE)
        html_content = re.sub(r'<em[^>]*>(.*?)</em>', r'*\1*', html_content, flags=re.DOTALL | re.IGNORECASE)
        
        # Convert citations
        html_content = self._convert_citations(html_content)
        
        # Remove duplicate citations with links: [[@citation]](url)[@citation] -> [@citation]
        html_content = re.sub(r'\[\[(@[^\]]+)\]\]\([^\)]+\)\[@[^\]]+\]', r'[\1]', html_content)
        # Remove consecutive duplicate citations: [@citation][@citation] -> [@citation]
        html_content = re.sub(r'(\[@[^\]]+\])\1', r'\1', html_content)
        # Remove duplicate author-date citations with links: [(Author, Year)](url)(Author, Year) -> (Author, Year)
        html_content = re.sub(r'\[\(([^)]+)\)\]\([^\)]+\)\1', r'(\1)', html_content)
        # Remove consecutive duplicate author-date citations: (Author, Year)(Author, Year) -> (Author, Year)
        html_content = re.sub(r'(\([^)]*(?:et al\.|&|,)\s*(?:19|20)\d{2}[^)]*\))\1', r'\1', html_content)
        # Remove empty citation pattern: []()
        html_content = re.sub(r'\[\]\(\)', '', html_content)
        # Remove duplicate figure/table references: [「圖N」](#link)「圖N」 -> [「圖N」](#link)
        html_content = re.sub(r'(\[「(圖|表)\d+」\]\([^\)]+\))「\2\d+」', r'\1', html_content)
        # Remove duplicate figure/table references: [圖N：](#link)圖N：： -> [圖N：](#link)
        html_content = re.sub(r'(\[(圖|表)\d+：\]\([^\)]+\))\2\d+：：', r'\1', html_content)
        # Remove duplicate table references: [表N：](#link)表N：： -> [表N：](#link)
        html_content = re.sub(r'(\[表\d+：\]\([^\)]+\))表\d+：：', r'\1', html_content)
        # Remove duplicate figure/table references with single colon: [圖N：](#link)圖N： -> [圖N：](#link)
        html_content = re.sub(r'(\[(圖|表)\d+：\]\([^\)]+\))\2\d+：\s*', r'\1 ', html_content)
        
        # Clean up HTML entities
        html_content = html.unescape(html_content)
        
        # Remove remaining HTML tags
        html_content = re.sub(r'<[^>]+>', '', html_content)
        
        # Clean up whitespace
        html_content = re.sub(r'\n{3,}', '\n\n', html_content)
        
        self.content.append(html_content)
        
    def _clean_html_text(self, text: str) -> str:
        """Clean HTML text, removing tags and decoding entities."""
        text = re.sub(r'<[^>]+>', '', text)
        text = html.unescape(text)
        return text.strip()


def main():
    """Main conversion function."""
    project_root = Path(__file__).parent.parent
    imported_dir = project_root / "imported_paper"
    html_file = imported_dir / "LeveragingGenerativeAIforKnowledgeExtractionf.html"
    images_dir = imported_dir / "images"
    collections_json = imported_dir / "collections.json"
    output_images_dir = project_root / "images"
    
    if not html_file.exists():
        print(f"Error: {html_file} not found")
        return 1
        
    print("Parsing HTML file...")
    parser = GoogleDocsHTMLParser(html_file, images_dir, collections_json)
    parser.load_citations()
    parser.parse_html()
    
    print("Extracting metadata...")
    metadata = parser.metadata
    print(f"  Title: {metadata.get('title', 'N/A')}")
    print(f"  Author: {metadata.get('author', 'N/A')}")
    print(f"  Advisor: {metadata.get('advisor', 'N/A')}")
    print(f"  Student ID: {metadata.get('student_id', 'N/A')}")
    
    print("Copying images...")
    if images_dir.exists():
        output_images_dir.mkdir(exist_ok=True)
        for img_file in sorted(images_dir.glob("*.png")):
            shutil.copy2(img_file, output_images_dir / img_file.name)
            print(f"  Copied {img_file.name}")
    
    print("Processing bibliography...")
    if collections_json.exists():
        shutil.copy2(collections_json, project_root / "bibliography.json")
        print(f"  Copied collections.json to bibliography.json")
    
    print("Generating paper.md...")
    generate_paper_md(project_root, metadata, parser.content)
    
    print("Generating cover_page.tex...")
    generate_cover_tex(project_root, metadata)
    
    print("Conversion complete!")
    return 0


def generate_paper_md(project_root: Path, metadata: Dict, content: List[str]):
    """Generate paper.md with YAML metadata and content."""
    # Read existing paper.md to understand structure
    existing_paper = project_root / "paper.md"
    yaml_template = """---
title: "{title}"
author: "{author}"
abstract: "{abstract}"
bibliography:
  - bibliography.json
csl: chicago-author-date.csl
link-citations: true
pdf-engine: xelatex
CJKmainfont: "PingFang TC"
toc: true
toc-depth: 2
lof: true
lot: true
header-includes:
- \\pagenumbering{{arabic}}
- \\setcounter{{page}}{{1}}
- \\usepackage{{xeCJK}}
- \\setCJKmainfont{{Noto Sans CJK TC}}
- \\usepackage[a4paper,margin=1in]{{geometry}}
- |
    \\usepackage{{etoolbox}}
    \\AtBeginEnvironment{{CSLReferences}}{{
      \\newpage\\section*{{References}}%
      \\setlength{{\\parindent}}{{0pt}}%
    }}
    \\pretocmd{{\\tableofcontents}}{{\\clearpage}}{{}}{{}}
    \\pretocmd{{\\listoffigures}}{{\\clearpage}}{{}}{{}}
    \\pretocmd{{\\listoftables}}{{\\clearpage}}{{}}{{}}
    \\apptocmd{{\\listoftables}}{{\\clearpage}}{{}}{{}}
figPrefix: "圖"
tblPrefix: "表"
rangeDelim: "–"
numbersections: true
---

"""
    
    title = metadata.get('title', 'Untitled')
    if 'title_en' in metadata:
        title = f"{title} / {metadata['title_en']}"
    author = metadata.get('author', 'Unknown')
    abstract = metadata.get('abstract', '')
    
    # Escape quotes in YAML
    title = title.replace('"', '\\"')
    author = author.replace('"', '\\"')
    abstract = abstract.replace('"', '\\"').replace('\n', ' ')
    
    yaml_content = yaml_template.format(
        title=title,
        author=author,
        abstract=abstract
    )
    
    markdown_content = "".join(content)
    
    with open(existing_paper, 'w', encoding='utf-8') as f:
        f.write(yaml_content)
        f.write(markdown_content)


def generate_cover_tex(project_root: Path, metadata: Dict):
    """Generate cover_page.tex with extracted metadata."""
    cover_template = """% NTUST-style thesis cover (A4), Traditional Chinese enabled via XeLaTeX
% Compile with: xelatex cover_page.tex
\\documentclass[a4paper,12pt]{{article}}

\\usepackage[margin=2.5cm]{{geometry}}
\\usepackage{{graphicx}}
\\usepackage{{xcolor}}
\\usepackage{{xeCJK}}         % Traditional Chinese support (requires XeLaTeX)
\\usepackage{{fontspec}}
\\usepackage{{indentfirst}}
\\usepackage{{ifthen}}

% ----------------------------
% Fonts (adjust to installed fonts on your system if needed)
% Recommended: Noto Serif CJK TC / Noto Sans CJK TC
\\setmainfont{{Times New Roman}}
% macOS built-in Traditional Chinese font; widely available
\\setCJKmainfont{{PingFang TC}}
\\setCJKsansfont{{PingFang TC}}
% Define a CJK family alias used below
\\setCJKfamilyfont{{song}}{{PingFang TC}}

% ----------------------------
% Metadata (edit these fields)
\\newcommand{{\\University}}{{National Taiwan University of Science and Technology}}
\\newcommand{{\\Department}}{{Executive Master of Research and Development}}
\\newcommand{{\\DegreeName}}{{Master's Thesis}}
\\newcommand{{\\StudentID}}{{{student_id}}}
\\newcommand{{\\Title}}{{{title}}}
\\newcommand{{\\Author}}{{{author}}}
\\newcommand{{\\Advisor}}{{{advisor}}}
\\newcommand{{\\ROCDate}}{{{date}}}

% ----------------------------
% Simple helpers
\\newcommand{{\\HRule}}{{\\noindent\\rule{{\\textwidth}}{{0.6pt}}}}

\\begin{{document}}
\\thispagestyle{{empty}}
\\linespread{{1.25}}\\selectfont
\\vspace*{{8mm}}

% University emblem/logo
\\begin{{center}}
  % Logo is optional. If file not present, leaves vertical space.
  \\IfFileExists{{ntust_logo.jpg}}{{
    \\includegraphics[width=28mm]{{ntust_logo.jpg}}%
  }}{{
    \\IfFileExists{{ntust_logo.pdf}}{{
      \\includegraphics[width=28mm]{{ntust_logo.pdf}}%
    }}{{
      \\IfFileExists{{ntust_logo.png}}{{
        \\includegraphics[width=28mm]{{ntust_logo.png}}%
      }}{{
        \\vspace{{28mm}}%
      }}%
    }}%
  }}%
\\end{{center}}

% University / Department / Degree
\\vspace{{8mm}}
\\begin{{center}}
  {{\\CJKfamily{{song}}\\fontsize{{20pt}}{{28pt}}\\selectfont \\University}}\\\\[4mm]
  {{\\CJKfamily{{song}}\\fontsize{{18pt}}{{26pt}}\\selectfont \\Department}}\\\\[4mm]
  {{\\CJKfamily{{song}}\\fontsize{{18pt}}{{26pt}}\\selectfont \\DegreeName}}
\\end{{center}}

\\vspace{{4mm}}
\\noindent\\hfill {{\\CJKfamily{{song}}\\normalsize Student ID: \\StudentID}}

\\vspace{{3mm}}
\\HRule

% Titles
\\vspace{{20mm}}
\\begin{{center}}
  {{\\CJKfamily{{song}}\\fontsize{{16pt}}{{24pt}}\\selectfont \\Title}}
\\end{{center}}

% Author / Advisor
\\vspace{{28mm}}
\\begin{{center}}
  {{\\CJKfamily{{song}}\\fontsize{{14pt}}{{22pt}}\\selectfont
    Student: \\Author \\\\[6mm]
    Advisor: \\Advisor
  }}
\\end{{center}}

% Date
\\vfill
\\begin{{center}}
  {{\\CJKfamily{{song}}\\fontsize{{14pt}}{{22pt}}\\selectfont \\ROCDate}}
\\end{{center}}

\\end{{document}}

"""
    
    title = metadata.get('title', 'Untitled')
    author = metadata.get('author', 'Unknown')
    advisor = metadata.get('advisor', 'Unknown')
    student_id = metadata.get('student_id', 'Unknown')
    date = metadata.get('date', 'Unknown')
    
    # Escape LaTeX special characters
    def escape_latex(text):
        special_chars = ['\\', '&', '%', '$', '#', '^', '{', '}', '_']
        for char in special_chars:
            text = text.replace(char, '\\' + char)
        return text
    
    title = escape_latex(title)
    author = escape_latex(author)
    advisor = escape_latex(advisor)
    student_id = escape_latex(student_id)
    date = escape_latex(date)
    
    cover_content = cover_template.format(
        title=title,
        author=author,
        advisor=advisor,
        student_id=student_id,
        date=date
    )
    
    cover_file = project_root / "cover_page.tex"
    with open(cover_file, 'w', encoding='utf-8') as f:
        f.write(cover_content)


if __name__ == "__main__":
    exit(main())
