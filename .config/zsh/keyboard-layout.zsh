_keyboard_layout_hypr_keyboards() {
  hyprctl devices | awk '
    /^Keyboards:/ { in_keyboards=1; next }
    /^Tablets:/ { in_keyboards=0 }
    in_keyboards && /^\t\t[[:graph:]].*$/ && $0 !~ /rules:|active layout index:|active keymap:|capsLock:|numLock:|main:/ {
      current=$0
      sub(/^[[:space:]]+/, "", current)
    }
    in_keyboards && /^[[:space:]]+main:/ {
      main=$0
      sub(/^[[:space:]]*main:[[:space:]]*/, "", main)
      print current "|" main
    }
  '
}

_keyboard_layout_laptop_name() {
  awk '
    BEGIN { RS=""; FS="\n" }
    {
      name=""; sysfs=""; handlers=""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^N: Name=/) {
          name=$i
          sub(/^N: Name="/, "", name)
          sub(/"$/, "", name)
        } else if ($i ~ /^S: Sysfs=/) {
          sysfs=$i
          sub(/^S: Sysfs=/, "", sysfs)
        } else if ($i ~ /^H: Handlers=/) {
          handlers=$i
          sub(/^H: Handlers=/, "", handlers)
        }
      }

      if (handlers ~ /(^| )kbd( |$)/ && sysfs ~ /(platform\/i8042|serio|isa0060)/) {
        print name
        exit
      }
    }
  ' /proc/bus/input/devices | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

_keyboard_layout_external_name() {
  local external

  external="$(_keyboard_layout_hypr_keyboards | awk -F'|' '$2 == "yes" { print $1; exit }')"
  if [[ -n "$external" ]]; then
    printf '%s\n' "$external"
    return
  fi

  _keyboard_layout_hypr_keyboards | awk -F'|' '
    $1 !~ /(consumer-control|system-control|power-button|video-bus)/ {
      print $1
      exit
    }
  '
}

_keyboard_layout_targets() {
  local laptop external
  laptop="$(_keyboard_layout_laptop_name)"
  external="$(_keyboard_layout_external_name)"

  if [[ -n "$laptop" ]]; then
    printf 'laptop|%s\n' "$laptop"
  fi

  if [[ -n "$external" && "$external" != "$laptop" ]]; then
    printf 'external|%s\n' "$external"
  fi
}

keyboard_layout() {
  local target="$1"
  local device_target="${2:-all}"
  local layout_id=""
  local targets
  local switched=()

  case "$target" in
    pt-br|pt_br|br)
      layout_id="0"
      ;;
    en|en-us|en_us|us)
      layout_id="1"
      ;;
    status)
      _keyboard_layout_targets | awk -F'|' '{ print $1 ": " $2 }'
      return
      ;;
    -h|--help|"")
      cat <<'EOF'
usage: keyboard_layout <pt-br|en|status> [laptop|external|all]

  pt-br   switch to layout index 0: Brazilian ABNT2
  en      switch to layout index 1: US International
  status  list the laptop and external keyboard targets

Targets:
  laptop    only the built-in keyboard
  external  only the active external keyboard
  all       both built-in and external keyboards
EOF
      return
      ;;
    *)
      printf 'unknown layout: %s\n' "$target" >&2
      printf 'usage: keyboard_layout <pt-br|en|status> [laptop|external|all]\n' >&2
      return 1
      ;;
  esac

  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    printf 'HYPRLAND_INSTANCE_SIGNATURE is not set. Run this inside your Hyprland session.\n' >&2
    return 1
  fi

  targets=("${(@f)$(_keyboard_layout_targets)}")

  if (( ${#targets[@]} == 0 )); then
    printf 'No keyboard targets found.\n' >&2
    return 1
  fi

  local entry label kb
  for entry in "${targets[@]}"; do
    label="${entry%%|*}"
    kb="${entry#*|}"

    case "$device_target" in
      laptop|external)
        [[ "$label" == "$device_target" ]] || continue
        ;;
      all)
        ;;
      *)
        printf 'unknown device target: %s\n' "$device_target" >&2
        printf 'usage: keyboard_layout <pt-br|en|status> [laptop|external|all]\n' >&2
        return 1
        ;;
    esac

    hyprctl switchxkblayout "$kb" "$layout_id" || return 1
    switched+=("$label|$kb")
  done

  if (( ${#switched[@]} == 0 )); then
    printf 'No keyboards matched target: %s\n' "$device_target" >&2
    return 1
  fi

  for entry in "${switched[@]}"; do
    label="${entry%%|*}"
    kb="${entry#*|}"
    printf '%s keyboard %s switched to %s\n' "$label" "$kb" "$target"
  done
}
