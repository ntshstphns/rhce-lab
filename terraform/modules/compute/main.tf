# modules/compute/main.tf

# --- Key Generation (Internal Cluster Key) ---
resource "tls_private_key" "lab_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# --- AMI Lookup ---
data "aws_ami" "rhel8" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat
  filter {
    name   = "name"
    values = ["RHEL-8.*-x86_64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- 1. Ansible Control Node ---
resource "aws_instance" "control" {
  ami                    = data.aws_ami.rhel8.id
  instance_type          = "t2.medium"
  subnet_id              = var.subnet_id
  key_name               = var.AWS_SSH_KEY
  vpc_security_group_ids = [var.security_group]
  
  tags = { Name = "ansible-control" }

  # Cloud-Init:
  # 1. Create 'hyfer' user
  # 2. Copy YOUR key (from ec2-user) to hyfer and root
  # 3. Add INTERNAL GENERATED public key to root authorized_keys (for inter-node comms)
  # 4. Inject INTERNAL GENERATED private key into /root/.ssh/id_rsa
  user_data = <<-EOF
    #cloud-config
    users:
      - default
      - name: hyfer
        groups: [wheel]
        sudo: ["ALL=(ALL) NOPASSWD:ALL"]
        shell: /bin/bash

    hostname: ansible-control.hyfertechsolutions.com
    fqdn: ansible-control.hyfertechsolutions.com
    preserve_hostname: true
    manage_etc_hosts: true
    ssh_pwauth: true
    disable_root: false

    runcmd:
      - [ sh, -c, "hostnamectl set-hostname ansible-control.hyfertechsolutions.com" ]
      
      # --- Setup Hyfer User (Your Key) ---
      - [ sh, -c, "mkdir -p /home/hyfer/.ssh" ]
      - [ sh, -c, "cp /home/ec2-user/.ssh/authorized_keys /home/hyfer/.ssh/" ]
      - [ sh, -c, "chown -R hyfer:hyfer /home/hyfer/.ssh" ]
      - [ sh, -c, "chmod 700 /home/hyfer/.ssh" ]
      - [ sh, -c, "chmod 600 /home/hyfer/.ssh/authorized_keys" ]

      # --- Setup Root User (Your Key) ---
      - [ sh, -c, "cp /home/ec2-user/.ssh/authorized_keys /root/.ssh/" ]
      
      # --- Add Internal Cluster Public Key to Root ---
      - [ sh, -c, "echo '${tls_private_key.lab_key.public_key_openssh}' >> /root/.ssh/authorized_keys" ]
      
      # --- Final Permissions & Contexts ---
      - [ sh, -c, "chmod 600 /root/.ssh/authorized_keys" ]
      - [ sh, -c, "chown root:root /root/.ssh/authorized_keys" ]
      - [ sh, -c, "restorecon -R /root/.ssh /home/hyfer/.ssh" ]

    write_files:
      - encoding: b64
        content: ${base64encode(tls_private_key.lab_key.private_key_pem)}
        path: /root/.ssh/id_rsa
        permissions: '0600'
        owner: root:root
  EOF
}

# --- 2. Managed Nodes (Node 1, 2, 3) ---
resource "aws_instance" "managed" {
  count                  = 3
  ami                    = data.aws_ami.rhel8.id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  key_name               = var.AWS_SSH_KEY
  vpc_security_group_ids = [var.security_group]

  tags = { Name = "ansible-node${count.index + 1}" }

  user_data = <<-EOF
    #cloud-config
    users:
      - default
      - name: hyfer
        groups: [wheel]
        sudo: ["ALL=(ALL) NOPASSWD:ALL"]
        shell: /bin/bash

    hostname: ansible-node${count.index + 1}.hyfertechsolutions.com
    fqdn: ansible-node${count.index + 1}.hyfertechsolutions.com
    preserve_hostname: true
    manage_etc_hosts: true
    disable_root: false

    runcmd:
      - [ sh, -c, "hostnamectl set-hostname ansible-node${count.index + 1}.hyfertechsolutions.com" ]
      
      # --- Setup Hyfer User (Your Key) ---
      - [ sh, -c, "mkdir -p /home/hyfer/.ssh" ]
      - [ sh, -c, "cp /home/ec2-user/.ssh/authorized_keys /home/hyfer/.ssh/" ]
      - [ sh, -c, "chown -R hyfer:hyfer /home/hyfer/.ssh" ]
      - [ sh, -c, "chmod 700 /home/hyfer/.ssh" ]
      - [ sh, -c, "chmod 600 /home/hyfer/.ssh/authorized_keys" ]

      # --- Setup Root User (Your Key) ---
      - [ sh, -c, "cp /home/ec2-user/.ssh/authorized_keys /root/.ssh/" ]

      # --- Add Internal Cluster Public Key to Root ---
      - [ sh, -c, "echo '${tls_private_key.lab_key.public_key_openssh}' >> /root/.ssh/authorized_keys" ]

      # --- Final Permissions & Contexts ---
      - [ sh, -c, "chmod 600 /root/.ssh/authorized_keys" ]
      - [ sh, -c, "chown root:root /root/.ssh/authorized_keys" ]
      - [ sh, -c, "restorecon -R /root/.ssh /home/hyfer/.ssh" ]
  EOF
}

# --- 3. Database Node (ansible-db) with Extra Disk ---
resource "aws_instance" "db_node" {
  ami                    = data.aws_ami.rhel8.id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  key_name               = var.AWS_SSH_KEY
  vpc_security_group_ids = [var.security_group]

  tags = { Name = "ansible-db" }

  user_data = <<-EOF
    #cloud-config
    users:
      - default
      - name: hyfer
        groups: [wheel]
        sudo: ["ALL=(ALL) NOPASSWD:ALL"]
        shell: /bin/bash

    hostname: ansible-db.hyfertechsolutions.com
    fqdn: ansible-db.hyfertechsolutions.com
    preserve_hostname: true
    manage_etc_hosts: true
    disable_root: false

    runcmd:
      - [ sh, -c, "hostnamectl set-hostname ansible-db.hyfertechsolutions.com" ]
      
      # --- Setup Hyfer User (Your Key) ---
      - [ sh, -c, "mkdir -p /home/hyfer/.ssh" ]
      - [ sh, -c, "cp /home/ec2-user/.ssh/authorized_keys /home/hyfer/.ssh/" ]
      - [ sh, -c, "chown -R hyfer:hyfer /home/hyfer/.ssh" ]
      - [ sh, -c, "chmod 700 /home/hyfer/.ssh" ]
      - [ sh, -c, "chmod 600 /home/hyfer/.ssh/authorized_keys" ]

      # --- Setup Root User (Your Key) ---
      - [ sh, -c, "cp /home/ec2-user/.ssh/authorized_keys /root/.ssh/" ]

      # --- Add Internal Cluster Public Key to Root ---
      - [ sh, -c, "echo '${tls_private_key.lab_key.public_key_openssh}' >> /root/.ssh/authorized_keys" ]

      # --- Final Permissions & Contexts ---
      - [ sh, -c, "chmod 600 /root/.ssh/authorized_keys" ]
      - [ sh, -c, "chown root:root /root/.ssh/authorized_keys" ]
      - [ sh, -c, "restorecon -R /root/.ssh /home/hyfer/.ssh" ]
  EOF
}

resource "aws_ebs_volume" "secondary_disk" {
  availability_zone = "us-east-2a"
  size              = 1
  tags = { Name = "ansible-db-secondary" }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.secondary_disk.id
  instance_id = aws_instance.db_node.id
}