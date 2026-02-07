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
              sudo apt-get install -y docker.io
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              
              curl -Lo minikube https://storage.googleapis.com
              chmod +x minikube
              sudo install minikube /usr/local/bin/
              touch /tmp/docker_minikube_installed	
              EOT

  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  tags = {
    Name = "Minikube-Citizen-Project"
  }
}

resource "terraform_data" "setup_minikube" {
  depends_on = [aws_instance.minikube]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_instance.minikube.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/docker_minikube_installed ]; do sleep 10; done",
      "sudo usermod -aG docker ubuntu",
      "sudo -u ubuntu nohup minikube start -p test --driver=docker &",
      
      "echo 'Waiting for Kubernetes API...'",
      "while ! sudo -u ubuntu minikube kubectl -p test -- get nodes > /dev/null 2>&1; do sleep 10; done",
      
      "git clone ${var.github_repo}",
      "cd citizen-project-master",
      
      "sudo -u ubuntu minikube kubectl -p test -- apply -f yaml/",
      "sleep 15", 
      
      "sudo -u ubuntu nohup minikube kubectl -p test -- port-forward --address 0.0.0.0 service/citizen-service-lb 8089:8089 > /dev/null 2>&1 &",
      
      "echo 'Deployment and Port-Forwarding complete!'"
    ]
  }
} # <-- ΑΥΤΟ ΤΟ ΑΓΚΙΣΤΡΟ ΠΙΘΑΝΩΣ ΕΛΕΙΠΕ

resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg"
  description = "SSH, Minikube and App Port"

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
