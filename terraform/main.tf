provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "bam" {
  ami                    = "${var.ami}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
            #!/bin/bash
            cd /home/ubuntu
            npm start
            EOF

  tags {
    Name = "bam-app"
  }
}

resource "aws_security_group" "instance" {
  name = "bam-app-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

variable "ami" {
  description = "The AMI used by the ec2 instance. This will be output by packer."
  default     = "ami-2757f631"
}

output "public_ip" {
  value = "${aws_instance.bam.public_ip}"
}
