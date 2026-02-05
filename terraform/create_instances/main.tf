# --- 1. PROVIDER & DATA SOURCES ---
provider "aws" {
  region = var.region
}

# Εύρεση του AMI για την εφαρμογή
data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["citizen-app-ami-final-2025"] 
  }
}

# Εύρεση του AMI για τη βάση
data "aws_ami" "db_ami" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["citizen-db-ami-final-2025"]
  }
}

# --- 2. SECURITY GROUPS ---

# SG για τον Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "citizen-lb-sg-2025"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

# SG για την Εφαρμογή
resource "aws_security_group" "app_sg" {
  name   = "citizen-app-sg-2025"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 8089
    to_port         = 8089
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

# SG για τη Βάση Δεδομένων
resource "aws_security_group" "db_sg" {
  name   = "citizen-db-sg-2025"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 3. EC2 INSTANCES ---

# Instance για τη Βάση Δεδομένων
resource "aws_instance" "db" {
  ami                    = data.aws_ami.db_ami.id
  instance_type          = var.instance_type_db
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  tags                   = { Name = "Citizen-DB-Prod-2025" }
}

# Instances για την Εφαρμογή (3 Instances)
resource "aws_instance" "app" {
  count                  = 3
  ami                    = data.aws_ami.app_ami.id
  instance_type          = var.instance_type_app
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = var.subnets[count.index % length(var.subnets)]
  
  depends_on             = [aws_instance.db]

  user_data = <<-EOF
              #!/bin/bash
              # 1. Καταγραφή logs για έλεγχο σφαλμάτων
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              
              # 2. Εγκατάσταση απαραίτητων πακέτων
              apt-get update
              apt-get install -y openjdk-17-jdk maven git netcat-openbsd

              # 3. Αναμονή μέχρι η βάση να απαντήσει στη θύρα 3306
              echo "Waiting for DB at ${aws_instance.db.private_ip}..."
              while ! nc -z ${aws_instance.db.private_ip} 3306; do
                echo "DB is not ready yet... sleeping 10s"
                sleep 10
              done
              echo "Database is UP!"

              # 4. Λήψη και Build του κώδικα
              cd /home/ubuntu
              git clone https://github.com/konstantinos85-hub/citizen-project.git
              cd citizen-project/citizen-service
              
              mvn clean package -DskipTests

              # 5. Εκτέλεση της εφαρμογής
              # Χρησιμοποιούμε System Properties (-D) που υπερισχύουν του application.properties
              nohup java -Dspring.datasource.url=jdbc:mysql://${aws_instance.db.private_ip}:3306/${var.db_name}?createDatabaseIfNotExist=true \
                -Dspring.datasource.username=${var.db_user} \
                -Dspring.datasource.password=${var.db_password} \
                -Dspring.jpa.hibernate.ddl-auto=update \
                -Dspring.jpa.database-platform=org.hibernate.dialect.MySQLDialect \
                -jar target/${var.jar_name}.jar \
                --server.port=8089 \
                --spring.profiles.active=prod > /var/log/spring-boot-app.log 2>&1 &
              
              echo "Application started in background."
              EOF


  tags = { Name = "Citizen-App-Instance-${count.index + 1}" }
}

# --- 4. LOAD BALANCER ---

resource "aws_lb" "app_lb" {
  name               = "citizen-lb-2025"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.subnets
}

resource "aws_lb_target_group" "app_tg" {
  name     = "citizen-tg-2025"
  port     = 8089
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/api/citizens/test"
    interval            = 60
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 10 
  }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  count            = 3
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app[count.index].id
  port             = 8089
}
