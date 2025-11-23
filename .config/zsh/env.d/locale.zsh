export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US:en

# Enable true color support for terminal
export COLORTERM=truecolor

# Ensure proper terminal type for color support
if [[ -z "$TERM" ]] || [[ "$TERM" == "dumb" ]]; then
    export TERM=xterm-256color
fi
