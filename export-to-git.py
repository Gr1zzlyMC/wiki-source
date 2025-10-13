#!/usr/bin/env python3
"""
MediaWiki Export to Git
Downloads all pages from MediaWiki's Special:Export and commits them to git
"""

import requests
import xml.etree.ElementTree as ET
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import urljoin

def sanitize_filename(title):
    """Convert MediaWiki page title to safe filename"""
    # Replace problematic characters
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

def git_commit_and_push(message="Sync from MediaWiki"):
    """Commit changes and push to git"""
    print("\nCommitting changes to git...")
    
    # Check if we're in a git repo
    result = subprocess.run(['git', 'status'], capture_output=True)
    if result.returncode != 0:
        print("Initializing git repository...")
        subprocess.run(['git', 'init'])
        subprocess.run(['git', 'branch', '-M', 'main'])
    
    # Add all changes
    subprocess.run(['git', 'add', '.'])
    
    # Check if there are changes to commit
    result = subprocess.run(['git', 'diff', '--cached', '--quiet'])
    if result.returncode != 0:
        # There are changes
        subprocess.run(['git', 'commit', '-m', message])
        print("✓ Changes committed!")
        
        # Try to push
        print("Pushing to remote...")
        result = subprocess.run(['git', 'push'], capture_output=True)
        if result.returncode == 0:
            print("✓ Pushed to remote!")
        else:
            print("⚠ Push failed. You may need to set up remote:")
            print("  git remote add origin <your-repo-url>")
            print("  git push -u origin main")
    else:
        print("No changes to commit")

def main():
    print("=" * 60)
    print("MediaWiki Export to Git")
    print("=" * 60)
    print()
    
    # Get configuration
    api_url = input("MediaWiki API URL (e.g., https://wiki.example.com/api.php): ").strip()
    username = input("Username: ").strip()
    password = input("Password (or bot password): ").strip()
    output_dir = input("Output directory (default: pages): ").strip() or "pages"
    
    print()
    
    # Get all pages
    result = get_all_pages(api_url, username, password)
    if result is None:
        print("Failed to get pages. Exiting.")
        sys.exit(1)
    
    pages, session = result
    
    # Export pages
    export_pages(api_url, pages, session, output_dir)
    
    # Git operations
    git_commit_and_push()
    
    print()
    print("=" * 60)
    print("✓ Sync complete!")
    print("=" * 60)

if __name__ == '__main__':
    main()

