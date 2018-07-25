output "public_ip" {
  value = "${aws_instance.bam.public_ip}"
}

output "public_dns" {
  value = "${aws_instance.bam.public_dns}"
}
