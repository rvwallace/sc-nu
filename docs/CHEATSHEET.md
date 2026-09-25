# Nushell Quick Reference & Migration Cheatsheet

A practical guide for engineers transitioning from POSIX shells (Zsh/Bash) to Nushell.

---

## 1. The Core Mental Model

In Zsh, commands communicate using **plain text byte streams** parsed with `grep`, `awk`, `sed`, `cut`, and `jq`.

In Nushell, commands communicate using **structured data types**:
- **Table**: A list of records (like an SQL table or spreadsheet).
- **Record**: Key-value dictionary (`{ key: "value", num: 42 }`).
- **List**: An ordered array (`[ "a", "b", "c" ]`).
- **Primitive**: String, integer, float, filesize (`10mb`), duration (`5sec`, `2day`), date.

When you run an external binary (e.g., `git`, `aws`, `kubectl`), it outputs text. You convert it into structured data using `from json`, `from yaml`, or `lines`, and from that point forward you have the full power of Nushell's typed data engine!

---

## 2. Variables & Quoting

### Environment Variables
```nu
# Read variable
$env.USER
$env.PATH

# Set variable (in current scope)
$env.MY_VAR = "hello"

# Set variable across callers (inside custom commands)
def --env set_token [val: string] {
    $env.API_TOKEN = $val
}

# Unset variable
hide-env -i MY_VAR

# Bulk load record into environment
load-env { FOO: "bar", BAZ: "qux" }
```

### Local Variables
```nu
let immutable_val = "cannot change"
mut mutable_val = 1
$mutable_val = $mutable_val + 1
```

### Quoting Rules (CRITICAL!)
| Syntax | Meaning | Example | Result |
| :--- | :--- | :--- | :--- |
| `"..."` | **Literal string** (no `$var` expansion!) | `"Hello $env.USER"` | `Hello $env.USER` |
| `'...'` | **Raw string** | `'Single quotes'` | `Single quotes` |
| `$"..."` | **Interpolated string** (use `($expr)`) | `$"Hello ($env.USER)!"` | `Hello robert.wallace!` |

```nu
# Wrong:
ssh -i "$env.KEY" "$env.USER"@10.0.0.1      # Passes literal "$env.KEY"

# Correct:
ssh -i $env.KEY $"($env.USER)@10.0.0.1"   # Interpolates cleanly
# Or pass as separate argument:
ssh -i $env.KEY -l $env.USER 10.0.0.1
```

---

## 3. Subexpressions & Command Substitution

In Zsh: `result=$(command arg)`  
In Nushell: `let result = (command arg)` *(just wrap in parentheses)*

```nu
# Capture command output
let git_root = (git rev-parse --show-toplevel | str trim)

# Use directly inside another command
cd (git rev-parse --show-toplevel | str trim)

# Math inside expressions
let doubled = (20 * 2)
```

---

## 4. Piping & Redirection

| Operation | Zsh / Bash | Nushell |
| :--- | :--- | :--- |
| **Pipe data** | `cmd1 \| cmd2` | `cmd1 \| cmd2` |
| **Discard stdout** | `cmd > /dev/null` | `cmd out> /dev/null` or `cmd \| ignore` |
| **Discard stderr** | `cmd 2> /dev/null` | `cmd err> /dev/null` |
| **Discard all** | `cmd &> /dev/null` | `cmd out+err> /dev/null` |
| **Save to file** | `cmd > file.txt` | `cmd \| save -f file.txt` |
| **Append to file** | `cmd >> file.txt` | `cmd \| save --append file.txt` |

---

## 5. Zsh vs. Nushell "Rosetta Stone"

| Common Task | Zsh / Bash | Nushell Equivalent |
| :--- | :--- | :--- |
| **Filter rows** | `grep "prod"` | `find "prod"` or `where col == "prod"` |
| **Select columns** | `awk '{print $1, $3}'` | `select col1 col3` |
| **Drop column** | `cut -d' ' -f2 --complement` | `reject col2` |
| **Get single column** | `awk '{print $2}'` | `get col_name` |
| **Count lines/items**| `wc -l` | `length` (or `lines \| length`) |
| **First N items** | `head -n 5` | `first 5` |
| **Last N items** | `tail -n 5` | `last 5` |
| **Sort** | `sort -k2 -nr` | `sort-by size --reverse` |
| **Unique rows** | `sort -u` | `uniq` |
| **Interactive TUI** | `less` / `fzf` | `explore` *(Nushell's built-in table pager!)* |
| **JSON parsing** | `jq '.items[].name'` | `from json \| get items.name` |
| **YAML parsing** | `yq '.metadata.name'` | `from yaml \| get metadata.name` |
| **CSV parsing** | `mlr --csv ...` | `from csv` |
| **Split text** | `tr ':' '\n'` | `split row ":"` |
| **Trim whitespace** | `xargs` / `sed` | `str trim` |
| **Replace text** | `sed 's/foo/bar/g'` | `str replace --all 'foo' 'bar'` |
| **Join list** | `paste -sd,` | `str join ", "` |
| **HTTP API request**| `curl -s https://api... \| jq` | `http get https://api...` *(parsed automatically!)* |
| **Check which binary**| `which kubectl` | `which kubectl` |
