#!/usr/bin/env python3
"""
MediaWiki Export - ALL Namespaces (Templates, Categories, etc.)
Downloads pages from all namespaces including templates, categories, help pages, etc.
"""

import requests
import os
import sys
from pathlib import Path

def sanitize_filename(title):
    """Convert MediaWiki page title to safe filename"""
    safe = title.replace('/', '_').replace('\\', '_').replace(':', '_')
    safe = safe.replace('*', '_').replace('?', '_').replace('"', '_')
    safe = safe.replace('<', '_').replace('>', '_').replace('|', '_')
    return safe

def get_namespaces(api_url):
    """Get all available namespaces from the wiki"""
    print("Fetching namespaces...")
    response = requests.get(api_url, params={
        'action': 'query',
        'meta': 'siteinfo',
        'siprop': 'namespaces',
        'format': 'json'
    }).json()
    
    namespaces = response['query']['namespaces']
    # Filter out negative namespace IDs (Special, Media) as they can't be exported
    valid_namespaces = {k: v for k, v in namespaces.items() if int(k) >= 0}
    
    print(f"Found {len(valid_namespaces)} exportable namespaces:")
    for ns_id, ns_info in sorted(valid_namespaces.items(), key=lambda x: int(x[0])):
        ns_name = ns_info.get('*', '(Main)')
        print(f"  [{ns_id}] {ns_name}")
    
    return valid_namespaces

def login(api_url, username, password):
    """Login to MediaWiki and return session"""
    session = requests.Session()
    
    print("\nLogging in to MediaWiki...")
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
    
    print("Login successful!")
    return session

def get_pages_in_namespace(api_url, session, namespace_id):
    """Get all pages in a specific namespace"""
    pages = []
    apcontinue = None
    
    while True:
        params = {
            'action': 'query',
            'list': 'allpages',
            'apnamespace': namespace_id,
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
    
    return pages

def export_all_pages(api_url, session, namespaces, output_dir):
    """Export pages from all namespaces"""
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    total_pages = 0
    
    for ns_id, ns_info in sorted(namespaces.items(), key=lambda x: int(x[0])):
        ns_name = ns_info.get('*', 'Main')
        if not ns_name:
            ns_name = 'Main'
        
        print(f"\n[Namespace {ns_id}: {ns_name}]")
        print("Fetching page list...")
        
        pages = get_pages_in_namespace(api_url, session, ns_id)
        
        if not pages:
            print(f"  No pages found")
            continue
        
        print(f"  Found {len(pages)} pages")
        
        # Create namespace directory
        ns_dir = output_path / sanitize_filename(ns_name)
        ns_dir.mkdir(exist_ok=True)
        
        # Export each page
        for i, page in enumerate(pages, 1):
            title = page['title']
            print(f"  [{i}/{len(pages)}] Exporting: {title}")
            
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
                
                # Save to file (use title without namespace prefix for filename)
                # But keep the full title in the comment
                page_title_only = title.split(':', 1)[-1] if ':' in title else title
                safe_title = sanitize_filename(page_title_only)
                file_path = ns_dir / f"{safe_title}.mediawiki"
                
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(f"<!-- Page: {title} -->\n")
                    f.write(content)
                
                total_pages += 1
            else:
                print(f"    (no content)")
    
    print(f"\n" + "="*60)
    print(f"Exported {total_pages} pages total!")
    print(f"="*60)

def main():
    print("="*60)
    print("MediaWiki Full Export - All Namespaces")
    print("="*60)
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
    
    # Get namespaces
    namespaces = get_namespaces(api_url)
    
    # Login
    session = login(api_url, username, password)
    if not session:
        print("Failed to login. Exiting.")
        sys.exit(1)
    
    # Export all pages
    export_all_pages(api_url, session, namespaces, output_dir)
    
    print()
    print("Note: Special pages (Special:*) cannot be exported as they are")
    print("      dynamically generated by MediaWiki.")
    print()

if __name__ == '__main__':
    main()

