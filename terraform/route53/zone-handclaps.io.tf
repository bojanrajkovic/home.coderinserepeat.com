data "aws_cloudfront_distribution" "handclaps_io" {
  id = var.handclaps_io_cloudfront_distribution_id
}

resource "aws_route53_record" "handclaps_io_A" {
  type    = "A"
  name    = "handclaps.io"
  zone_id = aws_route53_zone.zone["handclaps.io"].zone_id

  alias {
    name                   = data.aws_cloudfront_distribution.handclaps_io.domain_name
    zone_id                = data.aws_cloudfront_distribution.handclaps_io.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_handclaps_io_A" {
  type    = "A"
  name    = "www.handclaps.io"
  zone_id = aws_route53_zone.zone["handclaps.io"].zone_id

  alias {
    name                   = aws_route53_record.handclaps_io_A.name
    zone_id                = aws_route53_record.handclaps_io_A.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "handclaps_io_acm_validation_record" {
  type    = "CNAME"
  name    = "_ad2a78d4b65ce5e123707343a7a47ffd.handclaps.io"
  zone_id = aws_route53_zone.zone["handclaps.io"].zone_id
  ttl     = 300

  records = [
    "_2485bede3edd9e95f0196ae06d4bb400.xjncphngnr.acm-validations.aws."
  ]
}

resource "aws_route53_record" "handclaps_io_CAA" {
  type    = "CAA"
  name    = "handclaps.io"
  zone_id = aws_route53_zone.zone["handclaps.io"].zone_id
  ttl     = 300

  records = var.caa_records
}

resource "aws_route53_record" "handclaps_io_MX" {
  type    = "MX"
  name    = "handclaps.io"
  zone_id = aws_route53_zone.zone["handclaps.io"].zone_id
  ttl     = 300

  records = var.mx_records
}

resource "aws_route53_record" "handclaps_io_TXT" {
  type    = "TXT"
  name    = "handclaps.io"
  zone_id = aws_route53_zone.zone["handclaps.io"].zone_id
  ttl     = 300

  records = [
    "google-site-verification=q3lgH-BUlkTFn6WkOrTZL2OLsIiHpXj8pynSJx41Ml8",
    "keybase-site-verification=5m-HTZ6EckqEX6xIayfwR9F2oMPgbdCN_C6MM6H7ajw",
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "handclaps_io_google_dkim_record" {
  type    = "TXT"
  name    = "google._domainkey.handclaps.io"
  zone_id = aws_route53_zone.zone["handclaps.io"].zone_id
  ttl     = 300

  records = [
    var.dkim_keys["handclaps.io"]
  ]
}

import {
  to = aws_route53_record.handclaps_io_A
  id = "${aws_route53_zone.zone["handclaps.io"].zone_id}_handclaps.io_A"
}

import {
  to = aws_route53_record.www_handclaps_io_A
  id = "${aws_route53_zone.zone["handclaps.io"].zone_id}_www.handclaps.io_A"
}

import {
  to = aws_route53_record.handclaps_io_CAA
  id = "${aws_route53_zone.zone["handclaps.io"].zone_id}_handclaps.io_CAA"
}

import {
  to = aws_route53_record.handclaps_io_MX
  id = "${aws_route53_zone.zone["handclaps.io"].zone_id}_handclaps.io_MX"
}

import {
  to = aws_route53_record.handclaps_io_TXT
  id = "${aws_route53_zone.zone["handclaps.io"].zone_id}_handclaps.io_TXT"
}

import {
  to = aws_route53_record.handclaps_io_google_dkim_record
  id = "${aws_route53_zone.zone["handclaps.io"].zone_id}_google._domainkey.handclaps.io_TXT"
}

import {
  to = aws_route53_record.handclaps_io_acm_validation_record
  id = "${aws_route53_zone.zone["handclaps.io"].zone_id}__ad2a78d4b65ce5e123707343a7a47ffd.handclaps.io_CNAME"
}
