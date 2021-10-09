/*
output "public_ip" {
  value       = aws_instance.terraform-example.public_ip
  description = "The public IP address of the web server"
}

output "source_instance_id" {
  value       = aws_instance.terraform-example.id
  description = "The instance_id of the web server"
}
*/
output "alb_dns_name" {

  value       = aws_lb.aws_example.dns_name
  description = "The domain name of the load balancer"
}

output "image_id_instances" {
  value       = aws_launch_configuration.terraform-example-launch.image_id
  description = "Images ids for EC2 instances"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform-locks-1.name
  description = "The name of the DynamoDB table"
}

output "asg_name" {
  value       = aws_autoscaling_group.autoscale-example.name
  description = "The name of the Auto Scaling Group"
}
output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the Security Group attached to the load balancer"
}
