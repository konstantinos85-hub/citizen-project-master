provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "minikube" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = <<-EOT
              #!/bin/bash
              sudo apt-get update -y
              # Εγκατάσταση Docker
              sudo apt-get install -y docker.io
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              
              # Εγκατάσταση Minikube
              curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              chmod +x minikube
              sudo install minikube /usr/local/bin/
                  
              touch /tmp/docker_minikube_installed	
              EOT

  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  tags = {
    Name = "Minikube-EC2"
  }
}

resource "null_resource" "wait_for_minikube_instance" {
  depends_on = [aws_instance.minikube]
    
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/docker_minikube_installed ]; do sleep 10; done",
      "sudo usermod -aG docker ubuntu",
      # Εκκίνηση minikube
      "sudo -u ubuntu nohup minikube start -p test --driver=docker &",
      "echo 'Starting minikube'",        
              
      "while ! sudo -u ubuntu minikube kubectl -p test -- get nodes > /dev/null 2>&1; do",
      "echo 'Waiting for Kubernetes API to be ready...'",
      "sleep 10",
      "done",
      "echo 'Minikube is ready!'",
      
      # Εδώ βάζουμε το ΔΙΚΟ ΣΟΥ repo
      "git clone https://github.com/konstantinos85-hub/citizen-project-master.git",
	  "cd citizen-project-master",
	  "echo 'Repo cloned!'",
	
      # Εδώ βάζουμε το φάκελο yaml/ που έχεις στο repo σου
      "sudo -u ubuntu minikube kubectl -p test -- apply -f yaml/",
      "touch /tmp/app_depl_complete"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      # ΠΡΟΣΟΧΗ: Εδώ το μονοπάτι για το Mac σου
      private_key = file("${path.module}/cloud.test.pem")
      host        = aws_instance.minikube.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/app_depl_complete ]; do sleep 10; done",
      "echo 'App deployment script completed'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${path.module}/cloud.test.pem")
      host        = aws_instance.minikube.public_ip
    }
  }
}

resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "Allow SSH, Minikube and App Port"

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

  # Προσθήκη της θύρας 8089 για την εφαρμογή σου
  ingress {
    from_port   = 8089
    to_port     = 8089
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
