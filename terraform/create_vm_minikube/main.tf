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
# 1. Δημιουργία Swap (Απαραίτητο για t3.micro)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 2. Εγκατάσταση Docker
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu

# 3. Εγκατάσταση Minikube (ΠΛΗΡΕΣ URL)
curl -LO https://github.com
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# 4. Εγκατάσταση Kubectl (ΠΛΗΡΕΣ URL)
curl -LO "https://dl.k8s.io(curl -L -s https://dl.k8s.io)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 5. Σηματοδότηση ολοκλήρωσης
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
      # 1. Αναμονή για το σήμα από το user_data
      "while [ ! -f /tmp/docker_minikube_installed ]; do echo 'Waiting for tools...'; sleep 10; done",
      
      # 2. Διασφάλιση δικαιωμάτων εκτέλεσης (για σιγουριά)
      "sudo chmod +x /usr/local/bin/minikube /usr/local/bin/kubectl",
      
      # 3. Εκκίνηση με πλήρη διαδρομή και χρήση του sudo για το group docker
      "sudo usermod -aG docker ubuntu",
      "sg docker -c '/usr/local/bin/minikube start -p test --driver=docker'",
      
      # 4. Αναμονή για το cluster
      "until /usr/local/bin/minikube kubectl -p test -- get nodes | grep -w 'Ready'; do echo 'Waiting for cluster...'; sleep 10; done",
      
      # 5. Git Clone και Deployment
      "rm -rf /home/ubuntu/app", # Καθαρισμός αν υπάρχει ήδη
      "git clone https://github.com /home/ubuntu/app",
      "cd /home/ubuntu/app && /usr/local/bin/minikube kubectl -p test -- apply -f yaml/",
      
      "touch /tmp/app_depl_complete"
    ]

  }

  provisioner "remote-exec" {
    inline = [
      "if [ -f /tmp/app_depl_complete ]; then echo 'Deployment finished successfully!'; else echo 'Deployment failed!'; exit 1; fi"
    ]
  }
}
