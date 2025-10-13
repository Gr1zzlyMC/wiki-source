# CSS Audit

## Summary
- Located all Cascading Style Sheets sources, including MediaWiki interface pages that use the `.css.mediawiki` suffix.
- Confirmed the repository contains three CSS override pages: `Common.css`, `Minerva.css`, and `Mobile.css` under `pages/MediaWiki/`.
- Normalized the Minerva skin overrides to remove duplicate/conflicting declarations and added the missing newline terminator to `Mobile.css`.

## Command Output
```
$ find pages -name '*.css' -o -name '*.css.mediawiki'
pages/MediaWiki/Common.css.mediawiki
pages/MediaWiki/Mobile.css.mediawiki
pages/MediaWiki/Minerva.css.mediawiki
```

## Findings
### MediaWiki:Common.css
The global stylesheet provides typography resets, layout utilities, and reference styling that match Wikimedia defaults. No conflicting or duplicate declarations were detected during manual review.

### MediaWiki:Minerva.css
The Minerva skin overrides previously repeated several selectors with different values (e.g., `.minerva-header`, `.minerva-icon`, and `#searchInput`), which could lead to ordering conflicts. The file now consolidates each selector into a single rule block with consistent values, making the intended styling unambiguous.

### MediaWiki:Mobile.css
The mobile overrides strictly define a logo replacement for the header title. The stylesheet now ends with a newline to satisfy POSIX text file conventions, and no extraneous declarations were found.

## Conclusion
All CSS lives in the three MediaWiki override pages listed above. After deduplicating Minerva-specific rules and tidying the mobile stylesheet, no further conflicts or redundant code were identified.
