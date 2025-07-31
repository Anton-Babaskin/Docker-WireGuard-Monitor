# Docker WireGuard Monitor (wg\_telemon)

This repository provides a simple Bash-based monitor script and systemd timer for any WireGuard server running inside a Docker container. It will:

* Check that the specified container is **running**
* Verify that the WireGuard interface exists and is **UP**
* Inspect the **latest handshake** timestamp for each peer and alert if it is `never` or older than a configurable threshold
* Send real-time alerts to a Telegram chat via Bot API

---

## Features

* **Container agnostic**: specify your Docker container name
* **Interface agnostic**: customize the WireGuard interface (default `wg0`)
* **Threshold-based handshake check**: configurable age in seconds
* **Lightweight**: pure Bash + curl, no Python dependencies
* **Systemd integration**: service + timer for reliable scheduling

## Quick Setup

1. **Clone this repo** on your host:

   ```bash
   git clone https://github.com/your-org/wg_telemon.git /opt/wg_telemon
   cd /opt/wg_telemon
   ```

2. **Configure environment** (`/etc/telemon.env`):

   ```ini
   BOT_TOKEN=123456789:ABCdefGhIjKlmnoPQRsTUVwxyz
   CHAT_ID=1234567890
   WG_CONTAINER=your-wg-docker-container
   WG_IFACE=wg0          # WireGuard interface name inside container
   THRESHOLD=120         # seconds without handshake → alert
   ```

   ```bash
   chmod 600 /etc/telemon.env
   ```

3. **Install the script**:

   ```bash
   sudo cp wg_telemon.sh /usr/local/bin/wg_telemon.sh
   sudo chmod +x /usr/local/bin/wg_telemon.sh
   ```

4. **Register systemd unit & timer**:

   ```bash
   sudo cp wg-telemon.service /etc/systemd/system/
   sudo cp wg-telemon.timer   /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now wg-telemon.timer
   ```

5. **Verify operation**:

   ```bash
   sudo systemctl start wg-telemon.service
   sudo journalctl -u wg-telemon.service -n20
   ```

---

## Script Details (`wg_telemon.sh`)

```bash
#!/usr/bin/env bash
source /etc/telemon.env

# send text alert to Telegram
send() {
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
       -d "chat_id=${CHAT_ID}" \
       --data-urlencode "text=$1" >/dev/null
}

# 1) Container run check
if ! docker inspect -f '{{.State.Running}}' "${WG_CONTAINER}" 2>/dev/null | grep -q true; then
  send "🚨 ${WG_CONTAINER} not running!"
  exit 0
fi

# 2) Interface existence
link=$(docker exec "${WG_CONTAINER}" ip link show "${WG_IFACE}" 2>/dev/null) || {
  send "🚨 ${WG_IFACE} missing!"
  exit 0
}

# 3) Interface UP flag
flags=$(echo "$link" | head -1 | sed -n 's/.*<\(.*\)>.*/\1/p')
if ! echo "$flags" | grep -qw UP; then
  send "⚠️ ${WG_IFACE} is DOWN (${flags})"
  exit 0
fi

# 4) Handshake age
alerts=()
while IFS= read -r line; do
  if [[ $line == peer:* ]]; then
    peer=${line#peer:\ }
  elif [[ $line =~ latest[[:space:]]handshake:[[:space:]]([0-9]+|never) ]]; then
    val=${BASH_REMATCH[1]}
    if [[ $val == never ]] || (( val > THRESHOLD )); then
      alerts+=("Peer $peer ➜ handshake ${val}s ago")
    fi
  fi
done < <(docker exec "${WG_CONTAINER}" wg show "${WG_IFACE}")

if ((${#alerts[@]})); then
  send "⚠️ WG issues:\n$(printf '%s\n' "${alerts[@]}")"
fi
```

---

## Systemd Units

* **`wg-telemon.service`**

  ```ini
  [Unit]
  Description=WireGuard Telegram Monitor
  Wants=docker.service
  After=docker.service

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/wg_telemon.sh
  ```

* **`wg-telemon.timer`**

  ```ini
  [Unit]
  Description=Run WireGuard monitor every minute

  [Timer]
  OnBootSec=1min
  OnUnitActiveSec=1min
  AccuracySec=5s

  [Install]
  WantedBy=timers.target
  ```

Enable with:

```bash
systemctl daemon-reload
systemctl enable --now wg-telemon.timer
```

---

## Testing & Troubleshooting

1. **Manual run**:

   ```bash
   systemctl start wg-telemon.service
   journalctl -u wg-telemon.service -n20
   ```

2. **Container down**:

   ```bash
   docker stop ${WG_CONTAINER}
   # → Telegram: "not running"
   docker start ${WG_CONTAINER}
   ```

3. **Interface down**:

   ```bash
   docker exec ${WG_CONTAINER} ip link set ${WG_IFACE} down
   # → Telegram: "${WG_IFACE} is DOWN"
   docker exec ${WG_CONTAINER} ip link set ${WG_IFACE} up
   ```

4. **Handshake test**:
   Block UDP port on host:

   ```bash
   iptables -I INPUT -p udp --dport 51820 -j DROP
   # → handshake alerts
   iptables -D INPUT -p udp --dport 51820 -j DROP
   ```

Now you have a **Docker-based WireGuard monitor** ready for any container and interface. Feel free to customize thresholds, intervals, or add more checks!
