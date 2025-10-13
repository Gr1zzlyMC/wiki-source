#!/bin/bash

# Two-way sync between GitHub and MediaWiki (Bash version)
# This script helps you sync pages in both directions

echo "Two-Way Wiki Sync Script"
echo "========================"
echo ""
echo "This script will help you sync between GitHub and MediaWiki"
echo ""

# Menu
echo "Select sync direction:"
echo "1. Pull from MediaWiki to GitHub (download all wiki pages)"
echo "2. Push from GitHub to MediaWiki (upload local changes)"
echo "3. Full sync (pull then push - recommended)"
echo "4. Exit"
echo ""

read -p "Enter your choice (1-4): " choice

if [ "$choice" = "4" ]; then
    echo "Exiting..."
    exit 0
fi

# Get credentials
echo ""
read -p "Enter your MediaWiki API URL (e.g., https://wiki.example.com/api.php): " WIKI_API
read -p "Enter your MediaWiki username: " WIKI_USER
read -sp "Enter your MediaWiki password (or bot password): " WIKI_PASS
echo ""
echo ""

# Extract base URL
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

# Check git repository
if [ ! -d .git ]; then
    echo "Error: Not in a git repository. Please run 'git init' first."
    exit 1
fi

# Setup MediaWiki remote
if git remote | grep -q "^wiki$"; then
    git remote set-url wiki "$MEDIAWIKI_REMOTE" 2>/dev/null
else
    git remote add wiki "$MEDIAWIKI_REMOTE" 2>/dev/null
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$CURRENT_BRANCH" = "HEAD" ] || [ -z "$CURRENT_BRANCH" ]; then
    echo "Creating 'main' branch..."
    git checkout -b main
    CURRENT_BRANCH="main"
fi

# Function to pull from MediaWiki
pull_from_mediawiki() {
    echo ""
    echo "=== PULLING FROM MEDIAWIKI ==="
    echo "Fetching all pages from MediaWiki..."
    echo ""
    
    if git fetch wiki; then
        echo ""
        echo "✓ Successfully fetched from MediaWiki!"
        echo ""
        echo "Merging MediaWiki pages into $CURRENT_BRANCH..."
        
        if git merge wiki/master --allow-unrelated-histories -m "Sync from MediaWiki"; then
            echo ""
            echo "✓ Successfully merged MediaWiki pages!"
            return 0
        else
            echo ""
            echo "⚠ Merge conflict. Please resolve conflicts manually."
            return 1
        fi
    else
        echo ""
        echo "✗ Failed to fetch from MediaWiki"
        return 1
    fi
}

# Function to push to MediaWiki
push_to_mediawiki() {
    echo ""
    echo "=== PUSHING TO MEDIAWIKI ==="
    echo "Pushing changes to MediaWiki..."
    echo ""
    
    if git push wiki ${CURRENT_BRANCH}:refs/heads/master; then
        echo ""
        echo "✓ Successfully pushed to MediaWiki!"
        return 0
    else
        echo ""
        echo "✗ Failed to push to MediaWiki"
        return 1
    fi
}

# Execute based on choice
case "$choice" in
    1)
        # Pull only
        if pull_from_mediawiki; then
            echo ""
            echo "Next step: Push to GitHub with 'git push origin $CURRENT_BRANCH'"
        fi
        ;;
    2)
        # Push only
        if push_to_mediawiki; then
            echo ""
            echo "✓ Changes are now live on MediaWiki!"
        fi
        ;;
    3)
        # Full sync
        echo "Starting full two-way sync..."
        
        # First pull from MediaWiki
        if pull_from_mediawiki; then
            # Then push to MediaWiki (in case we had local changes)
            if push_to_mediawiki; then
                echo ""
                echo "=== SYNCING TO GITHUB ==="
                echo "Pushing to GitHub..."
                
                # Check if origin remote exists
                if git remote | grep -q "^origin$"; then
                    if git push origin $CURRENT_BRANCH; then
                        echo ""
                        echo "✓ Successfully pushed to GitHub!"
                        echo ""
                        echo "🎉 Full sync complete! All repositories are now in sync."
                    else
                        echo ""
                        echo "⚠ Failed to push to GitHub. You may need to set up the remote first:"
                        echo "  git remote add origin <your-github-repo-url>"
                    fi
                else
                    echo ""
                    echo "⚠ No GitHub remote found. Add it with:"
                    echo "  git remote add origin <your-github-repo-url>"
                    echo "  git push -u origin $CURRENT_BRANCH"
                fi
            fi
        fi
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo ""
echo "========================"
echo "Sync operation complete!"
echo ""

