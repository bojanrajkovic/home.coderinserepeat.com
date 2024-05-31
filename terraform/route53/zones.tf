resource "aws_route53_zone" "zone" {
  for_each = var.domains
  name     = each.value
}

resource "aws_route53_zone" "services_coderinserepeat_com" {
  name = "services.coderinserepeat.com"
}

import {
  for_each = var.domain_zone_mappings
  to       = aws_route53_zone.zone[each.key]
  id       = each.value
}
