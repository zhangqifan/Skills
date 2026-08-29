#!/bin/zsh

set -u

minutes=10
include_identifiers=0

while (( $# > 0 )); do
  case "$1" in
    --minutes)
      if (( $# < 2 )) || [[ "$2" != <-> ]]; then
        print -u2 "Usage: $0 [--minutes N] [--include-identifiers]"
        exit 64
      fi
      minutes="$2"
      shift 2
      ;;
    --include-identifiers)
      include_identifiers=1
      shift
      ;;
    *)
      print -u2 "Usage: $0 [--minutes N] [--include-identifiers]"
      exit 64
      ;;
  esac
done

if (( minutes < 1 || minutes > 120 )); then
  print -u2 "--minutes must be between 1 and 120"
  exit 64
fi

section() {
  print
  print "## $1"
}

redact_stream() {
  if (( include_identifiers )); then
    /bin/cat
  else
    /usr/bin/sed -E \
      -e 's/[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}/[device-id]/g' \
      -e 's/[[:xdigit:]]{8}-[[:xdigit:]]{8}/[connection-id]/g' \
      -e 's/[[:xdigit:]]{16,}/[identifier]/g' \
      -e 's/([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}/[mac-address]/g' \
      -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[ipv4-address]/g' \
      -e 's/(SFDevice ID|IDS|Nm|Md|AltDSID|CNID|MRI|MRtI|rapportID) [^, ]+/\1 [redacted]/g' \
      -e "s/(AID|ADSID|AltDSID) '[^']*'/\1 '[redacted]'/g" \
      -e 's/mailto:[^", )]+/mailto:[redacted]/g' \
      -e 's/tel:\+?[0-9][0-9() .-]{5,}/tel:[redacted]/g' \
      -e 's/[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/[email]/g' \
      -e 's/\+[0-9][0-9() .-]{6,}/[phone]/g' \
      -e 's/[[:alnum:]_.-]+\.local/[hostname]/g' \
      -e 's|/Users/[^/ ]+|/Users/[redacted]|g'
  fi
}

section "macOS"
/usr/bin/sw_vers
/usr/bin/uname -m

section "Handoff preferences"
for preference_key in ActivityAdvertisingAllowed ActivityReceivingAllowed; do
  preference_value=$(/usr/bin/defaults -currentHost read com.apple.coreservices.useractivityd "$preference_key" 2>&1)
  print "$preference_key: $preference_value"
done

section "Wi-Fi and AWDL"
wifi_device=$(/usr/sbin/networksetup -listallhardwareports 2>/dev/null | /usr/bin/awk '/Hardware Port: (Wi-Fi|AirPort)/ { getline; print $2; exit }')
if [[ -n "$wifi_device" ]]; then
  /usr/sbin/networksetup -getairportpower "$wifi_device" 2>&1
else
  print "Wi-Fi interface not found"
fi
/sbin/ifconfig awdl0 2>&1 | /usr/bin/awk 'NR == 1 || /status:/'

section "Bluetooth"
/usr/sbin/system_profiler SPBluetoothDataType -detailLevel mini 2>/dev/null | /usr/bin/grep -E -m 2 'State:|Chipset:' || true

section "Relevant host processes"
/usr/bin/pgrep -fal '^/System/Library/PrivateFrameworks/ReplicatorCore\.framework/Support/replicatord$|^/System/Applications/iPhone Mirroring\.app/|/AirDropHandoffExtension\.appex/' || true

section "Developer-visible devices"
if /usr/bin/xcrun --find devicectl >/dev/null 2>&1; then
  /usr/bin/xcrun devicectl list devices 2>&1 | /usr/bin/awk 'NR <= 2 || /physical/' | redact_stream
else
  print "devicectl unavailable"
fi

section "Replicator state paths"
replicator_directory="$HOME/Library/Group Containers/group.com.apple.replicatord/replicatord"
for state_item in records replicatord.sql replicatord.sql-shm replicatord.sql-wal tmp; do
  state_target="$replicator_directory/$state_item"
  state_display="~/Library/Group Containers/group.com.apple.replicatord/replicatord/$state_item"
  if [[ -e "$state_target" ]]; then
    state_metadata=$(/usr/bin/stat -f 'mode=%Sp | size=%z | modified=%Sm' "$state_target" 2>&1)
    print "$state_display | $state_metadata"
  else
    print "missing: $state_display"
  fi
done

section "Relevant unified-log signatures from the last ${minutes}m"
diagnostic_temp_root="${TMPDIR:-/tmp}"
diagnostic_tmp_directory=$(/usr/bin/mktemp -d "${diagnostic_temp_root%/}/repair-iphone-mirroring.XXXXXX") || exit 1
raw_log="$diagnostic_tmp_directory/unified.log"
log_error="$diagnostic_tmp_directory/unified.err"
trap '/bin/rm -f "$raw_log" "$log_error"; /bin/rmdir "$diagnostic_tmp_directory" 2>/dev/null || true' EXIT HUP INT TERM

/usr/bin/log show --last "${minutes}m" --style compact --info --debug \
  --predicate '(process == "iPhone Mirroring") OR (process == "replicatord") OR (process == "rapportd")' \
  >"$raw_log" 2>"$log_error"
log_status=$?

if (( log_status == 0 )); then
  print "collection_status: success"
  /usr/bin/grep -Ei 'noCompatiblePhone|Checking if Replicator|relationship|persona ID|personaID|isPaired|state: pairing|state: introduced|Unpaired|isCloudPaired|unsupported BLE device|MyiCloud|WiFiP2P|DeviceClose|QUIC|TLS|Local Authentication|Touch ID|AppleWatch authentication|Unlock succeeded|control stream|audio/video streams|ready to be on screen|Tearing down' "$raw_log" \
    | /usr/bin/awk '
      / rapportd\[/ {
        rapport_count++
        if (rapport_count <= 20) print
        next
      }
      { print }
      END {
        if (rapport_count > 20) {
          print "... suppressed " (rapport_count - 20) " additional rapportd lines ..."
        }
      }
    ' \
    | redact_stream \
    | /usr/bin/tail -n 400 || true
else
  print "collection_status: failed (log show exit $log_status)"
  if [[ -s "$log_error" ]]; then
    /usr/bin/tail -n 20 "$log_error" | redact_stream
  fi
  exit "$log_status"
fi
