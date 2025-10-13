#!/bin/bash

# Pull all pages from MediaWiki to local Git repository
# This script fetches all pages from your MediaWiki and converts them to files

echo "MediaWiki to GitHub Sync Script"
echo "================================"
echo ""

# Prompt for credentials
read -p "Enter your MediaWiki API URL (e.g., https://wiki.example.com/api.php): " WIKI_API
read -p "Enter your MediaWiki username: " WIKI_USER
read -sp "Enter your MediaWiki password (or bot password): " WIKI_PASS
echo ""
echo ""

# Extract base URL from API URL
SCHEME="${WIKI_API%%://*}"
REST="${WIKI_API#*://}"
REST="${REST%%\?*}"
REST="${REST%%#*}"
REST="${REST%/api.php}"
REST="${REST%/index.php}"
REST="${REST%/}"

BASE_URL="${SCHEME}://${REST}"
MEDIAWIKI_REMOTE="mediawiki::${SCHEME}://${WIKI_USER}:${WIKI_PASS}@${REST}"

echo "Base URL: $BASE_URL"
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "Error: Not in a git repository. Please run 'git init' first."
    exit 1
fi

# Check if mediawiki remote already exists
if git remote | grep -q "^wiki$"; then
    echo "MediaWiki remote 'wiki' already exists. Updating..."
    git remote set-url wiki "$MEDIAWIKI_REMOTE"
else
    echo "Adding MediaWiki remote as 'wiki'..."
    git remote add wiki "$MEDIAWIKI_REMOTE"
fi

echo ""
echo "Fetching all pages from MediaWiki..."
echo "This may take a while depending on the number of pages..."
echo ""

# Fetch from MediaWiki
if git fetch wiki; then
    echo ""
    echo "✓ Successfully fetched from MediaWiki!"
    echo ""
    
    # Show what branches are available
    echo "Available MediaWiki branches:"
    git branch -r | grep wiki/
    echo ""
    
    # Check if we're on a branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    if [ "$CURRENT_BRANCH" = "HEAD" ] || [ -z "$CURRENT_BRANCH" ]; then
        echo "No local branch detected. Creating 'main' branch..."
        git checkout -b main
        CURRENT_BRANCH="main"
    fi
    
    # Merge or pull the master branch from MediaWiki
    echo "Merging MediaWiki pages into current branch ($CURRENT_BRANCH)..."
    echo ""
    
    if git merge wiki/master --allow-unrelated-histories; then
        echo ""
        echo "✓ Successfully merged MediaWiki pages!"
        echo ""
        echo "Pages have been downloaded to your local repository."
        echo ""
        echo "Next steps:"
        echo "1. Review the downloaded files: ls -la"
        echo "2. Push to GitHub: git push origin $CURRENT_BRANCH"
        echo ""
    else
        echo ""
        echo "⚠ Merge conflict occurred. You may need to resolve conflicts manually."
        echo "After resolving conflicts, run:"
        echo "  git add ."
        echo "  git commit -m 'Merged pages from MediaWiki'"
        echo "  git push origin $CURRENT_BRANCH"
        echo ""
    fi
else
    echo ""
    echo "✗ Failed to fetch from MediaWiki"
    echo ""
    echo "Possible issues:"
    echo "1. git-remote-mediawiki is not installed"
    echo "2. Incorrect credentials"
    echo "3. MediaWiki API is not accessible"
    echo ""
    echo "To install git-remote-mediawiki:"
    echo "  - On Linux/Mac: Install perl-MediaWiki-API package"
    echo "  - Add git-remote-mediawiki to your PATH"
    exit 1
fi

