#!/usr/bin/env bash

# rofi + qalc calculator
#
# Enter        -> copy result, keep calculator open
# Ctrl+Enter   -> copy result, close calculator
# Shift+Delete -> delete selected history entry
# Alt+Enter    -> reuse selected expression
# Ctrl+L       -> clear calculator history
# F1           -> show quick Qalculate help

HISTORY="${XDG_DATA_HOME:-$HOME/.local/share}/rofi/rofi_calc_history"
MAX_HISTORY=100

mkdir -p "$(dirname "$HISTORY")"
touch "$HISTORY"

RETV="${ROFI_RETV:-0}"
INFO="${ROFI_INFO:-}"
ROFI_TEXT="${ROFI_INPUT:-}"
SELECTED="${1:-}"

# Separator used internally inside ROFI_INFO.
SEP=$'\x1e'

# calculate() stores its output here.
CALC_RESULT=""
CALC_ERROR=""


# ------------------------------------------------------------
# Parse selected row info
# ------------------------------------------------------------

KIND=""
SELECTED_RESULT=""

if [[ -n "$INFO" ]]; then
    KIND="${INFO%%"$SEP"*}"

    if [[ "$INFO" == *"$SEP"* ]]; then
        SELECTED_RESULT="${INFO#*"$SEP"}"
    fi
fi


# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

trim() {
    sed \
        -e 's/^[[:space:]]*//' \
        -e 's/[[:space:]]*$//'
}


one_line() {
    tr '\n\t' '  ' |
        sed \
            -e 's/[[:space:]][[:space:]]*/ /g' \
            -e 's/^[[:space:]]*//' \
            -e 's/[[:space:]]*$//'
}


calculate() {
    local expr="$1"
    local stdout
    local stderr
    local status
    local errfile
    local detected_error

    CALC_RESULT=""
    CALC_ERROR=""

    [[ -z "$expr" ]] && return 0

    errfile=$(mktemp)

    stdout=$(qalc -t "$expr" 2>"$errfile")
    status=$?

    stderr=$(cat "$errfile")
    rm -f "$errfile"

    # qalc -t leaves the actual result on stdout.
    CALC_RESULT=$(
        printf '%s\n' "$stdout" |
            sed '/^[[:space:]]*$/d' |
            tail -n 1 |
            trim
    )

    # Look specifically for Qalculate error messages.
    detected_error=$(
        printf '%s\n' "$stderr" |
            grep -Ei '(^|[[:space:]])(error|fatal):' |
            tail -n 1 |
            one_line
    )

    if [[ -n "$detected_error" ]]; then
        CALC_ERROR="$detected_error"
        CALC_RESULT=""
        return 1
    fi

    # If qalc itself failed, show whatever useful stderr it gave us.
    if (( status != 0 )); then
        CALC_ERROR=$(
            printf '%s\n' "$stderr" |
                tail -n 1 |
                one_line
        )

        [[ -z "$CALC_ERROR" ]] &&
            CALC_ERROR="Qalculate could not evaluate the expression."

        CALC_RESULT=""
        return 1
    fi

    # If an expression just evaluates to itself, don't show a useless row.
    if [[ "$CALC_RESULT" == "$expr" ]]; then
        CALC_RESULT=""
    fi

    return 0
}


copy_result() {
    local value="$1"

    [[ -n "$value" ]] &&
        printf '%s' "$value" | wl-copy
}


add_history() {
    local expr="$1"
    local result="$2"
    local line
    local tmp

    [[ -z "$expr" || -z "$result" ]] && return 0

    line="$expr = $result"
    tmp=$(mktemp)

    # Remove an identical old entry.
    grep -Fvx -- "$line" "$HISTORY" > "$tmp" || true

    # Put newest calculation at the end.
    printf '%s\n' "$line" >> "$tmp"

    # Keep history bounded.
    tail -n "$MAX_HISTORY" "$tmp" > "$HISTORY"

    rm -f "$tmp"
}


delete_history() {
    local expr="$1"
    local result="$2"
    local line
    local tmp

    [[ -z "$expr" || -z "$result" ]] && return 0

    line="$expr = $result"
    tmp=$(mktemp)

    grep -Fvx -- "$line" "$HISTORY" > "$tmp" || true

    mv "$tmp" "$HISTORY"
}


# ------------------------------------------------------------
# Render Rofi
# ------------------------------------------------------------

render() {
    local input="$1"
    local keep_filter="${2:-0}"
    local keep_selection="${3:-0}"
    local message="${4:-}"

    local line
    local expr
    local hist_result

    # Calculate first so we know whether there is an error.
    calculate "$input" || true

    # Rofi script-mode options.
    printf '\0markup-rows\x1ffalse\n'
    printf '\0prompt\x1f󰃬\n'
    printf '\0use-hot-keys\x1ftrue\n'

    if [[ "$keep_filter" == "1" ]]; then
        printf '\0keep-filter\x1ftrue\n'
    fi

    if [[ "$keep_selection" == "1" ]]; then
        printf '\0keep-selection\x1ftrue\n'
    fi

    # F1 help takes priority over an error for this refresh.
    if [[ -n "$message" ]]; then
        printf '\0message\x1f%s\n' "$message"

    elif [[ -n "$CALC_ERROR" ]]; then
        printf '\0message\x1f%s\n' "$CALC_ERROR"
    fi


    # --------------------------------------------------------
    # Current calculation
    # --------------------------------------------------------

    if [[ -n "$CALC_RESULT" ]]; then

        # Real row value:
        #
        #   13 * 12
        #
        # Displayed value:
        #
        #   13 * 12 = 156
        #
        # This allows Alt+Enter to put only the expression
        # back into the input field.

        printf \
            '%s\0display\x1f%s = %s\x1finfo\x1fcurrent%s%s\x1fmeta\x1f%s\n' \
            "$input" \
            "$input" \
            "$CALC_RESULT" \
            "$SEP" \
            "$CALC_RESULT" \
            "$CALC_RESULT"
    fi


    # --------------------------------------------------------
    # History
    # --------------------------------------------------------

    while IFS= read -r line; do

        [[ -z "$line" ]] && continue

        expr="${line% = *}"
        hist_result="${line##* = }"

        printf \
            '%s\0display\x1f%s\x1finfo\x1fhistory%s%s\x1fmeta\x1f%s\n' \
            "$expr" \
            "$line" \
            "$SEP" \
            "$hist_result" \
            "$hist_result"

    done < <(tac "$HISTORY")
}


# ------------------------------------------------------------
# Rofi actions
# ------------------------------------------------------------

case "$RETV" in

    0)
        # Initial opening.
        render "$ROFI_TEXT"
        ;;


    1)
        # ----------------------------------------------------
        # ENTER
        #
        # Copy result and stay open.
        # ----------------------------------------------------

        if [[ "$KIND" == "current" ]]; then

            add_history \
                "$SELECTED" \
                "$SELECTED_RESULT"

            copy_result "$SELECTED_RESULT"

        elif [[ "$KIND" == "history" ]]; then

            copy_result "$SELECTED_RESULT"

        fi

        render "" 0 1
        ;;


    2)
        # ----------------------------------------------------
        # ENTER on custom input
        # ----------------------------------------------------

        calculate "$ROFI_TEXT" || true

        if [[ -n "$CALC_RESULT" ]]; then

            add_history \
                "$ROFI_TEXT" \
                "$CALC_RESULT"

            copy_result "$CALC_RESULT"

            render "" 0 1

        else
            # Invalid expression: keep it there and show error.
            render "$ROFI_TEXT" 1 0
        fi
        ;;


    3)
        # ----------------------------------------------------
        # SHIFT + DELETE
        #
        # Delete selected history entry.
        # ----------------------------------------------------

        if [[ "$KIND" == "history" ]]; then

            delete_history \
                "$SELECTED" \
                "$SELECTED_RESULT"

        fi

        render "$ROFI_TEXT" 1 1
        ;;


    10)
        # ----------------------------------------------------
        # CTRL + ENTER
        #
        # Copy result and close.
        # ----------------------------------------------------

        if [[ "$KIND" == "current" ]]; then

            add_history \
                "$SELECTED" \
                "$SELECTED_RESULT"

            copy_result "$SELECTED_RESULT"

        elif [[ "$KIND" == "history" ]]; then

            copy_result "$SELECTED_RESULT"

        else

            calculate "$ROFI_TEXT" || true

            if [[ -n "$CALC_RESULT" ]]; then

                add_history \
                    "$ROFI_TEXT" \
                    "$CALC_RESULT"

                copy_result "$CALC_RESULT"

            else
                # Don't close if the expression is invalid.
                render "$ROFI_TEXT" 1 0
                exit 0
            fi
        fi

        # No output -> Rofi closes.
        exit 0
        ;;


    11)
        # ----------------------------------------------------
        # CTRL + L
        #
        # Clear history.
        # ----------------------------------------------------

        : > "$HISTORY"

        render "$ROFI_TEXT" 1 0
        ;;


    12)
        # ----------------------------------------------------
        # F1
        #
        # Tiny Qalculate cheat sheet.
        # ----------------------------------------------------

        HELP='Qalculate examples: 20 miles / 2h to km/h  •  sin(90 deg)  •  solve(x^2 - 5x + 6 = 0)  •  52 to hex  •  today + 30 days   |   Enter copy  •  Ctrl+Enter copy+close  •  Alt+Enter reuse  •  Shift+Delete remove history  •  Ctrl+L clear history'

        render "$ROFI_TEXT" 1 0 "$HELP"
        ;;


    28)
        # ----------------------------------------------------
        # LIVE INPUT REFRESH
        #
        # calc.rasi maps every input change to custom action 19.
        # ----------------------------------------------------

        render "$ROFI_TEXT" 1 0
        ;;


    *)
        render "$ROFI_TEXT" 1 0
        ;;

esac
