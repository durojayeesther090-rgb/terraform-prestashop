output "public_ip" {
  value = aws_instance.prestashop.public_ip
}

output "prestashop_url" {
  value = "http://${aws_instance.prestashop.public_ip}"
}
