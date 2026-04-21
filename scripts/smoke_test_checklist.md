# Briluxforge — Release Smoke Test Checklist

Run this on a **clean machine** (no dev environment, no prior install) before shipping.

## Install
- [ ] App launches without errors
- [ ] Window title shows "Briluxforge"
- [ ] Window minimum size 900×600 enforced
- [ ] Dark mode active by default

## Auth & Onboarding
- [ ] Sign up with new email/password
- [ ] Onboarding flow plays: Welcome → Use-Case → API Guide → Add Key → Done
- [ ] Use-case selection sets correct default model (e.g. Coding → DeepSeek)
- [ ] Onboarding skips on second launch

## API Keys
- [ ] Add a DeepSeek API key — green checkmark on verify
- [ ] Add an invalid key — actionable error message shown, no crash
- [ ] Keys survive app restart (stored in secure storage)

## Delegation Engine
- [ ] Coding prompt routes to DeepSeek — delegation badge visible
- [ ] Long-context prompt (>30k tokens estimated) routes to Gemini Flash
- [ ] Low-confidence prompt shows Delegation Failure Dialog
- [ ] "Use Default" picks correctly; "Let AI Decide" fires meta-prompt
- [ ] DefaultModelReconciler: no crash if model_profiles.json is swapped

## Chat
- [ ] Send a message — streaming response renders token by token
- [ ] Assistant response renders as rich Markdown (bold, code, lists)
- [ ] Code block has syntax highlighting and copy button
- [ ] Conversation persists after restart (Drift/SQLite)
- [ ] New chat (Ctrl+N) creates fresh conversation
- [ ] Conversation list in sidebar updates

## Skills
- [ ] Skills screen lists all 5 built-in skills
- [ ] Toggle a skill on — "X skills active" indicator appears in chat input
- [ ] Send a prompt — system prompt includes injected skill text
- [ ] Create a custom skill — appears in list, can be toggled
- [ ] Delete custom skill works; built-in skill delete is blocked

## Savings Tracker
- [ ] Sidebar shows "You've saved $X.XX" after first API call
- [ ] Value animates upward after each subsequent call
- [ ] Tap opens breakdown modal with per-model token counts
- [ ] Math correct: DeepSeek 5k in / 2k out ≈ $0.074 savings vs Opus benchmark

## Settings
- [ ] Default model selector works and persists
- [ ] Theme toggle (dark ↔ light) works
- [ ] License status section visible; "Enter License Key" button opens screen
- [ ] Logout works; redirects to login screen

## Keyboard Shortcuts
- [ ] Ctrl+N → new chat
- [ ] Ctrl+Enter → send message
- [ ] Ctrl+, → settings
- [ ] Ctrl+K → model selector

## Offline / Edge Cases
- [ ] App launches with no network — chat history and keys accessible
- [ ] API call with no network — clear error message, no crash
- [ ] License re-validation offline — trusts cached status (up to 7 days)
