output "public_ip" {
  value = "${aws_instance.bam.public_ip}"
}