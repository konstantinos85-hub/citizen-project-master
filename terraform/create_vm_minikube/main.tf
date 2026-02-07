provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "minikube" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOT
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              sudo systemctl restart docker
              sleep 5
              curl -Lo minikube https://storage.googleapis.com
              chmod +x minikube
              sudo install minikube /usr/local/bin/
              touch /tmp/docker_minikube_installed	
              EOT

  vpc_security_group_ids = [aws_security_group.minikube_sg.id]

  tags = {
    Name = "Citizen-Minikube-EC2"
  }
}

resource "null_resource" "wait_for_minikube_instance" {
  depends_on = [aws_instance.minikube]
    
  provisioner "remote-exec" {
        inline = [
      "while [ ! -f /tmp/docker_minikube_installed ]; do sleep 10; done",
      "sudo usermod -aG docker ubuntu",
      "sudo systemctl restart docker",
      "sleep 5",
      "sudo -u ubuntu minikube start -p test --driver=docker",
      "while ! sudo -u ubuntu minikube kubectl -p test -- get nodes > /dev/null 2>&1; do sleep 10; done",
      
      "git clone https://github.com/konstantinos85-hub/citizen-project-master.git",
      "cd citizen-project-master",

      "eval $(minikube -p test docker-env)",
      "docker build -t citizen-rest-app:latest .",

      "sudo -u ubuntu minikube kubectl -p test -- apply -f Kubernetes/minikube/",
      "sudo -u ubuntu nohup minikube kubectl -p test -- port-forward --address 0.0.0.0 service/citizen-service-lb 8089:8089 > /dev/null 2>&1 &",
      
      "touch /tmp/app_depl_complete"
    ]

    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
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
      private_key = file(var.private_key_path)
      host        = aws_instance.minikube.public_ip
    }
  }
}

resource "aws_security_group" "minikube_sg" {
  name        = "minikube-sg-citizen-v2"
  description = "Allow SSH, Minikube and App Port"

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
