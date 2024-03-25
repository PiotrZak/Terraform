
1. Provision Docker script

This Bash script performs several actions related to installing Docker and configuring its settings on a Linux system, specifically on Ubuntu.

2. Provision EBS script

This script essentially automates the setup process for attaching, formatting, and mounting an EBS volume on an AWS EC2 instance. It ensures that the volume is properly configured and will be mounted automatically on subsequent reboots.

3. Provision Swap script

This script automates the process of creating and configuring a swap file on a Linux system, ensuring that the settings persist across reboots. Additionally, it adjusts the swappiness parameter according to the provided value.

___

Security.tf

- SSH Key Pair:
- Security Group:
- Security Group Rules:

Outputs.tf

- hostname
- public_ip
- instance_id
- availability_zone
- ssh_username
- ssh_private_key_path
- ssh_private_key
- security_group_id

Main.tf

- Main EC2 Instance
- Data Volume Attachment
- Null Resource for Provisioners


