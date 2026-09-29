#!/usr/bin/env python3
"""
Import Zsh extended history into Nushell SQLite history database.
Preserves timestamps, multiline commands, hostnames, and existing Nu history.
"""

import os
import re
import shutil
import socket
import sqlite3
import sys
from datetime import datetime

def main():
    home = os.path.expanduser("~")
    zsh_history_path = os.path.join(home, ".zsh_history")
    xdg_config_home = os.environ.get("XDG_CONFIG_HOME", os.path.join(home, ".config"))
    nu_db_path = os.path.join(xdg_config_home, "nushell", "history.sqlite3")

    if not os.path.exists(zsh_history_path):
        print(f"Error: Zsh history not found at {zsh_history_path}", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(nu_db_path):
        print(f"Error: Nushell SQLite history not found at {nu_db_path}", file=sys.stderr)
        sys.exit(1)

    # 1. Backup existing Nushell history
    timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{nu_db_path}.bak_{timestamp_str}"
    shutil.copy2(nu_db_path, backup_path)
    print(f"✔ Backed up existing Nushell history to:\n  {backup_path}")

    # 2. Checkpoint SQLite WAL mode
    conn = sqlite3.connect(nu_db_path)
    cur = conn.cursor()
    cur.execute("PRAGMA wal_checkpoint(TRUNCATE);")

    # 3. Read existing Nushell records
    cur.execute(
        "SELECT command_line, start_timestamp, hostname, cwd, duration_ms, exit_status, more_info FROM history ORDER BY id ASC"
    )
    existing_nu_rows = cur.fetchall()
    print(f"✔ Read {len(existing_nu_rows)} existing Nushell history entries")

    # 4. Parse Zsh history
    hostname = socket.gethostname().split(".")[0]
    pattern = re.compile(r"^: (\d+):(\d+);(.*)$", re.DOTALL)
    zsh_entries = []
    current_entry = None

    with open(zsh_history_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            m = pattern.match(line)
            if m:
                if current_entry:
                    zsh_entries.append(current_entry)
                ts, dur, cmd = m.groups()
                current_entry = (
                    cmd.rstrip("\n"),
                    int(ts) * 1000,
                    hostname,
                    home,
                    int(dur) * 1000,
                    0,
                    None,
                )
            else:
                if current_entry:
                    # Multiline command continuation
                    cmd_line = current_entry[0] + "\n" + line.rstrip("\n")
                    current_entry = (
                        cmd_line,
                        current_entry[1],
                        current_entry[2],
                        current_entry[3],
                        current_entry[4],
                        current_entry[5],
                        None,
                    )
                else:
                    current_entry = (
                        line.rstrip("\n"),
                        0,
                        hostname,
                        home,
                        0,
                        0,
                        None,
                    )

    if current_entry:
        zsh_entries.append(current_entry)

    print(f"✔ Parsed {len(zsh_entries)} Zsh history entries")

    # 5. Merge and sort chronologically
    # Filter out any exact duplicate commands from today that are in both
    existing_cmds = set(r[0] for r in existing_nu_rows)
    filtered_zsh = [e for e in zsh_entries if e[0] not in existing_cmds or e[1] < (existing_nu_rows[0][1] if existing_nu_rows and existing_nu_rows[0][1] else 0)]

    all_entries = filtered_zsh + list(existing_nu_rows)
    all_entries.sort(key=lambda x: x[1] if x[1] else 0)

    # 6. Rebuild history table in exact chronological order
    cur.execute("DELETE FROM history;")
    cur.execute("DELETE FROM sqlite_sequence WHERE name='history';")

    insert_sql = """
        INSERT INTO history (command_line, start_timestamp, hostname, cwd, duration_ms, exit_status, more_info)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """
    cur.executemany(insert_sql, all_entries)
    conn.commit()

    # 7. Checkpoint WAL and verify
    cur.execute("PRAGMA wal_checkpoint(TRUNCATE);")
    cur.execute("SELECT count(*) FROM history;")
    total_count = cur.fetchone()[0]
    conn.close()

    print(f"✔ Successfully imported! Total commands now in Nushell history: {total_count}")

if __name__ == "__main__":
    main()
