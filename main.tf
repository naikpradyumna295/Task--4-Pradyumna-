provider "aws" {
  region = "us-east-1"
}

resource "null_resource" "check_key_pair" {
  provisioner "local-exec" {
    command = "./check_key_pair.sh Task4NewUnique2 ~/.ssh/id_rsa.pub"
  }
}

resource "aws_instance" "strapi_instance" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  key_name      = "Task4NewUnique2"

  security_groups = [aws_security_group.strapi_sg.name]

  provisioner "file" {
    content     = var.ssh_private_key
    destination = "/home/ubuntu/Task4NewUnique2.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ubuntu/Task4NewUnique2.pem",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io docker-compose",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo ufw allow 'Nginx Full'",
      "cd /home/ubuntu/strapi-app",
      "sudo docker-compose up -d",
      "sudo apt-get install -y certbot python3-certbot-nginx",
      "sudo certbot --nginx -d Pradyumna.contentecho.in --non-interactive --agree-tos --email your-email@example.com"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ssh_private_key
      host        = self.public_ip
    }
  }

  tags = {
    Name = "StrapiInstance"
  }
}

resource "aws_route53_record" "strapi" {
  zone_id = "Z06607023RJWXGXD2ZL6M"
  name    = "Pradyumna.contentecho.in"
  type    = "A"
  ttl     = "300"

  records = [aws_instance.strapi_instance.public_ip]
}

resource "aws_security_group" "strapi_sg" {
  name_prefix = "strapi-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

output "instance_public_ip" {
  value = aws_instance.strapi_instance.public_ip
}

variable "ssh_public_key" {
  description = "The public SSH key"
  type        = string
}

variable "ssh_private_key" {
  description = "The private SSH key"
  type        = string
  sensitive   = true
}
