resource "aws_route53_record" "services_coderinserepeat_com_CAA" {
  type       = "CAA"
  name       = "services.coderinserepeat.com"
  zone_id    = aws_route53_zone.services_coderinserepeat_com.zone_id
  depends_on = [aws_route53_zone.services_coderinserepeat_com]
  ttl        = 300

  records = var.caa_records
}