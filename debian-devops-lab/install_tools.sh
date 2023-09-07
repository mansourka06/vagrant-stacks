#!/bin/bash

#####################################################################################################################
IP=$(hostname -I | awk '{print $2}')

set -e 

# ENABLE/DESABLE INSTALL TOOLS : Supported value [ON, OFF]
ANSIBLE=OFF
DOCKER=OFF
JENKINS=OFF
MINIKUBE=OFF
TERRAFORM=OFF

# Check the system based Distribution
if [ -f /etc/debian_version ]; then
    echo "Detected a Debian-based distribution."
    # Update package list
    sudo apt update
    # some settings for common server
    sudo apt install -y -qq curl git net-tools gnupg software-properties-common tree telnet vim 2>&1 >/dev/null

## If the distribution is neither Red Hat-based nor Debian-based
else
    echo "Unsupported distribution. Only Debian-based OS are Support for this stack !"
    exit 1
fi

case $ANSIBLE in
    ON) # Install Ansible 
      sudo apt -y install ansible sshpass
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

case $DOCKER in
    ON)
      # Check if Docker is installed
      if command -v docker &>/dev/null; then
        echo "Docker is already installed on $IP server"
        sudo usermod -aG docker vagrant
        sudo systemctl enable docker
        sudo systemctl start docker
      else
        # install docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
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

case $TERRAFORM in
    ON) # Install Terraform
      TERRAFORM_VERSION="0.14.7" # Change this to the desired Terraform version
      wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
      unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
      sudo mv terraform /usr/local/bin/
      rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
      ;;
    OFF)
      echo "skip Terraform installation"
      ;;
    *)
     echo "Only ON or OFF value is supported, for terraform install"
     ;;
esac

case $JENKINS in
    ON) # Install Jenkins
      sudo wget -O /etc/apt-get.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
      sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
      sudo apt install -y jenkins
      sudo systemctl start jenkins
      sudo systemctl enable jenkins
      ;;
    OFF)
      echo "skip jenkins installation"
      ;;
    *)
     echo "Only ON or OFF value is supported, for jenkins install"
     ;;
esac

## Install zsh if needed
# To enable zsh: 
export ENABLE_ZSH="true" # comment this line if you don't want to install zsh

if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]; then
  echo "Checking ZSH install directory"

  if [ -d "/home/vagrant/.oh-my-zsh" ]; then
    echo "The ZSH install folder /home/vagrant/.oh-my-zsh already exists."
  else
    echo "We are going to install zsh"
    sudo rm -rf /home/vagrant/.oh-my-zsh
    sudo apt -y install zsh git
    echo "vagrant" | chsh -s /bin/zsh vagrant
    su - vagrant  -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - vagrant  -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git  docker docker-compose colored-man-pages aliases copyfile  copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
  fi
else
    echo "The zsh is not installed on this server"    
fi

##
echo "For this Stack, you will use $IP IP Address"
#####################################################################################################################