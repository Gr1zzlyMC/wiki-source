# MediaWiki ↔ GitHub Two-Way Sync Guide

This guide explains how to sync your wiki pages between MediaWiki and GitHub in both directions.

## Quick Start

### Option 1: Full Two-Way Sync (Recommended)

Run this to sync everything automatically:

**Windows (PowerShell):**
```powershell
.\sync-both-ways.ps1
```

**Linux/Mac (Bash):**
```bash
./sync-both-ways.sh
```

Choose option 3 for full sync.

### Option 2: Pull MediaWiki → GitHub

To download all pages from your MediaWiki into GitHub:

**Windows:**
```powershell
.\pull-from-mediawiki.ps1
```

**Linux/Mac:**
```bash
./pull-from-mediawiki.sh
```

Then push to GitHub:
```bash
git push origin main
```

### Option 3: Push GitHub → MediaWiki

If you already have pages in your GitHub repo and want to push them to MediaWiki:

```bash
# Make sure you have the wiki remote set up
git remote add wiki mediawiki::https://USERNAME:PASSWORD@your-wiki-url.com

# Push to MediaWiki
git push wiki main:refs/heads/master
```

## Understanding the Sync Process

### How it Works

1. **MediaWiki Pages** are stored in MediaWiki database
2. **git-remote-mediawiki** acts as a bridge, converting pages to/from git commits
3. **Local Git Repo** is your working directory
4. **GitHub** stores your backup/version control

### Sync Flow

```
MediaWiki ←→ git-remote-mediawiki ←→ Local Git ←→ GitHub
```

## Common Workflows

### Daily Editing Workflow

1. Make changes on MediaWiki (edit pages via web interface)
2. Pull changes to GitHub:
   ```powershell
   .\pull-from-mediawiki.ps1
   git push origin main
   ```

### Batch Editing Workflow

1. Edit `.mw` files locally in your editor
2. Commit changes:
   ```bash
   git add .
   git commit -m "Updated documentation"
   ```
3. Push to both:
   ```bash
   git push wiki main:refs/heads/master  # Push to MediaWiki
   git push origin main                   # Push to GitHub
   ```

### Complete Sync (When in Doubt)

Run the full sync script and choose option 3:
```powershell
.\sync-both-ways.ps1
```

This will:
1. Pull all pages from MediaWiki
2. Merge with local changes
3. Push everything back to MediaWiki
4. Push everything to GitHub

## File Format

- MediaWiki pages are stored as `.mw` files
- File name = Page title (with spaces and special chars)
- Content is in MediaWiki markup syntax

Example:
- `Main_Page.mw` = "Main Page" on wiki
- `Help:Contents.mw` = "Help:Contents" page

## Troubleshooting

### "git-remote-mediawiki not found"

**Windows:**
1. Install [Strawberry Perl](http://strawberryperl.com/) or [ActivePerl](https://www.activestate.com/products/perl/)
2. Install MediaWiki API module:
   ```
   cpan MediaWiki::API
   ```
3. Add git-remote-mediawiki to PATH

**Linux:**
```bash
sudo apt-get install libmediawiki-api-perl
# or
sudo yum install perl-MediaWiki-API
```

**Mac:**
```bash
brew install perl
cpan MediaWiki::API
```

### "Authentication Failed"

1. Use a **bot password**, not your regular account password
2. Create bot password in MediaWiki:
   - Go to Special:BotPasswords
   - Create new bot password with "Create/Edit pages" permission
   - Use the generated password in the scripts

### "Merge Conflicts"

If you edited the same page in both places:

1. Git will show conflict markers in the `.mw` file
2. Edit the file to resolve conflicts
3. Complete the merge:
   ```bash
   git add .
   git commit -m "Resolved merge conflicts"
   git push wiki main:refs/heads/master
   git push origin main
   ```

### "Nothing to Push"

If it says there's nothing to push to MediaWiki:
- Make sure you've committed your changes locally first
- MediaWiki remote only sees committed changes, not uncommitted files

## Advanced: Automatic Sync

### GitHub Actions (Coming Soon)

You can set up GitHub Actions to automatically sync changes every hour:

```yaml
# .github/workflows/sync-wiki.yml
name: Sync MediaWiki
on:
  schedule:
    - cron: '0 * * * *'  # Every hour
  workflow_dispatch:      # Manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Pull from MediaWiki
        run: |
          # Setup git-remote-mediawiki
          # Pull from MediaWiki
          # Push to GitHub
```

## Scripts Reference

| Script | Purpose | Platform |
|--------|---------|----------|
| `sync-both-ways.ps1` | Interactive two-way sync | Windows/PowerShell |
| `pull-from-mediawiki.ps1` | Pull MediaWiki → Local | Windows/PowerShell |
| `pull-from-mediawiki.sh` | Pull MediaWiki → Local | Linux/Mac/Bash |
| `test-mediawiki-connection.sh` | Test credentials & API | Linux/Mac/Bash |

## Security Notes

⚠️ **Important:** Never commit credentials to git!

- Scripts prompt for passwords (not saved)
- Use bot passwords (not your main account password)
- Consider using environment variables for automation
- Add to `.gitignore`:
  ```
  .env
  credentials.txt
  ```

## Need Help?

1. Test your connection first: `.\test-mediawiki-connection.sh`
2. Check MediaWiki logs: Special:Log
3. Check git status: `git status`
4. See what remotes are configured: `git remote -v`

## Next Steps

After syncing successfully:

1. ✅ Set up regular sync schedule (daily/weekly)
2. ✅ Configure GitHub Actions for automation
3. ✅ Document your wiki structure
4. ✅ Train team on the workflow
5. ✅ Set up branch protection rules on GitHub

