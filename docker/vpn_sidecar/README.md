# VPN Sidecar (Experimental)

This is a **local-only** experiment to bring up a VPN sidecar container using
OpenConnect (AnyConnect-compatible). It is **not** intended for student use.

## Prereqs
- Docker Desktop running
- OpenConnect image pulled via compose
- Credentials for vpn.sjsu.edu

## Usage

Create a `.env` file in this folder (do not commit):

```
VPN_ENDPOINT=vpn.sjsu.edu
VPN_USER=your_username
VPN_PASS=your_password
# VPN_GROUP=optional_group
```

Start the sidecar:

```
docker compose up --remove-orphans
```

Stop it:

```
docker compose down
```

## Notes
- This uses `/dev/net/tun` and NET_ADMIN capabilities.
- If your VPN requires MFA or a different auth flow, OpenConnect may need
  additional flags or a different protocol.
- To test connectivity once connected, try:
  `curl -I http://fineg02.engr.sjsu.edu/labcond.html`
