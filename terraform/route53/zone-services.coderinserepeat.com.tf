resource "aws_route53_record" "services_coderinserepeat_com_CAA" {
  type       = "CAA"
  name       = "services.coderinserepeat.com"
  zone_id    = aws_route53_zone.services_coderinserepeat_com.zone_id
  depends_on = [aws_route53_zone.services_coderinserepeat_com]
  ttl        = 300

  records = var.caa_records
}

resource "aws_route53_record" "services_coderinserepeat_com_CNAME_homeassistant" {
  type       = "CNAME"
  name       = "homeassistant.services.coderinserepeat.com"
  zone_id    = aws_route53_zone.services_coderinserepeat_com.zone_id
  depends_on = [aws_route53_zone.services_coderinserepeat_com]
  ttl        = 60
  records    = ["6gd9epj6904y66yr9r74n2dowgs6n255.ui.nabu.casa"]
}

resource "aws_route53_record" "services_coderinserepeat_com_CNAME_homeassistant_ACME" {
  type       = "CNAME"
  name       = "_acme-challenge.homeassistant.services.coderinserepeat.com"
  zone_id    = aws_route53_zone.services_coderinserepeat_com.zone_id
  depends_on = [aws_route53_zone.services_coderinserepeat_com]
  ttl        = 60
  records    = ["_acme-challenge.6gd9epj6904y66yr9r74n2dowgs6n255.ui.nabu.casa"]
}
