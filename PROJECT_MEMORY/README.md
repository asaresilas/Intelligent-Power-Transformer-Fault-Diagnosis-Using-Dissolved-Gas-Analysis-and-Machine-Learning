# PROJECT_MEMORY

This folder carries the memory of all work done with Claude, so it moves with the project to any SSD or computer.

| Item | What it is |
|---|---|
| `SESSION_SUMMARY.md` | Readable summary of the whole chat: decisions, files produced, datasets, verification results, next steps |
| `claude_memory_notes/` | Copies of Claude's memory notes for this project (index: `MEMORY.md`) |
| `chat_transcript/chat_session_2026-09-30_to_2026-10-08.zip` | Full export of the original chat session (12 MB) |

## Using it on the new SSD
1. Copy the whole project folder, including this folder, to the new SSD.
2. Open the project folder in Claude Code. The file `CLAUDE.md` in the project root tells Claude to read this folder first, so earlier context is restored even though the drive letter or path has changed.
3. Optionally, to restore Claude's own memory: copy the files in `claude_memory_notes/` into
   `C:\Users\<you>\.claude\projects\<project-path-with-dashes>\memory\` on the new machine. The project-path folder is created the first time you open the project in Claude Code.
4. Update `SESSION_SUMMARY.md` (or ask Claude to) whenever a phase is completed.
