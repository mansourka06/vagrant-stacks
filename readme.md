# VAGRANT-DEVOPS-LAB

Linux Tool Installation Script

## Requirements

- [x] **Vagrant installed on your local host**
- [x] **vagrant-vbguest plugins**: before you must install these plugins to speed up vagrant provisionning
```bash
vagrant plugin install vagrant-vbguest --plugin-version 0.21
vagrant plugin install vagrant-faster
vagrant plugin install vagrant-cachier
```

## Installation

This script automates the installation of various tools on a Linux system. It supports installing:
- [x] **Common Linux Tools:** curl git net-tools gnupg software-properties-common tree telnet vim
- [x] **Ansible**
- [x] **Docker**
- [x] **Terraform** 
- [x] **Jenkins**
- [x] **Minikube**



## Usage

### Commands :

1. **Clone this repository** :
```bash
git clone https://github.com/mansourka06/vagrant-devops-lab.git
```

2. **Run the installation** : open a terminal and navigate to the directory where the script is located
```bash
vagrant up
```


> **NOTE:**
 - Replace the list of packages as needed.
 - The script assumes a CentOS or Red Hat-based distribution.
 - For Jenkins installation, make sure to review Jenkins' official documentation for any additional setup steps.



> **Available Options:**
 - ON : Enable tool installation
 - OFF : Disable tool installation
 

3. **To shutdown VM use command above** :
```bash
vagrant halt
```

## Author
Mansour KA
