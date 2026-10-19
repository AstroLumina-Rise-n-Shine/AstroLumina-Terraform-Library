output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name to point traffic at (ALBs have no fixed IP)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted-zone ID of the ALB, needed for alias DNS records"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group (register targets here or hand it to an ECS service)"
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN of the forward listener"
  value       = aws_lb_listener.this.arn
}
