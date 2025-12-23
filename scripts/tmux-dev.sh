#!/bin/bash

# Use current directory name as session name
SESSION_NAME=$(basename "$PWD")

# Check if session already exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

if [ $? != 0 ]; then
  # Create new session with first window
  tmux new-session -d -s "$SESSION_NAME" -n code

  tmux select-pane -T "Code"
  tmux send-keys -t "$SESSION_NAME":1 'nvim .' C-m

  tmux new-window -t "$SESSION_NAME" -n claude
  tmux select-pane -T "Claude"
  tmux send-keys -t "$SESSION_NAME":2 'claude' C-m

  tmux new-window -t "$SESSION_NAME" -n test
  tmux select-pane -T "Test"
  tmux send-keys -t "$SESSION_NAME":3 'clear' C-m

  tmux select-window -t "$SESSION_NAME":code
fi

# Attach to the session
tmux attach-session -t "$SESSION_NAME"
