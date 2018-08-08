variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

variable "ami" {
  description = "The AMI used by the ec2 instance"
  default     = "ami-2d39803a"
}
