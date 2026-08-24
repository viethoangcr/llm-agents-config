---
name: text-compress
description: >
  Compress any text or document (articles, README, notes, instructions) to the
  fewest words possible while staying human-friendly to read. All information,
  facts, and instructions must stay exactly the same. No pleasantries, no
  hedging, simple words. Trigger when user asks to compress, shorten, tighten,
  or condense text or a document.
---

# Text Compress

## Purpose

Compress natural-language text to minimal word count without losing any information. Output stays readable by a human — plain, direct, no fluff. Grammar stays natural where a shorter form does not read well.

## Input

- User gives a file path, pasted text, or a URL to fetch.
- If nothing given, ask for the source.

## Output

- Compress in place: overwrite the source file with the compressed version.
- Before overwriting, copy the original to `<source>.original.md` (next to the source). If a `<source>.original.md` already exists, keep it — the original must never be lost.
- If input is pasted text (no file), print the compressed result.
- Show a word-count summary: `before → after` (words) and `% reduction`.

## Compression Rules

### Remove
- Articles where safe: "the", "a", "an"
- Filler: just, really, basically, actually, simply, essentially, generally, very, quite
- Pleasantries: "sure", "of course", "happy to", "please note", "I'd recommend", "let me know"
- Hedging: "it might be worth", "you could consider", "it may be", "possibly", "perhaps"
- Redundant phrasing: "in order to" → "to", "make sure to" → "ensure", "the reason is because" → "because", "each and every" → "each"
- Connective fluff: "however", "furthermore", "additionally", "in addition", "moreover", "on the other hand"
- Meta sentences that describe the document itself: "This document describes", "In this section, we will cover"

### Preserve EXACTLY
- Numbers, dates, versions, percentages, units (never round or approximate)
- Proper nouns: names, products, company names, project names
- Commands, file paths, code blocks, inline code, URLs
- Technical terms, protocols, algorithms, library/API names
- Negations and qualifiers: do not drop a "not", "never", "only", "may", "must" — that changes meaning
- Lists of steps with ordering meaning (do not merge or reorder)

### Keep Human-Friendly
- Output reads as normal English, just stripped. No telegram fragments unless the shorter form is fully readable.
- One thought per sentence; drop filler words, keep verbs.
- Keep headings, bullet structure, numbered steps, and table structure. Compress cell text, keep rows.
- If two sentences say the same thing, keep one.
- If multiple examples show the same pattern, keep one.

### Style
- Prefer ASD-STE100 (Simplified Technical English): one word one meaning, short sentences, active voice, approve vocabulary. Use it as the default when compressing technical text.
- One word over a phrase with the same meaning: "utilize" → "use", "in the event of" → "if", "prior to" → "before", "in order to" → "to", "make sure to" → "ensure"
- Active voice, present tense
- Imperative for instructions: "Run tests" not "You should run tests"

## Verification

After compressing, self-check:

1. Every fact, number, name, and instruction from the source is present in the output — no deletions except fluff.
2. No negation changed, no qualification weakened.
3. Output reads naturally, no broken grammar.
4. If a step, warning, or constraint feels lost, it was lost — restore it or stop and ask.

## Ground Rules

- NEVER change meaning to shorten. When in doubt, keep the longer version.
- NEVER alter code, commands, paths, URLs, or technical specs inside the text.
- NEVER add interpretation, summaries, or new words; you only remove.
- PREFER removing words over rephrasing.

## Example

Before:

> This document describes how to set up the dev environment on a new machine. It is important to note that you should always ensure Node.js version 20 or higher is installed, because older versions may not support the latest syntax. If you run into issues, it might be worth checking the troubleshooting section.

After:

> Set up dev environment on a new machine. Install Node.js 20+. Older versions may not support latest syntax. Check troubleshooting for issues.