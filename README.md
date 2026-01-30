# RHCE Training Lab Infrastructure (Terraform & AWS)
This repository contains **Terraform** code to provision a fully functional **Red Hat Certified Engineer (RHCE) EX294** exam preparation environment on AWS.

It automates the deployment of 5 RHEL 8 virtual machines, configures private DNS, handles root-level SSH access between nodes, and attaches required storage, strictly adhering to the lab topology required for common RHCE practice exams.

## 🏗 Lab Topology
The infrastructure provisions the following resources in a private VPC:

| Hostname | DNS Name | Role | Hardware Specs | 
| ----- | ----- | ----- | ----- | 
| **ansible-control** | `ansible-control.hyfertechsolutions.com` | Control Node | t2.medium | 
| **ansible-node1** | `ansible-node1.hyfertechsolutions.com` | Managed Host | t2.micro | 
| **ansible-node2** | `ansible-node2.hyfertechsolutions.com` | Managed Host | t2.micro | 
| **ansible-node3** | `ansible-node3.hyfertechsolutions.com` | Managed Host | t2.micro | 
| **ansible-db** | `ansible-db.hyfertechsolutions.com` | Database Host | t2.micro + **1GB Extra Disk** | 

### Key Features
* **Networking:** Custom VPC with a private Route53 Hosted Zone (`hyfertechsolutions.com`) and DHCP Options to ensure valid Forward and Reverse DNS resolution.
* **External Access:** You connect to all nodes as the user `hyfer` using your personal AWS Key Pair.
* **Root Access:** Cloud-Init scripts automatically enable Root login and inject SSH keys to allow the Control Node to SSH into all managed nodes as `root` without a password.
* **Storage:** `ansible-db` is automatically provisioned with the required `/dev/sdb` (1GB) for LVM tasks.
* **CI/CD:** Fully automated deployment via GitHub Actions and Terraform Cloud.

## 🚀 Setup & Prerequisites

### 1. AWS
* You need an AWS Account.
* An existing **EC2 Key Pair** (PEM format) created in your target region (e.g., `us-east-1`).
* **Cost Warning:** This lab runs 5 EC2 instances. While they are small, they **will incur costs** while running. Always use the **Destroy** workflow when finished practicing.

### 2. Terraform Cloud

1. Create a Workspace named `rhce-lab`.
2. Set the **Execution Mode** to **Remote**.
3. Add the following **Environment Variables**:
   * `AWS_ACCESS_KEY_ID`
   * `AWS_SECRET_ACCESS_KEY`
4. Add the following **Terraform Variables**:
| Variable | Type | Description | 
| ----- | ----- | ----- | 
| `AWS_SSH_KEY` | String | The **Name** of your key pair in AWS (e.g., `my-laptop-key`). |
| `ssh_allowed_cidr` | String | Your IP address (e.g., `1.2.3.4/32`) to allow SSH access. | 

### 3. GitHub
1. Go to **Settings > Secrets and variables > Actions**.
2. Add a secret named `TF_API_TOKEN` containing your Terraform Cloud User/Team API Token.

## 🕹 Usage

### Deploying (Apply)
1. **Push to Main:** Any push to the `main` branch will automatically trigger a `terraform apply`.
2. **Manual Trigger:** Go to the **Actions** tab in GitHub, select **Terraform Infrastructure**, click **Run workflow**, and ensure **Terraform Action** is set to `apply`.

### Destroying (Cleanup)
**Critical:** To stop billing, destroy the lab when done.
1. Go to the **Actions** tab in GitHub.
2. Select **Terraform Infrastructure**.
3. Click **Run workflow**.
4. Change **Terraform Action** to `destroy`.
5. Run the workflow.

## 💻 Connecting to the Lab
1. After the `apply` finishes, get the **Control Node Public IP** from the Terraform Output or AWS Console.
2. SSH into the control node using your local key (Note the user is `hyfer`):
```bash
ssh -i /path/to/your-key.pem hyfer@<CONTROL_NODE_IP>
```
3. Switch to root:
```bash
sudo -i
```
4. Verify Internal Access: Switch to root and test connectivity to a managed node:
```bash
sudo su -
ssh ansible-node1.hyfertechsolutions.com
```

## 📚 Lab Questions & Exam Tasks
This environment is designed to support the Ansible Sample Exam for EX294 provided by Lisenet.  
👉 [Click here to view the Lab Questions and Tasks](https://www.lisenet.com/2019/ansible-sample-exam-for-ex294/)

⚠️ Note on Solutions
The ansible/ directory in this repository contains configuration files and scripts that act as solutions or starting points for the tasks.

I strongly recommend attempting to solve the tasks yourself first before looking at the files in that directory. The best way to prepare for the exam is to build your own playbooks from scratch!

## 📝 License
This project is for educational purposes.
