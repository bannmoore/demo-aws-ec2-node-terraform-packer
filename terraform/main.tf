provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "bam" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    "${aws_security_group.instance.id}"
  ]

  user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p 8080 &
            EOF

  tags {
    Name = "bam-app"
  }
}

resource "aws_security_group" "instance" {
  name = "bam-app-instance"

  # app requests
  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
