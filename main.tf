terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Création du VPC du projet PetClinic
resource "aws_vpc" "petclinic_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "petclinic-vpc"
  }
}

# 2. Création d'une passerelle Internet (Internet Gateway)
resource "aws_internet_gateway" "petclinic_igw" {
  vpc_id = aws_vpc.petclinic_vpc.id

  tags = {
    Name = "petclinic-igw"
  }
}

# 3. Sous-réseaux Publics (Zone A et Zone B)
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.petclinic_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "petclinic-public-1a"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.petclinic_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "petclinic-public-1b"
  }
}

# 4. Sous-réseaux Privés pour l'Application
resource "aws_subnet" "private_app_az1" {
  vpc_id            = aws_vpc.petclinic_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "petclinic-private-app-1a"
  }
}

resource "aws_subnet" "private_app_az2" {
  vpc_id            = aws_vpc.petclinic_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "petclinic-private-app-1b"
  }
}

# 5. Sous-réseaux Privés pour RDS
resource "aws_subnet" "private_db_az1" {
  vpc_id            = aws_vpc.petclinic_vpc.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "petclinic-private-db-1a"
  }
}

resource "aws_subnet" "private_db_az2" {
  vpc_id            = aws_vpc.petclinic_vpc.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "petclinic-private-db-1b"
  }
}

# 6. Elastic IP pour NAT Gateway
resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.petclinic_igw]

  tags = {
    Name = "petclinic-nat-eip"
  }
}

# 7. NAT Gateway
resource "aws_nat_gateway" "petclinic_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "petclinic-nat-gateway"
  }
}

# 8. Table de routage PUBLIQUE
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.petclinic_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.petclinic_igw.id
  }

  tags = {
    Name = "petclinic-public-rt"
  }
}

resource "aws_route_table_association" "public_az1_assoc" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_az2_assoc" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# 9. Table de routage PRIVÉE
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.petclinic_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.petclinic_nat.id
  }

  tags = {
    Name = "petclinic-private-rt"
  }
}

resource "aws_route_table_association" "private_app_az1_assoc" {
  subnet_id      = aws_subnet.private_app_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_app_az2_assoc" {
  subnet_id      = aws_subnet.private_app_az2.id
  route_table_id = aws_route_table.private_rt.id
}

# 10. Security Group pour l'ALB
resource "aws_security_group" "alb_sg" {
  name        = "petclinic-alb-sg"
  description = "Accessibilite web publique pour l ALB"
  vpc_id      = aws_vpc.petclinic_vpc.id

  ingress {
    description = "Trafic HTTP PetClinic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "petclinic-alb-sg"
  }
}

# 11. Security Group pour l'Application EC2 (AVEC ACCÈS SSH)
resource "aws_security_group" "app_sg" {
  name        = "petclinic-app-sg"
  description = "Autorise le trafic HTTP et SSH vers l instance"
  vpc_id      = aws_vpc.petclinic_vpc.id

  ingress {
    description = "HTTP de partout"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- AJOUT PORT 22 POUR ACCÈS SSH ---
  ingress {
    description = "SSH de partout"
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

  tags = {
    Name = "petclinic-app-sg"
  }
}

# 12. Security Group pour RDS MySQL
resource "aws_security_group" "db_sg" {
  name        = "petclinic-db-sg"
  description = "Autorise le trafic venant uniquement de l application"
  vpc_id      = aws_vpc.petclinic_vpc.id

  ingress {
    description     = "MySQL depuis l application uniquement"
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

  tags = {
    Name = "petclinic-db-sg"
  }
}

# 13. Groupe de sous-réseaux pour RDS
resource "aws_db_subnet_group" "petclinic_db_subnet_group" {
  name       = "petclinic-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_az1.id, aws_subnet.private_db_az2.id]

  tags = {
    Name = "petclinic-db-subnet-group"
  }
}

# 14. Instance RDS MySQL
resource "aws_db_instance" "petclinic_db" {
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "petclinic"
  username               = "petclinicadmin"
  password               = "PetClinicSecurePassword2026"
  db_subnet_group_name   = aws_db_subnet_group.petclinic_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "petclinic-rds-mysql"
  }
}

# 15. Target Group pour l'ALB
resource "aws_lb_target_group" "petclinic_tg" {
  name        = "petclinic-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.petclinic_vpc.id
  target_type = "instance"

  health_check {
    path                = "/"
    port                = "8080"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# 16. Application Load Balancer (ALB)
resource "aws_lb" "petclinic_alb" {
  name               = "petclinic-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]

  tags = {
    Name = "petclinic-alb"
  }
}

# 17. Écouteur (Listener) ALB
resource "aws_lb_listener" "petclinic_http_listener" {
  load_balancer_arn = aws_lb.petclinic_alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.petclinic_tg.arn
  }
}

# 18. Image Amazon Linux 2
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}

# 19. Instance EC2 Application
resource "aws_instance" "petclinic_app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  key_name                    = "vockey" # <-- ACCÈS CLÉ SSH AWS ACADEMY
  subnet_id                   = aws_subnet.public_az1.id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true

  # USER_DATA CORRIGÉ POUR L'INSTALLATION DE JAVA 17
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              rpm --import https://yum.corretto.aws/corretto.key
              curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
              yum install -y java-17-amazon-corretto-devel git

              cd /home/ec2-user
              git clone https://github.com/spring-projects/spring-petclinic.git
              cd spring-petclinic
              
              ./mvnw package -DskipTests
              
              java -Xmx512m -jar target/spring-petclinic-*.jar \
                --spring.profiles.active=mysql \
                --spring.datasource.url=jdbc:mysql://${aws_db_instance.petclinic_db.endpoint}/petclinic \
                --spring.datasource.username=${aws_db_instance.petclinic_db.username} \
                --spring.datasource.password=PetClinicSecurePassword2026 > petclinic.log 2>&1 &
              EOF

  tags = {
    Name = "petclinic-app-server"
  }
}

# 20. Attachement Target Group
resource "aws_lb_target_group_attachment" "petclinic_app_attachment" {
  target_group_arn = aws_lb_target_group.petclinic_tg.arn
  target_id        = aws_instance.petclinic_app.id
  port             = 8080
}

# 21. Output URL
output "petclinic_url" {
  description = "URL publique pour acceder a l application Spring PetClinic"
  value       = "http://${aws_lb.petclinic_alb.dns_name}:8080"
}