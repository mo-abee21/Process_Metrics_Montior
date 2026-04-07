# 🔍 procinfo — Live Process Monitor via `/proc`

A Bash script that queries the Linux `/proc` filesystem to display real-time per-process stats — PID, command name, user, memory usage, CPU time, and thread count — for any running process matching a given pattern. Supports a continuous live-refresh mode for ongoing monitoring.

---

## 📋 Table of Contents

- [Features](#features)
- [Usage](#usage)
- [Output Format](#output-format)
- [How It Works](#how-it-works)
- [The `/proc` Filesystem](#the-proc-filesystem)
- [Error Handling](#error-handling)
- [Examples](#examples)
- [Notes](#notes)

---

## ✨ Features

- **Pattern-based process filtering** — matches any running process whose command name contains the given pattern
- **False-positive filtering** — cross-checks `ps` results against `/proc/<pid>/comm` to exclude processes that merely have the pattern in their arguments (e.g., `vim file.java` won't show up when searching for `java`)
- **Live refresh mode** — with `-t <secs>`, continuously reprints the process table every N seconds for real-time monitoring
- **Direct `/proc` reads** — pulls memory, CPU, and thread data straight from the kernel's virtual filesystem for accuracy
- **Formatted columnar output** — clean, aligned table with consistent column widths

---

## 🚀 Usage

```bash
./procinfo.sh [-t secs] <pattern>
```

| Argument | Description |
|---|---|
| `<pattern>` | Process command name to search for (e.g., `vim`, `java`, `python`) |
| `-t <secs>` | *(Optional)* Refresh interval in seconds for continuous monitoring |

**Single snapshot:**
```bash
./procinfo.sh vim
```

**Live refresh every 5 seconds:**
```bash
./procinfo.sh -t 5 java
```

---

## 📊 Output Format

```
                 PID                  CMD                 USER                  MEM                  CPU              THREADS
               13281               (vim)               alice               61 Mb             92 secs                1 Thr
               15379               (vim)                 bob               61 Mb              4 secs                1 Thr
```

| Column | Source | Description |
|---|---|---|
| `PID` | `ps -e -f` | Process ID |
| `CMD` | `/proc/<pid>/comm` | Executable name (not the full command line) |
| `USER` | `ps -e -f` | Username of the process owner |
| `MEM` | `/proc/<pid>/status` → `VmRSS` | Resident Set Size in MB (actual RAM in use) |
| `CPU` | `/proc/<pid>/stat` fields 14+15 | Total CPU time (user + kernel) in seconds |
| `THREADS` | `/proc/<pid>/status` → `Threads` | Number of active threads |

---

## ⚙️ How It Works

1. **Argument parsing** — accepts either 1 argument (`pattern`) or 3 arguments (`-t secs pattern`); prints usage and exits on anything else
2. **Process discovery** — runs `ps -e -f | grep <pattern>` to find candidate PIDs and usernames
3. **False-positive filtering** — reads `/proc/<pid>/comm` (the actual executable name, no arguments) and skips any process where `comm` doesn't match the pattern. This prevents `vim file.java` from appearing in a search for `java`
4. **Stat collection** — reads three files per process:
   - `/proc/<pid>/stat` — fields 14 and 15 (utime + stime) summed and divided by clock ticks for CPU seconds
   - `/proc/<pid>/status` — `VmRSS` line for resident memory in MB
   - `/proc/<pid>/status` — `Threads` line for thread count
5. **Output** — prints a formatted row per matching process
6. **Loop mode** — if `-t` is passed, wraps the above in an infinite `while true` loop with `sleep <secs>` between iterations, reprinting the header each cycle

---

## 🗂️ The `/proc` Filesystem

This script reads directly from `/proc`, Linux's virtual filesystem that exposes live kernel data as readable files. No external monitoring tools or elevated permissions are needed.

| File | What it contains |
|---|---|
| `/proc/<pid>/comm` | The bare executable name (no path, no arguments) |
| `/proc/<pid>/stat` | Space-separated process stats; fields 14 & 15 are user and kernel CPU ticks |
| `/proc/<pid>/status` | Human-readable key-value pairs including `VmRSS` (memory) and `Threads` |

CPU time is computed as:
```
CPU seconds = (utime + stime) / clock_ticks_per_second
```
where clock ticks are typically 100 Hz, so fields 14+15 are divided by 100.

Memory (`VmRSS`) is reported in kB by the kernel and converted to MB by dividing by 1024.

---

## 🛡️ Error Handling

| Condition | Behavior |
|---|---|
| No arguments provided | Prints usage: `procinfo.sh [-t secs] pattern` and exits |
| Wrong number of arguments | Prints usage and exits |
| `-t` flag without `secs` and `pattern` | Prints usage and exits |
| `/proc/<pid>` files unreadable (process exited mid-run) | `2>/dev/null` suppresses errors; process is silently skipped |
| Process in `ps` results but not matching `comm` | Filtered out to prevent false positives from argument matching |

---

## 📟 Examples

**Find all `vim` processes:**
```bash
./procinfo.sh vim
```
```
                 PID                  CMD                 USER                  MEM                  CPU              THREADS
               13281               (vim)               alice               61 Mb             92 secs                1 Thr
               15379               (vim)                 bob               61 Mb              4 secs                1 Thr
```

**Monitor Java processes, refreshing every 10 seconds:**
```bash
./procinfo.sh -t 10 java
```
```
                 PID                  CMD                 USER                  MEM                  CPU              THREADS
               60842              (java)                root                0 Mb           1726 secs                1 Thr
              357137              (java)               alice            11849 Mb          87230 secs               26 Thr
              429088              (java)                 bob            16267 Mb          89016 secs               28 Thr


                 PID                  CMD                 USER                  MEM                  CPU              THREADS
               ...
```

**No pattern provided:**
```bash
./procinfo.sh
```
```
procinfo.sh [-t secs] pattern
```

---

## 📝 Notes

- `/proc/<pid>/comm` is used deliberately over the full command line from `ps` to avoid matching on file arguments — this is the key distinction that makes pattern filtering accurate
- The script uses `2>/dev/null` throughout `/proc` reads to gracefully handle short-lived processes that may exit between discovery and stat collection
- Memory is `VmRSS` (Resident Set Size) — actual physical RAM the process is using, not virtual memory
- CPU time reflects the **total accumulated time** since the process started, not a real-time usage percentage
