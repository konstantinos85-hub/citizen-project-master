provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "minikube" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Όλη η εγκατάσταση γίνεται στο boot της μηχανής (Cloud-Init)
  user_data = <<-EOT
              #!/bin/bash
              # 1. Εγκατάσταση Docker & Git
              apt-get update -y
              apt-get install -y docker.io git
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu

              # 2. Εγκατάσταση Minikube Binary
              curl -Lo minikube https://storage.googleapis.com
              chmod +x minikube
              install minikube /usr/local/bin/

              # 3. Εκκίνηση Minikube (ως χρήστης ubuntu)
              sudo -u ubuntu minikube start --driver=docker -p test

              # 4. Clone Repo και Deployment εφαρμογής
              cd /home/ubuntu
              sudo -u ubuntu git clone ${var.github_repo}
              cd citizen-project-master
              
              # Αναμονή μέχρι να σηκωθεί το Kubernetes API
              while ! sudo -u ubuntu minikube kubectl -p test -- get nodes; do sleep 10; done
              
              # Apply τα YAML αρχεία σου
              sudo -u ubuntu minikube kubectl -p test -- apply -f yaml/
              
              # 5. Port Forwarding για πρόσβαση από το Internet (Θύρα 8089)
              sudo -u ubuntu nohup minikube kubectl -p test -- port-forward --address 0.0.0.0 service/citizen-service-lb 8089:8089 > /dev/null 2>&1 &
              
              # Δημιουργία σήματος ολοκλήρωσης
              touch /tmp/setup_complete
              EOT

  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  tags = {
    Name = "Minikube-Final-Server"
  }
}

# Αυτό το resource απλά ελέγχει πότε τελείωσε το User Data
resource "terraform_data" "wait_for_setup" {
  depends_on = [aws_instance.minikube]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_instance.minikube.public_ip
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Σύνδεση επιτυχής! Περιμένω την ολοκλήρωση της εγκατάστασης (Minikube & App)...'",
      "while [ ! -f /tmp/setup_complete ]; do sleep 20; done",
      "echo 'Η εφαρμογή είναι έτοιμη και live!'"
    ]
  }
}

resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg-final-v5"
  description = "Allow SSH and Port 8089"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8089
    to_port     = 8089
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
