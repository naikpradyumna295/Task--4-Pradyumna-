provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "Task4"
  public_key = file("C:/Users/LENOVO/Desktop/TASK-4/Task4.pub")
}

resource "aws_instance" "strapi_instance" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  security_groups = [aws_security_group.strapi_sg.name]

  provisioner "file" {
    source      = "C:/Users/LENOVO/Desktop/TASK-4/Task4.pem"
    destination = "/home/ubuntu/Task4.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ubuntu/MyNewKeyPair.pem",
      "apt-get update -y",
      "apt-get install -y docker.io docker-compose",
      "systemctl start docker",
      "systemctl enable docker",
      "ufw allow 'Nginx Full'",
      "git clone https://github.com/naikpradyumna295/Task--4-Pradyumna-.git /home/ubuntu/strapi-app",
      "cd /home/ubuntu/strapi-app",
      "docker-compose up -d",
      "apt-get install -y certbot python3-certbot-nginx",
      "certbot --nginx -d Pradyumna.contentecho.in --non-interactive --agree-tos --email naikpradyumna295@example.com"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("C:/Users/LENOVO/Desktop/TASK-4/Task4.pem")
      host        = aws_instance.strapi_instance.public_ip
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
