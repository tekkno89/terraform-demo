output "lb_dns" {
  value = "${module.nginx_elb.this_elb_dns_name}"
}
