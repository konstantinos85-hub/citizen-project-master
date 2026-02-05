# 1. Ορισμός του Παρόχου AWS
provider "aws" {
  region = var.aws_region
}

# 2. Ομάδα Ασφάλειας (Security Group)
resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH and Minikube access"

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

# 3. Δημιουργία Εικονικής Μηχανής (EC2 Instance)
resource "aws_instance" "minikube_server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  user_data = <<EOF
#!/bin/bash
# 1. Δημιουργία Swap (Απαραίτητο για μικρά instances)
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 2. Εγκατάσταση Docker
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# 3. Εγκατάσταση Minikube (Πλήρες URL)
curl -Lo minikube https://storage.googleapis.com
sudo install minikube /usr/local/bin/minikube

# 4. Εγκατάσταση Kubectl (Πλήρες URL)
curl -Lo kubectl https://dl.k8s.io
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 5. Σηματοδότηση ολοκλήρωσης για τον Provisioner
touch /tmp/docker_minikube_installed
EOF
}

# 4. Απομακρυσμένη Ρύθμιση και Διάταξη (Provisioning)
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
      # Αναμονή για την εγκατάσταση των εργαλείων
      "while [ ! -f /usr/local/bin/minikube ]; do echo 'Αναμονή για το αρχείο Minikube...'; sleep 20; done",
      "while [ ! -f /tmp/docker_minikube_installed ]; do echo 'Περιμένω την ολοκλήρωση των tools...'; sleep 20; done",
      
      "sleep 10",
      "sudo chmod +x /usr/local/bin/minikube /usr/local/bin/kubectl",

      # Εκκίνηση Minikube ως χρήστης ubuntu
      "sudo -u ubuntu /usr/local/bin/minikube start -p test --driver=docker",
      
      # Αναμονή για την ετοιμότητα του Cluster
      "until /usr/local/bin/minikube kubectl -p test -- get nodes | grep -w 'Ready'; do echo 'Περιμένω το Cluster...'; sleep 20; done",
      
      # Κλωνοποίηση και Deployment
      "rm -rf /home/ubuntu/app",
      "git clone https://github.com/konstantinos85-hub/citizen-project-master.git /home/ubuntu/app",
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
