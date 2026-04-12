# AGENTS.md
## Repository Context
**ansible-roles-debian** - Collection of Ansible roles for automated Debian 13 server/desktop setup on single local host. Containerized services with persistent Docker storage, idempotent automated operations, mDNS local discovery, resource management, security hardening, token protection via Ansible Vault.

## Core Architecture
**Common Role** - Foundation: package management, SSH security, systemd timers for periodic playbook automation, network configuration (static IP, Wake-on-LAN), Docker installation, user permissions.

**docker-host Role** - Docker CE stack assembly for containerized services.

## Service Deployment Roles
- **adguard-home** - DNS/ad blocker
- **home-assistant** - Smart home automation
- **vaultwarden** - Password manager
- **n8n** - Workflow automation
- **jellyfin-server** - Media server with GPU acceleration
- **certbot** - SSL certificate management
- **nginx web-server** - Reverse proxy
- **twingate-connector** - Zero-trust network access
- **ntfy** - Pub/sub notifications
- **opencloud** - File sharing
- **xmrig** - Cryptocurrency miner
- **omada-controller** - TP-Link Omada smart networking management

## Key Features
- Self-healing/automation: Systemd timers auto-rollback playbook changes
- Local discovery: mDNS (Avahi) publishes services
- Resource management: CPU/memory limits per container
- Security: Ansible Vault encryption, hardened SSH, token management
- Idempotent: Safe repeated execution

## Code Style Guidelines
- Follow existing role patterns
- Ansible best practices (avoid idempotency issues, correct module usage)
- Jinja2 templates validated
- Variable naming consistent with repo
- No hardcoded secrets (always use Ansible Vault)
- YAML syntax and formatting maintained
- After coding, you update the README.md documentation
