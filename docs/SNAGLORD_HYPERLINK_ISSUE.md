# Issue: OSC 8 Hyperlinks Terminated by ST (`\x1b\`) Cause Text / Filenames to be Swallowed in Snaglord Output

## Target Repositories

- **Primary bug location (`ansi-to-tui`)**: https://github.com/ratatui/ansi-to-tui
- **Upstream consumer (`tmux-snaglord`)**: https://github.com/raine/tmux-snaglord

---

## Suggested Issue Title

> `OSC escape sequences terminated with ST (\x1b\) swallow subsequent text until next BEL or EOF`

---

## Problem Summary

When terminal output containing OSC 8 hyperlinks (e.g. from Nushell `ls`, `eza --hyperlink`, `ls --hyperlink`, or custom CLI tools) is captured and parsed into Ratatui `Text` using `ansi-to-tui`, the link text (e.g. filename) and all subsequent columns on the line are completely missing from the rendered TUI output.

In `tmux-snaglord`:
- Commands like `ll` (aliased to `eza --icons --hyperlink`) display permissions, file sizes, timestamps, and icons, but the filenames immediately following the icons are completely eaten and blank.
- In Nushell, `ls` displays the table borders, headers, and row numbers (`0`, `1`, ...), but the filenames and all subsequent table columns (`type`, `size`, `modified`) are completely eaten and blank because each filename is wrapped in an OSC 8 hyperlink by default.

---

## Root Cause

In `ansi-to-tui` (`src/parser.rs`), `any_escape_sequence` attempts to discard non-SGR escape sequences. However, it assumes all OSC sequences (`\x1b]`) are terminated strictly by the ASCII Bell character (`\x07` / `BEL`):

```rust
fn any_escape_sequence(s: &[u8]) -> IResult<&[u8], Option<&[u8]>> {
    let (input, garbage) = preceded(
        char('\x1b'),
        opt(alt((
            delimited(char('['), take_till(AsChar::is_alpha), opt(take(1u8))),
            delimited(char(']'), take_till(|c| c == b'\x07'), opt(take(1u8))),
        ))),
    )
    .parse(s)?;
    Ok((input, garbage))
}
```

According to ECMA-48 and the OSC 8 hyperlink specification, OSC escape sequences can be terminated by either:
1. **BEL**: `\x07` (`\a`)
2. **ST (String Terminator)**: `ESC \` (`\x1b\\`)

When tools like Nushell or `eza` emit OSC 8 hyperlinks, they use standard ST termination:
```text
\x1b]8;;file:///path/to/file\x1b\filename\x1b]8;;\x1b\
```

Because `ansi-to-tui` only looks for `\x07`, `take_till(|c| c == b'\x07')` fails to stop at `\x1b\`. It continues consuming bytes across `filename\x1b]8;;\x1b\` until it hits an unrelated `\x07` or reaches the end of the line / EOF. As a result, the entire filename and subsequent text is treated as garbage and discarded.

---

## Minimal Reproducible Example

```rust
use ansi_to_tui::IntoText;

fn main() {
    // Standard OSC 8 hyperlink terminated with ST (\x1b\)
    let input = b"\x1b]8;;https://example.com\x1b\\clickable_text\x1b]8;;\x1b\\";
    
    let text = input.into_text().unwrap();
    
    // Expected: Text containing a Span with content "clickable_text"
    // Actual: Empty Text / Span content is swallowed
    println!("Parsed: {:?}", text);
}
```

---

## Mitigation in Nushell (`sc-nu`)

To avoid triggering this upstream parser bug while preserving syntax highlighting, file type colors, sizes, and timestamps, disable OSC 8 clickable links in `$env.config`:

```nu
$env.config = {
    # ...
    ls: {
        use_ls_colors: true
        clickable_links: false
    }
    shell_integration: {
        osc8: false
    }
}
```
