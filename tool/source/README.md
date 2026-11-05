# Development capture provenance

The original pages were loaded in a real browser on 2026-11-02 after direct HTTP
requests hit a Cloudflare challenge. No challenge was bypassed or stored as data.
The browser returned 31 `.zekr-row` nodes for morning and 30 for evening.
For each row, capture used:

- text: `.zekr.innerText.trim()`
- repeat: `Number(.count-down.getAttribute('data-count'))`
- source: `.zekr .text-muted.textContent.trim()` or empty string
- virtue: `.zekrbless-content.textContent.trim()`, falling back to `.zekrbless`
- id: row position, starting at 1

For each original item, the browser independently fingerprinted
`JSON.stringify([text, repeat, source, virtue])` using UTF-16 FNV-1a.
Every captured item in `tool/capture_content.py` matches that fingerprint.
Original text is never Unicode-normalized, spell-corrected, or stripped of tashkeel.
`innerText` reflects visible paragraph spacing rather than HTML indentation.

## All-category extension

`categories_capture.json` follows every azkar link observed in the exact
`.card-body.text-primary-emphasis` menu. Only the standalone `القرآن` link
(`/quran`) was excluded. It captures 27 categories and 315 entries in menu order.
The original morning/evening collections compare equal to the earlier capture.
Each page was navigated and its accessibility/DOM state checked before reading
its `#azkar-list-panel .zekr-row` nodes. No guessed category URLs were used.

The aggregate browser data was exported as plain UTF-8 JSON through TextEdit,
without retyping Arabic. Every imported string is checked against the browser's
UTF-16 FNV-1a fingerprint. Source repetitions of zero are preserved verbatim and
represented in the app as manual reading completion, not a religious repeat count.

Use `python3 tool/import_categories.py --check` to verify all captures and assets;
without `--check`, it regenerates the JSON assets, catalog, and category enum.
