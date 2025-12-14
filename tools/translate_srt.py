#!/usr/bin/env python3
"""
Translate SRT subtitle files using Gemini API.

This script parses SRT files, extracts subtitle text, translates it using
the Gemini API, and reconstructs the SRT file with translated text while
preserving subtitle numbers, timestamps, and formatting.
"""

import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.parse
import urllib.error


def parse_srt(content):
    """
    Parse SRT content into a list of subtitle entries.
    
    Each entry is a dict with:
    - 'number': subtitle number (str)
    - 'timestamp': timestamp line (str)
    - 'text': list of text lines (list of str)
    """
    entries = []
    blocks = re.split(r'\n\s*\n', content.strip())
    
    for block in blocks:
        if not block.strip():
            continue
        
        lines = block.strip().split('\n')
        if len(lines) < 2:
            continue
        
        # First line is subtitle number
        number = lines[0].strip()
        
        # Second line is timestamp
        if len(lines) < 2:
            continue
        timestamp = lines[1].strip()
        
        # Remaining lines are text
        text_lines = [line.strip() for line in lines[2:] if line.strip()]
        
        if text_lines:
            entries.append({
                'number': number,
                'timestamp': timestamp,
                'text': text_lines
            })
    
    return entries


def reconstruct_srt(entries):
    """
    Reconstruct SRT content from parsed entries.
    """
    srt_lines = []
    for entry in entries:
        srt_lines.append(entry['number'])
        srt_lines.append(entry['timestamp'])
        srt_lines.extend(entry['text'])
        srt_lines.append('')  # Blank line between entries
    
    return '\n'.join(srt_lines)


def translate_text(text, source_lang, target_lang, model, api_key):
    """
    Translate text using Gemini API.
    
    Args:
        text: Text to translate (str)
        source_lang: Source language (str)
        target_lang: Target language (str)
        model: Gemini model name (str)
        api_key: Gemini API key (str)
    
    Returns:
        Translated text (str)
    """
    prompt = (
        f"Translate the following subtitle text from {source_lang} to {target_lang}. "
        f"Maintain the exact same structure and formatting. "
        f"Only translate the natural language text content. "
        f"Preserve any special characters, punctuation, and line breaks.\n\n"
        f"Content to translate:\n{text}"
    )
    
    payload = {
        "contents": [{
            "parts": [{
                "text": prompt
            }]
        }]
    }
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    
    try:
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            url,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(req) as response:
            response_data = json.loads(response.read().decode('utf-8'))
            
            # Check for API errors
            if 'error' in response_data:
                error_msg = response_data['error'].get('message', str(response_data['error']))
                raise Exception(f"Gemini API error: {error_msg}")
            
            # Extract translated text
            if 'candidates' not in response_data or not response_data['candidates']:
                raise Exception("No translation returned from API")
            
            translated_text = response_data['candidates'][0]['content']['parts'][0]['text']
            
            # Remove markdown code fences if present
            translated_text = translated_text.strip()
            if translated_text.startswith('```'):
                lines = translated_text.split('\n')
                if lines[0].startswith('```'):
                    lines = lines[1:]
                if lines and lines[-1].strip() == '```':
                    lines = lines[:-1]
                translated_text = '\n'.join(lines).strip()
            
            return translated_text
            
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        try:
            error_data = json.loads(error_body)
            error_msg = error_data.get('error', {}).get('message', error_body)
        except:
            error_msg = error_body
        raise Exception(f"HTTP error {e.code}: {error_msg}")
    except urllib.error.URLError as e:
        raise Exception(f"Network error: {e.reason}")


def translate_srt_file(input_file, output_file, source_lang, target_lang, model, api_key_file):
    """
    Translate an SRT file and write the result to output_file.
    """
    # Read API key
    if not os.path.exists(api_key_file):
        print(f"Error: API key file not found: {api_key_file}", file=sys.stderr)
        print(f"Create it with your Gemini API key before running translation.", file=sys.stderr)
        print(f'Example: echo "<your-key>" > {api_key_file}', file=sys.stderr)
        sys.exit(1)
    
    with open(api_key_file, 'r') as f:
        api_key = f.read().strip()
    
    # Read input SRT file
    if not os.path.exists(input_file):
        print(f"Error: Input file not found: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    with open(input_file, 'r', encoding='utf-8') as f:
        srt_content = f.read()
    
    # Parse SRT file
    entries = parse_srt(srt_content)
    
    if not entries:
        print("Error: No subtitle entries found in SRT file", file=sys.stderr)
        sys.exit(1)
    
    print(f"Found {len(entries)} subtitle entries. Translating...", file=sys.stderr)
    
    # Translate each entry's text
    for i, entry in enumerate(entries, 1):
        # Combine text lines for translation
        original_text = '\n'.join(entry['text'])
        
        if not original_text.strip():
            # Skip empty entries
            continue
        
        print(f"Translating entry {i}/{len(entries)}...", file=sys.stderr, end='\r')
        
        try:
            # Translate the text
            translated_text = translate_text(original_text, source_lang, target_lang, model, api_key)
            
            # Split translated text back into lines
            # Preserve the number of lines if possible
            translated_lines = [line.strip() for line in translated_text.split('\n') if line.strip()]
            
            # If translation changed line count, try to preserve original structure
            if len(translated_lines) != len(entry['text']):
                # Use translated text as-is, split by newlines
                entry['text'] = translated_lines if translated_lines else [translated_text]
            else:
                entry['text'] = translated_lines
            
        except Exception as e:
            print(f"\nError translating entry {i}: {e}", file=sys.stderr)
            # Keep original text on error
            continue
    
    print(f"\nTranslation completed. Writing output...", file=sys.stderr)
    
    # Reconstruct SRT file
    translated_srt = reconstruct_srt(entries)
    
    # Create output directory if needed
    output_dir = os.path.dirname(output_file)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)
    
    # Write translated SRT file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(translated_srt)
    
    print(f"Translation completed: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description='Translate SRT subtitle files using Gemini API'
    )
    parser.add_argument('input_file', help='Input SRT file path')
    parser.add_argument('output_file', help='Output SRT file path')
    parser.add_argument('source_lang', help='Source language (e.g., Japanese, English)')
    parser.add_argument('target_lang', help='Target language (e.g., Traditional Chinese)')
    parser.add_argument(
        '--model',
        default='gemini-2.5-flash',
        help='Gemini model name (default: gemini-2.5-flash)'
    )
    parser.add_argument(
        '--api-key-file',
        default='.api_key',
        help='Path to API key file (default: .api_key)'
    )
    
    args = parser.parse_args()
    
    translate_srt_file(
        args.input_file,
        args.output_file,
        args.source_lang,
        args.target_lang,
        args.model,
        args.api_key_file
    )


if __name__ == '__main__':
    main()
