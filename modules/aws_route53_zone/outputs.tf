output "zone_id" {
  description = "Hosted zone ID (pass as zone_id to record or alias resources)"
  value       = aws_route53_zone.this.id
}

output "zone_name" {
  description = "Domain name of the hosted zone"
  value       = aws_route53_zone.this.name
}

output "name_servers" {
  description = "Authoritative name servers of the hosted zone (public zones: set these NS records at your registrar; private zones: only relevant inside the VPC)"
  value       = aws_route53_zone.this.name_servers
}
