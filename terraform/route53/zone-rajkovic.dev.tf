data "aws_cloudfront_distribution" "rajkovic_dev" {
  id = var.rajkovic_dev_cloudfront_distribution_id
}

resource "aws_route53_record" "rajkovic_dev_CAA" {
  type    = "CAA"
  name    = "rajkovic.dev"
  zone_id = aws_route53_zone.zone["rajkovic.dev"].zone_id
  ttl     = 300

  records = var.caa_records
}

resource "aws_route53_record" "rajkovic_dev_MX" {
  type    = "MX"
  name    = "rajkovic.dev"
  zone_id = aws_route53_zone.zone["rajkovic.dev"].zone_id
  ttl     = 300

  records = var.mx_records
}

resource "aws_route53_record" "rajkovic_dev_TXT" {
  type    = "TXT"
  name    = "rajkovic.dev"
  zone_id = aws_route53_zone.zone["rajkovic.dev"].zone_id
  ttl     = 300

  records = [
    "keybase-site-verification=NQZCEJ4D1nfWzeGn5K6aaoaFldRefMm0spWYEyW8N4c",
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "rajkovic_dev_google_dkim_record" {
  type    = "TXT"
  name    = "google._domainkey.rajkovic.dev"
  zone_id = aws_route53_zone.zone["rajkovic.dev"].zone_id
  ttl     = 300

  records = [
    var.dkim_keys["rajkovic.dev"]
  ]
}

resource "aws_route53_record" "bojan_rajkovic_dev_A" {
  type    = "A"
  name    = "bojan.rajkovic.dev"
  zone_id = aws_route53_zone.zone["rajkovic.dev"].zone_id

  alias {
    name                   = data.aws_cloudfront_distribution.rajkovic_dev.domain_name
    zone_id                = data.aws_cloudfront_distribution.rajkovic_dev.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "bojan_rajkovic_dev_acm_validation_record" {
  type    = "CNAME"
  name    = "_ef3c73b526d0dac2ac781c8364c7448f.bojan.rajkovic.dev"
  zone_id = aws_route53_zone.zone["rajkovic.dev"].zone_id
  ttl     = 300

  records = [
    "_319f1527ac7f5eea9b9ef04922927235.hkvuiqjoua.acm-validations.aws."
  ]
}

import {
  to = aws_route53_record.rajkovic_dev_CAA
  id = "${aws_route53_zone.zone["rajkovic.dev"].zone_id}_rajkovic.dev_CAA"
}

import {
  to = aws_route53_record.rajkovic_dev_MX
  id = "${aws_route53_zone.zone["rajkovic.dev"].zone_id}_rajkovic.dev_MX"
}

import {
  to = aws_route53_record.rajkovic_dev_TXT
  id = "${aws_route53_zone.zone["rajkovic.dev"].zone_id}_rajkovic.dev_TXT"
}

import {
  to = aws_route53_record.rajkovic_dev_google_dkim_record
  id = "${aws_route53_zone.zone["rajkovic.dev"].zone_id}_google._domainkey.rajkovic.dev_TXT"
}

import {
  to = aws_route53_record.bojan_rajkovic_dev_A
  id = "${aws_route53_zone.zone["rajkovic.dev"].zone_id}_bojan.rajkovic.dev_A"
}

import {
  to = aws_route53_record.bojan_rajkovic_dev_acm_validation_record
  id = "${aws_route53_zone.zone["rajkovic.dev"].zone_id}__ef3c73b526d0dac2ac781c8364c7448f.bojan.rajkovic.dev_CNAME"
}
