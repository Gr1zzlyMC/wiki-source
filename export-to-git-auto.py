#!/usr/bin/env python3
"""
MediaWiki Export to Git (Automated version for CI/CD)
Reads configuration from environment variables
"""

import requests
import xml.etree.ElementTree as ET
import os
import subprocess
import sys
from pathlib import Path

def sanitize_filename(title):
    """Convert MediaWiki page title to safe filename"""
    safe = title.replace('/', '_').replace('\\', '_').replace(':', '_')
    safe = safe.replace('*', '_').replace('?', '_').replace('"', '_')
    safe = safe.replace('<', '_').replace('>', '_').replace('|', '_')
    return safe

def get_all_pages(api_url, username, password):
    """Get list of all pages from MediaWiki API"""
    session = requests.Session()
    
    # Login
    print("Logging in to MediaWiki...")
    login_token = session.get(api_url, params={
        'action': 'query',
        'meta': 'tokens',
        'type': 'login',
        'format': 'json'
    }).json()
    
    login_response = session.post(api_url, data={
        'action': 'login',
        'lgname': username,
        'lgpassword': password,
        'lgtoken': login_token['query']['tokens']['logintoken'],
        'format': 'json'
    }).json()
    
    if login_response['login']['result'] != 'Success':
        print(f"Login failed: {login_response['login']['result']}")
        return None
    
    print("✓ Login successful!")
    
    # Get all pages
    print("Fetching list of all pages...")
    pages = []
    apcontinue = None
    
    while True:
        params = {
            'action': 'query',
            'list': 'allpages',
            'aplimit': '500',
            'format': 'json'
        }
        if apcontinue:
            params['apcontinue'] = apcontinue
        
        response = session.get(api_url, params=params).json()
        pages.extend(response['query']['allpages'])
        
        if 'continue' in response:
            apcontinue = response['continue']['apcontinue']
        else:
            break
    
    print(f"✓ Found {len(pages)} pages")
    return pages, session

def export_pages(api_url, pages, session, output_dir):
    """Export pages from MediaWiki and save as individual files"""
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    print(f"Exporting pages to {output_dir}...")
    
    for i, page in enumerate(pages, 1):
        title = page['title']
        print(f"[{i}/{len(pages)}] Exporting: {title}")
        
        # Get page content
        response = session.get(api_url, params={
            'action': 'query',
            'titles': title,
            'prop': 'revisions',
            'rvprop': 'content',
            'rvslots': 'main',
            'format': 'json'
        }).json()
        
        page_data = next(iter(response['query']['pages'].values()))
        
        if 'revisions' in page_data:
            content = page_data['revisions'][0]['slots']['main']['*']
            
            # Save to file
            safe_title = sanitize_filename(title)
            file_path = output_path / f"{safe_title}.mediawiki"
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(f"<!-- Page: {title} -->\n")
                f.write(content)
            
            print(f"  ✓ Saved to {file_path.name}")
        else:
            print(f"  ⚠ Skipped (no content)")
    
    print(f"\n✓ Exported {len(pages)} pages!")

def main():
    print("=" * 60)
    print("MediaWiki Export to Git (Automated)")
    print("=" * 60)
    print()
    
    # Get configuration from environment variables
    api_url = os.environ.get('WIKI_API')
    username = os.environ.get('WIKI_USER')
    password = os.environ.get('WIKI_PASS')
    output_dir = os.environ.get('OUTPUT_DIR', 'pages')
    
    if not api_url or not username or not password:
        print("Error: Missing required environment variables:")
        print("  WIKI_API - MediaWiki API URL")
        print("  WIKI_USER - Username")
        print("  WIKI_PASS - Password")
        sys.exit(1)
    
    print(f"API URL: {api_url}")
    print(f"Username: {username}")
    print(f"Output directory: {output_dir}")
    print()
    
    # Get all pages
    result = get_all_pages(api_url, username, password)
    if result is None:
        print("Failed to get pages. Exiting.")
        sys.exit(1)
    
    pages, session = result
    
    # Export pages
    export_pages(api_url, pages, session, output_dir)
    
    print()
    print("=" * 60)
    print("✓ Export complete!")
    print("=" * 60)

if __name__ == '__main__':
    main()

