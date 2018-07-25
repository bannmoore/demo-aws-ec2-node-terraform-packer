variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

variable "ami" {
  description = "The AMI used by the ec2 instance"
  default     = "ami-2757f631"
}

variable "key_pair_name" {
  description = "The name of the Key Pair that can be used to SSH to each EC2 instance. Leave blank to not include a Key Pair."
  default     = ""
}
