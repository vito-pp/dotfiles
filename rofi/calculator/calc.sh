#!/usr/bin/env bash
# rofi-calc: qalc + rofi script modi
# Result shown as first list entry, history below

HISTORY="${XDG_DATA_HOME:-$HOME/.local/share}/rofi/rofi_calc_history"
mkdir -p "$(dirname "$HISTORY")"
touch "$HISTORY"

INPUT="$1"
RETV="${ROFI_RETV:-0}"
INFO="${ROFI_INFO:-}"

# entry selected
if [[ "$RETV" == "1" ]]; then
    if [[ "$INFO" == "result" ]]; then
        result=$(qalc -t "$INPUT" 2>/dev/null | tail -1 | xargs)
        if [[ -n "$result" && "$result" != "$INPUT" ]]; then
            echo "$INPUT = $result" >> "$HISTORY"
            echo -n "$result" | wl-copy
        fi
        exit 0
    else
        echo -n "$INFO" | wl-copy
        exit 0
    fi
fi

# evaluate live
result=""
if [[ -n "$INPUT" ]]; then
    result=$(qalc -t "$INPUT" 2>/dev/null | tail -1 | xargs)
    [[ "$result" == "$INPUT" ]] && result=""
fi

# rofi output
printf '\0markup-rows\x1ffalse\n'
printf '\0prompt\x1f󰃬\n'

if [[ -n "$result" ]]; then
    printf '%s = %s\0info\x1fresult\n' "$INPUT" "$result"
fi

while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    raw_result="${line##* = }"
    printf '%s\0info\x1f%s\n' "$line" "$raw_result"
done < <(tac "$HISTORY")
