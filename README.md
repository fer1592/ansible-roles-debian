# Ansible Debian
Contains a group of Ansible Roles ready to be used in a Debian 13 installation.

## Instructions

The intention of the following repository is to host a set of Ansible roles ready to be used on a Debian 13 installation. The main idea of this is to invoke the roles in your playbook in order to obtain the desired configurations. Each of the roles with its corresponding input variables are now listed in the following sections:

---

### Common

This role **must be the first** to be included in any playbook utilizing this repository. It handles initial setup, security hardening, Ansible dependencies, and network management tools.

#### Performed Tasks

The `Common` role executes the following actions on the system:

* **Package Management:**
    * Updates the `apt` cache.
    * Installs essential packages: `git`, `jq`, `vim`, `openssh-server`, and **`network-manager`**.
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
    * Updates the local `ansible-debian` repository using `git pull`.
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
| `common_ansible_debian_repo_path` | Local path of the `ansible-debian` repository for the `git pull` command. | string | `.` | No | Usually the path where the playbook is executed. |
| `common_static_ip_config` | Configuration object to set a static IP via `nmcli`. | dict | **(Not Defined)** | No | **Warning: Triggers a scheduled reboot.** Requires `type`, `conn_name`, `ip4`, `ifname`, `gw4`, and `dns4` keys. |
| `common_avahi_enabled` | Enables the installation and service of Avahi for mDNS. | boolean | `false` | No | Installs `avahi-daemon` and `avahi-utils`. |
| `common_avahi_publish_hostname` | Hostname to publish on the local network if Avahi is enabled. | string | **(Not Defined)** | No | Example: `my-server.local` |
| `common_systemd_timer_oncalendar` | Expression to be used in the systemd unit that will call the playbook execution periodically. Check for examples [here](https://wiki.archlinux.org/title/Systemd/Timers). | string | **(Not Defined)** | Yes | Example: `daily`
| `common_systemd_timer_onbootsec` | If defined, it will set the field `OnBootSec` in the `Systemd` timer unit. Allows to execute the playbook after an X ammount of time after the system boot. | string | **(Not Defined)** | No | Example: `15min` |

## Initial Configuration Script (`scripts/config.sh`)

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