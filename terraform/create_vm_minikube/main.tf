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
              # Το restart του docker εδώ βοηθάει, αλλά το remote-exec χρειάζεται ειδική μεταχείριση
              sudo systemctl restart docker
              
              # ΣΩΣΤΟ URL ΓΙΑ LINUX
              curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              chmod +x minikube
              sudo install minikube /usr/local/bin/
              
              # Εγκατάσταση kubectl (απαραίτητο για το dashboard proxy)
              curl -LO "https://dl.k8s.io(curl -L -s https://dl.k8s.io)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              sudo install kubectl /usr/local/bin/

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
      
      # Χρήση sg (switch group) για να αναγνωριστούν τα δικαιώματα docker χωρίς relogin
      "sudo -u ubuntu minikube start -p test --driver=docker",
      
      "while ! sudo -u ubuntu minikube kubectl -p test -- get nodes > /dev/null 2>&1; do sleep 10; done",
      
      "git clone https://github.com/konstantinos85-hub/citizen-project-master.git",
      "cd citizen-project-master",

      # Build το image μέσα στο περιβάλλον του minikube
      "eval $(sudo -u ubuntu minikube -p test docker-env)",
      "sudo docker build -t citizen-rest-app:latest .",

      "sudo -u ubuntu minikube kubectl -p test -- apply -f Kubernetes/minikube/",
      
      # Port Forward για την εφαρμογή
      "sudo -u ubuntu nohup minikube kubectl -p test -- port-forward --address 0.0.0.0 service/citizen-service-lb 8089:8089 > /dev/null 2>&1 &",
      
      # ΕΝΕΡΓΟΠΟΙΗΣΗ DASHBOARD
      "sudo -u ubuntu minikube -p test addons enable dashboard",
      "sudo -u ubuntu nohup kubectl proxy --address='0.0.0.0' --disable-filter=true > /dev/null 2>&1 &",
      
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
      "echo 'App & Dashboard deployment completed'"
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
  name        = "minikube-sg-citizen-v4"
  description = "Allow SSH, Minikube, App Port and Dashboard"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App Port
  ingress {
    from_port   = 8089
    to_port     = 8089
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Dashboard Proxy Port
  ingress {
    from_port   = 8001
    to_port     = 8001
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
