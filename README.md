# MediaWiki to GitHub Sync

Simple tool to export all pages from MediaWiki and sync them to a GitHub repository.

## Requirements

- Python 3.6+
- `requests` library: `pip install requests`
- Git installed and configured

## Quick Start

1. **Install Python dependencies:**
   ```bash
   pip install requests
   ```

2. **Run the export script:**
   ```bash
   python export-to-git.py
   ```

3. **Follow the prompts:**
   - Enter your MediaWiki API URL (e.g., `https://wiki.example.com/api.php`)
   - Enter your username
   - Enter your password (or [bot password](https://www.mediawiki.org/wiki/Manual:Bot_passwords) - recommended)
   - Choose output directory (default: `pages/`)

4. **Set up GitHub remote (first time only):**
   ```bash
   git remote add origin https://github.com/yourusername/your-repo.git
   git push -u origin main
   ```

## What It Does

1. ✅ Logs into your MediaWiki instance
2. ✅ Fetches list of all pages
3. ✅ Downloads content for each page
4. ✅ Saves each page as a `.mediawiki` file
5. ✅ Commits changes to git
6. ✅ Pushes to GitHub (if remote configured)

## Output Structure

```
pages/
  ├── Main_Page.mediawiki
  ├── Help_Contents.mediawiki
  ├── Project_Guidelines.mediawiki
  └── ...
```

## Bot Passwords (Recommended)

For security, use bot passwords instead of your main password:

1. Go to `Special:BotPasswords` on your wiki
2. Create a new bot password with these rights:
   - ✅ High-volume editing
   - ✅ Edit existing pages
   - ✅ Create, edit, and move pages
3. Use the bot username and password when prompted

## Automation

### GitHub Actions (Automated Sync)

Want automatic syncing every day? Add this workflow file:

`.github/workflows/sync-wiki.yml`

```yaml
name: Sync from MediaWiki

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:  # Manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'
      
      - name: Install dependencies
        run: pip install requests
      
      - name: Sync from MediaWiki
        env:
          WIKI_API: ${{ secrets.WIKI_API }}
          WIKI_USER: ${{ secrets.WIKI_USER }}
          WIKI_PASS: ${{ secrets.WIKI_PASS }}
        run: |
          python export-to-git-auto.py
      
      - name: Push changes
        run: |
          git config user.name "Wiki Sync Bot"
          git config user.email "bot@example.com"
          git add .
          git diff --cached --quiet || git commit -m "Auto-sync from MediaWiki [$(date)]"
          git push
```

### Required Secrets

Add these to your GitHub repository settings (Settings → Secrets):
- `WIKI_API` - Your MediaWiki API URL
- `WIKI_USER` - Your username
- `WIKI_PASS` - Your password or bot password

## Alternative: Manual Export

You can also use MediaWiki's Special:Export:

1. Go to `Special:Export` on your wiki
2. Check "Include only the current revision"
3. Add all page names
4. Click "Export"
5. Save the XML file
6. Use a parser to convert XML to individual files

## Comparison of Methods

| Method | Pros | Cons |
|--------|------|------|
| **This Script** | ✅ Simple<br>✅ No server access needed<br>✅ Works with any MediaWiki | ❌ One-way sync only |
| **PageSync Extension** | ✅ Two-way sync<br>✅ Server-side automation | ❌ Requires server access<br>❌ Extension installation |
| **git-mediawiki** | ✅ Two-way sync<br>✅ Git-like workflow | ❌ Requires Perl<br>❌ Complex setup on Windows |

## Troubleshooting

### "Login failed"
- Check your username and password
- Try using a bot password instead
- Verify the API URL is correct

### "No changes to commit"
- Pages haven't changed since last sync
- This is normal!

### "Push failed"
- Set up git remote: `git remote add origin <url>`
- Or push manually: `git push -u origin main`

## License

Free to use and modify as needed!

