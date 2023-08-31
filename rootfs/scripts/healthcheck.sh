#!/command/with-contenv bash
# shellcheck disable=SC1091
set -e

# source healthcheck functions
source /opt/healthchecks-framework/healthchecks.sh

EXITCODE=0

# Determine which RTLSDR config file is in use
if [ -n "$RTLSDRAIRBAND_CUSTOMCONFIG" ]; then
    RTLSDRAIRBAND_CONFIGFILE='/run/rtlsdr-airband/rtl_airband.conf'
else
    RTLSDRAIRBAND_CONFIGFILE='/usr/local/etc/rtl_airband.conf'
fi

# Icecast checks

echo "ICECAST CONNETIVITY CHECKS:"

# Try to determine icecast servers / ports
# Start by isolating the icecast sections of the config.
#   - `tr -d '\n'` & `tr -d '\r'` - makes the whole config one line
#   - `tr -s ' '` - squashes whitespace (probably not required)
#   - `grep...` - returns only the stanzas that contain icecast configuration
ICECAST_CONFIG_LINES=$(tr -d '\n' < "$RTLSDRAIRBAND_CONFIGFILE" | tr -d '\r' | tr -s ' ' | grep -oP '{[^{}]*?type\s*=\s*"icecast"\s*;[^{}]*?}')

# If there are icecast connections configured...
if [[ -n "$ICECAST_CONFIG_LINES" ]]; then

    # For each icecast connection stanza...
    while read -r ICECAST_CONFIG_LINE; do
        
        # Get icecast server hostname/IP
        ICECAST_HOSTNAME=$(echo "$ICECAST_CONFIG_LINE" | grep -oP 'server\s*?=\s*?\K".*?"\s*;' | tr -d '";')
        ICECAST_IP=$(get_ipv4 "$ICECAST_HOSTNAME")

        # Get icecast server port
        ICECAST_PORT=$(echo "$ICECAST_CONFIG_LINE" | grep -oP 'port\s*?=\s*\K.*?\s*;' | tr -d '";')

        # Ensure connection is established
        echo "Checking icecast connection to $ICECAST_HOSTNAME:$ICECAST_PORT..."
        if check_tcp4_connection_established ANY ANY "$ICECAST_IP" "$ICECAST_PORT"; then
          :
        else
          EXITCODE=1
        fi

    done <<< "$ICECAST_CONFIG_LINES"

fi

exit "$EXITCODE"
