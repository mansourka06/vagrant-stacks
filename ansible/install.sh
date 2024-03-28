#!/bin/bash

##############################################################################################

set -e 

# ENABLE/DESABLE INSTALL TOOLS : Supported value [ON, OFF]
ANSIBLE=ON
DOCKER=ON
AWX=ON

# Check the system based Distribution
if [ -f /etc/debian_version ]; then
    echo "Detected a Debian-based distribution."
    # Update package list
    sudo apt update -y
    sudo apt-get upgrade -y
    # some settings for common server
    sudo apt install -y -qq curl git sshpass net-tools gnupg software-properties-common tree telnet vim 2>&1 >/dev/null

## If the distribution is neither Red Hat-based nor Debian-based
else
    echo "Unsupported distribution. Only Debian-based OS are Support for this stack !"
    exit 1
fi

#### Ansible User Creation #####
ansible_user="ansible"
ansible_user_pwd="ansible"

# Check if the user already exists
if id "$ansible_user" &>/dev/null; then
    echo "User $ansible_user already exists."
else
    # Create user with home directory
    sudo useradd -m -s /bin/bash "$ansible_user"

    # Set password for the new user
    echo "$ansible_user:$ansible_user_pwd" | sudo chpasswd

    # Add the user to the sudo group
    sudo usermod -aG sudo "$ansible_user"

    echo "User $ansible_user created with password and added to the sudo group."
fi

#### Ansible Installation #####
case $ANSIBLE in
    ON) # Install Ansible 
      sudo apt install -y ansible sshpass
      echo "Ansible installation completed."
      ansible --version

      ;;
    OFF)
      echo "skip ansible installation"
      ;;
    *)
     echo "Only ON or OFF value is supported, for ansible install"
     ;;
esac

#### Docker an Docker-ComposeInstallation #####
case $DOCKER in
    ON)
      # Check if Docker is installed
      if command -v docker &>/dev/null; then
        echo "Docker is already installed on $IP server"
        sudo usermod -aG docker vagrant
        sudo usermod -aG docker $ansible_user
        sudo systemctl enable docker
        sudo systemctl start docker
      else
        # install docker
        curl -fsSL https://get.docker.com -o get-docker.sh 2>&1
        sh get-docker.sh 2>&1 >/dev/null
        sudo usermod -aG docker $ansible_user
        sudo usermod -aG docker vagrant
        sudo systemctl enable docker
        sudo systemctl start docker

        #install docker compose
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker installation completed."
      fi
      ;;
    OFF)
      echo "skip docker installation"
      ;;
    *)
     echo "Only ON or OFF value is supported, for docker install"
     ;;
esac

#### AWX Installation #####
case $AWX in
    ON) 
    # Install requirements libs
      sudo apt install -y python3-pip
      pip3 install docker docker-compose --user

      # Clone AWX repository
      git clone --branch 17.0.1 https://github.com/ansible/awx.git
      
      cd awx/installer/

      # Run the AWX installer
      ansible-playbook -i inventory install.yml

      # Access AWX at http://localhost:80
      ;;
    OFF)
      echo "skip AWX installation"
      ;;
    *)
     echo "Only ON or OFF value is supported, for awx install"
     ;;
esac

##
echo "For this Stack, you will use $IP IP Address"
#####################################################################################################################