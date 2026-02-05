# 1. Ορισμός του Παρόχου AWS
provider "aws" {
  region = var.aws_region
}

# 2. Ομάδα Ασφάλειας
resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH and Minikube"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Εικονική Μηχανή με Διορθωμένο User Data
resource "aws_instance" "minikube_server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  user_data = <<EOF
#!/bin/bash
# Προσθήκη Swap για να αντέξει η μηχανή το Minikube
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Διορθωμένη εγκατάσταση Docker
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu

# Διορθωμένη εγκατάσταση Minikube
curl -LO https://storage.googleapis.com
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Διορθωμένη εγκατάσταση Kubectl
curl -LO "https://dl.k8s.io(curl -L -s https://dl.k8s.io)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

touch /tmp/docker_minikube_installed
EOF
}

# 4. Απομακρυσμένη Ρύθμιση
resource "null_resource" "remote_setup" {
  depends_on = [aws_instance.minikube_server]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/cloud.test.pem")
    host        = aws_instance.minikube_server.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/docker_minikube_installed ]; do echo 'Waiting for tools...'; sleep 10; done",
      "sudo usermod -aG docker ubuntu",
      "minikube start -p test --driver=docker",
      "until minikube kubectl -p test -- get nodes | grep -w 'Ready'; do echo 'Waiting for cluster...'; sleep 10; done",
      
      # Διορθωμένο Git Clone (πλήρες URL και σωστός φάκελος)
      "git clone https://github.com /home/ubuntu/app",
      "cd /home/ubuntu/app",
      
      # Εφαρμογή των YAML (το path εξαρτάται από τη δομή του repo σου)
      "minikube kubectl -p test -- apply -f /home/ubuntu/app/yaml/",
      "touch /tmp/app_depl_complete"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "if [ -f /tmp/app_depl_complete ]; then echo 'Deployment finished successfully!'; else echo 'Deployment failed!'; exit 1; fi"
    ]
  }
}
