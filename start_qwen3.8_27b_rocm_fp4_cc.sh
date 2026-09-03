#!/usr/bin/env bash
# Claude Code: ~/.claude/settings.json
# Confirm on startup: "chat template, thinking = 0" and "n_slots = 1"
#
# MUST use --parallel 1: with parallel 2, Claude Code's title-gen request
# races the main agent on a second slot and you only get a title, no tool calls.
# Also halves per-slot context (131072 -> 65536).

../llama-server \
  -m ~/models/gguf/qwen3.8/Qwen3.8-27B-ROCmFP4-FAST.gguf \
  -a qwen3.8-27b \
  --spec-type draft-mtp \
  --model-draft ~/models/gguf/qwen3.8/mtp-Qwen3.8-27B-Q4_0.gguf \
  --spec-draft-ngl 99 --spec-draft-device ROCm0 \
  --spec-draft-n-max 4 --spec-draft-n-min 0 --spec-draft-p-min 0.0 \
  -ngl 999 -fa on --load-mode dio --jinja -fit off --parallel 1 -dev ROCm0 \
  -c 131072 --host 127.0.0.1 --port 8800 \
  --reasoning off \
  --reasoning-format none \
  --chat-template-file ./qwen3.8-claude.jinja
