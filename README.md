# Ansible Debian
Contains a group of Ansible Roles ready to be used in a Debian 13 installation.

## Roles

The intention of the following repository is to host a set of Ansible roles ready to be used on a Debian 13 installation, and just in a single host locally. The main idea of this is to invoke the roles in your playbook in order to obtain the desired configurations. Each of the roles with its corresponding input variables are now listed in the following sections:

### Why just for local usage?

This is just for personal usage on a homeserver, so it's intended to run and self-heal and auto-update with minimal intervention. For sure it is possible to adapt it to use it in multiple hosts, but since it's not my use case, I haven't adapted it. If I ever release this and someone finds this useful, and whishes to contribute to adapt this, feel free to do so, I'll be happy to help.

---

### Common

This role **must be the first** to be included in any playbook utilizing this repository. It handles initial setup, security hardening, Ansible dependencies, and network management tools.

#### Performed Tasks

The `Common` role executes the following actions on the system:

* **Package Management:**
    * Updates the `apt` cache.
    * Installs essential packages: `git`, `jq`, `vim`, `openssh-server`, `curl`, `gpg`, and `network-manager`.
    * Installs `avahi-daemon` and `avahi-utils` if Multicast DNS (mDNS) is enabled (`common_avahi_enabled`).
    * Installs any extra packages defined by the user (`common_extra_packages`).
    * Upgrades all system packages (`apt upgrade dist`) and auto-removes unneeded packages (`autoremove`, `purge`).
* **SSH Security and Access:**
    * Ensures password authentication (`PasswordAuthentication`) is disabled and public key authentication (`PubkeyAuthentication`) is enabled in `sshd_config`, if configured (`common_ssh_disable_password_authentication`).
    * Adds specified public SSH keys (`common_sshd_authorized_keys`) to the current user's `~/.ssh/authorized_keys` file.
    * Restarts the SSH service if the configuration has changed.
* **Ansible and Python Management:**
    * Installs and ensures `pip`, `ansible`, and `ansible-core` are up-to-date.
    * Ensures the `community.general` Ansible Galaxy collection is installed and updated.
* **Repository Control:**
    * Configures Git globally to prevent automatic rebase (`pull.rebase: false`).
    * Ensures GitHub SSH host keys are added to `known_hosts` for the current user.
    * Updates the local `ansible-roles-debian` repository using `git pull`.
* **Playbook Automation (Cron):**
    * Creates a `systemd` unit (`.service`) to execute the current playbook.
    * Creates and enables a `systemd` timer unit (`.timer`) to periodically execute the service unit (simulating a Cron job).
* **Network Configuration (Optional):**
    * Allows configuration of a static IP address using `nmcli` if `common_static_ip_config` is defined. **If the static IP is applied, a system reboot is scheduled in 3 minutes**.
* **Hostname Publishing (Optional):**
    * If Avahi is enabled, it creates and manages a `systemd` service to publish a specific hostname (`common_avahi_publish_hostname`) using `avahi-publish`.

#### Input Variables

It is recommended to define these variables in the `group_vars/all.yml` file or pass them directly to the playbook.

| Variable | Description | Type | Default Value | Mandatory | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `common_playbook_name` | **Name of the main playbook file**. Used to name the systemd service and timer units for cron automation. | string | **(None)** | Yes | Example: server_setup.yml |
| `common_sshd_authorized_keys` | List of public SSH keys to include in `authorized_keys`. | list | **(None)** | Yes | Example: `['ssh-rsa AAA... user1', 'ssh-ed25519 AAA... user2']` |
| `common_sshd_disable_password_authentication`| Disables password authentication in `sshd_config`. | boolean | **(Not Defined)** | No | If set to `true`, changes `PasswordAuthentication no`. |
| `common_extra_packages` | List of additional Debian packages to install via `apt`. | list | `[]` | No | Example: `['htop', 'tmux', 'curl']` |
| `common_ansible_roles_debian_repo_path` | Local path of the `ansible-roles-debian` repository for the `git pull` command. | string | `.` | No | Usually the path where the playbook is executed. |
| `common_static_ip_config` | Configuration object to set a static IP via `nmcli`. | dict | **(Not Defined)** | No | **Warning: Triggers a scheduled reboot.** Requires `type`, `conn_name`, `ip4`, `ifname`, `gw4`, and `dns4` keys. |
| `common_avahi_enabled` | Enables the installation and service of Avahi for mDNS. | boolean | `false` | No | Installs `avahi-daemon` and `avahi-utils`. |
| `common_avahi_publish_hostname` | Hostname to publish on the local network if Avahi is enabled. | string | **(Not Defined)** | No | Example: `my-server.local` |
| `common_systemd_timer_oncalendar` | Expression to be used in the systemd unit that will call the playbook execution periodically. Check for examples [here](https://wiki.archlinux.org/title/Systemd/Timers). | string | **(Not Defined)** | Yes | Example: `daily`
| `common_systemd_timer_onbootsec` | If defined, it will set the field `OnBootSec` in the `Systemd` timer unit. Allows to execute the playbook after an X ammount of time after the system boot. | string | **(Not Defined)** | No | Example: `15min` |

### docker-host

This role handles the idempotent installation of the Docker Community Edition (CE) stack. It automatically configures the necessary official repositories for your Debian release and architecture (`amd64`/`arm64`). It also adds the current user to the `docker` group, enabling the use of the Docker CLI without `sudo` after a session restart. It also ensures the core services are running and performs essential cleanup of unused resources.

### Input Variables

No input variables needed

### AdGuard Home

This role handles the deployment and configuration of AdGuard Home using Docker. It allows for full configuration through a Jinja2 template, and optionally integrates with Avahi for mDNS service publishing.

#### Performed Tasks

* **Image Management:** Pulls the latest stable `adguard/adguardhome` Docker image.
* **Directory Structure:** Creates persistent directories for configuration and work data within the user's home directory (`ansible-roles-debian-data/adguard`).
* **Configuration:** Generates the `AdGuardHome.yaml` configuration file from a template whenever the `adguard_config` variable is defined.
* **Container Management:** Runs the AdGuard Home container with resource limits (CPUs, Memory), custom port mappings, and persistent volume mounts.
* **Service Health:** Automatically restarts the container if the configuration template changes.
* **Avahi Integration (Optional):** If enabled and the `avahi-daemon` is running, it creates and starts a systemd service to publish AdGuard Home on the local network.

#### Input Variables

| Variable | Description | Type | Default Value | Mandatory |
| :--- | :--- | :--- | :--- | :--- |
| `adguard_config` | Dictionary containing the AdGuard Home YAML configurations you want to include in the configuration. If you don't want to keep the configuration in the values, it's recommended to don't include this variable, and let AdGuard to manage it. | dict | **(Not Defined)** | No |
| `adguard_ports` | List of port mappings for the Docker container (e.g., `["53:53/udp", "80:80/tcp"]`). | list | **(None)** | Yes |
| `adguard_cpus` | CPU limit for the container. | string | **(None)** | Yes |
| `adguard_memory` | Memory and swap limit for the container. | string | **(None)** | Yes |
| `adguard_docker_network` | Name of the Docker bridge network to create/use. | string | `bridge` | No |
| `adguard_avahi_publish` | Enables the creation of a systemd service to publish via Avahi. | boolean | `false` | No |

## Initial Configuration

In order to use the previous roles, you will need:
1. To configure an `ssh` key, which should be registered in your github account, in order to allow the playbook to keep the roles up to date.
2. An ansible playbook that calls these roles.
3. An inventory file, which just basically have point to local.

### SSH key

If you already cloned this repo in the system where you want to use these roles, then feel free to skip this section. If you haven't generated the `ssh` key, then open the terminal and follow the next steps:

1. Create the ´.ssh´ directory if it doesn't exist:
```bash
mkdir -p ~/.ssh
```

2. Copy or create your SSH key in the ´.ssh´ directory:
```bash
ssh-keygen -t ed25519 -b 512 -C "<your email here>" # to generate a new key
```

Make sure you add the public key into your github account. You can do this by copying the content of the public key file:
```bash
cat ~/.ssh/id_ed25519.pub
```

Then, go to your GitHub account settings, navigate to `SSH and GPG keys`, and add a new SSH key. Paste the content of the public key file into the key field.

3. Clone this repository into your raspberry pi:
```bash
git clone git@github.com:fer1592/ansible-roles-debian.git
```

### Ansible playbook

To use the roles contained in this repository, you simply need to create a main playbook file (e.g., `main.yml`) that targets your host and imports the roles.

**Crucial Step:** When invoking the roles, you must define all **Mandatory** variables listed in the role documentation, for the roles you are using. If you are using the [Ansible Alternative directory layout](https://docs.ansible.com/projects/ansible/latest/tips_tricks/sample_setup.html#alternative-directory-layout), you can define the variables in the `group_vars` for your host instead of doing that in the runbook.

#### Example Playbook (`home-assistant.yml`)

This example demonstrates how to include the `Common` role and define its mandatory variables:

```yaml
---
- name: Run Initial Server Setup
  hosts: local
  gather_facts: yes
  become: yes
  vars: # you can "ommit" this section if you follow the recommendations of the next section
    common_playbook_name: home-assistant.yml
    common_sshd_authorized_keys:
      - ssh-rsa AAAAB3Nza... your_first_key_here
      - ssh-ed25519 AAAAC3Nz... your_second_key_here
    common_extra_packages:
      - htop
      - tmux
    common_ssh_disable_password_authentication: true
    common_systemd_timer_oncalendar: "daily"
  roles:
    # 1. The Common role must always be included first
    - role: common
    # 2. Other roles would be listed here
    # - role: openmediavault
    # - role: docker_services
```

### Inventory file

I've designed these roles to be used in a directory structure as explained in the [Ansible Alternative directory layout](https://docs.ansible.com/projects/ansible/latest/tips_tricks/sample_setup.html#alternative-directory-layout), so, my recommendation for you is just to use it as well, since any warning for running the playbook with `local` will be suppressed. You can even create the playbook and inventory files in the current repository, since they will be just ignored by git. Basically, if you follow my way, for the inventory you will just need the following files:

- `inventories/local/hosts`. Content should be:

```
[local]
localhost ansible_python_interpreter="{{ ansible_playbook_python }}"
```

- inventories/local/group_vars/local.yml

```yaml
---
# Here you can define all the variables to use in your playbook
```

### The `config.sh` script

The provided script `scripts/config.sh` is designed to be executed on a clean Debian installation to set up the environment necessary to run Ansible playbooks.

**Key features of the script:**
* Installs base dependencies (`python3-pip`, etc.).
* Creates a dedicated Python Virtual Environment (`venv/ansible`).
* Installs `ansible` and required collections (e.g., `community.docker`).
* **Sudoers Management:** The script automatically adds the current executing user to the `sudo` group and configures **passwordless sudo** access for all subsequent commands within the script.

**Execution:**
Before running the script, make sure that:
1. `sudo` is installed. You can run any command with `sudo`. If the command fails because `sudo` was not found, install it and configure it as follows:

```bash
su
# enter your sudo password
apt get update
apt install sudo
```

2. Your user is allowed to call sudo without a password. Why? Since the playbook install and update packages it's a requirement, it needs to be able to run things as root. If you consider that as a security risk, you could try to create a different user for ansible and add it as a sudoer, however that's something I didn't have time to test. In order to add your user as a sudoer, type in the terminal the following:

```bash
# still as root
touch /etc/sudoers.d/<your username>
echo "<your username> ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/<your username> > /dev/null
exit
```

Once you are back to your own prompt, running any command with `sudo` shouldn't require the password anymore.

To run the script, use:
```bash
sh scripts/config.sh
```

**Important**: When executing the script, you will be prompted to enter your user's password once for the first sudo command. After successfully entering the password, all following sudo commands in the script will be executed without further password prompts.

**Important**: The following expects your playbook directory to follow the [Alternative directory layout](https://docs.ansible.com/projects/ansible/latest/tips_tricks/sample_setup.html#alternative-directory-layout), and it hardcodes the inventory path to `inventories/local/hosts`. You can update the script to your needs or skip it completely. You can also create the playbooks and inventories in the current repository, since those files will be ignored (that is how I'm actually using this)