output "vpn_connection_id" {
  description = "ID of the IPsec VPN connection"
  value       = aws_vpn_connection.this.id
}

output "vpn_gateway_id" {
  description = "ID of the VPN gateway attached to the VPC"
  value       = aws_vpn_gateway.this.id
}

output "customer_gateway_id" {
  description = "ID of the customer gateway (the on-prem side object)"
  value       = aws_customer_gateway.this.id
}

output "tunnel1_address" {
  description = "Public IP of the first VPN tunnel endpoint (configure it on the on-prem device)"
  value       = aws_vpn_connection.this.tunnel1_address
}

output "tunnel2_address" {
  description = "Public IP of the second (redundant) VPN tunnel endpoint"
  value       = aws_vpn_connection.this.tunnel2_address
}
