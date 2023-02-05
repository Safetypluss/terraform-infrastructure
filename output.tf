//load balancer output

output "elb_target_group_arn" {
    value = aws_lb_target_group.damy_tg.arn
}

output "elb_load_balancer_dns_name" {
    value = aws_lb.damy_elb.dns_name
}

output "elastic_load_balancer_zone_id" {
    value = aws_lb.damy_elb.zone_id
}