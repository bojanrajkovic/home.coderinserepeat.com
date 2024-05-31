data "aws_cloudfront_distribution" "coderinserepeat_com" {
  id = var.www_coderinserepeat_com_cloudformation_distribution_id
}

data "aws_s3_bucket" "test_coderinserepeat_com" {
  bucket = "test.coderinserepeat.com"
}

resource "aws_route53_record" "coderinserepeat_com_A" {
  type    = "A"
  name    = "coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id

  alias {
    name                   = data.aws_cloudfront_distribution.coderinserepeat_com.domain_name
    zone_id                = data.aws_cloudfront_distribution.coderinserepeat_com.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_coderinserepeat_com_A" {
  type    = "A"
  name    = "www.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id

  alias {
    name                   = aws_route53_record.coderinserepeat_com_A.name
    zone_id                = aws_route53_record.coderinserepeat_com_A.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "blog_coderinserepeat_com_A" {
  type    = "A"
  name    = "blog.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id

  alias {
    name                   = aws_route53_record.coderinserepeat_com_A.name
    zone_id                = aws_route53_record.coderinserepeat_com_A.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "coderinserepeat_com_CAA" {
  type    = "CAA"
  name    = "coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 300

  records = var.caa_records
}

resource "aws_route53_record" "coderinserepeat_com_MX" {
  type    = "MX"
  name    = "coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 300

  records = var.mx_records
}

resource "aws_route53_record" "coderinserepeat_com_TXT" {
  type    = "TXT"
  name    = "coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 300

  records = [
    "keybase-site-verification=xuo__YJ90_1LUshnYCENGV74GwiMX7u3s0SFtRqw6-U",
    "google-site-verification=25e4uXdo6k_RmkzOLTT8HIEFtaogUGzazE7Kj2LRPVA",
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "coderinserepeat_com_acm_validation_record" {
  type    = "CNAME"
  name    = "_9dbcb052b8c15f562742bbe6ee990ecb.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 300

  records = [
    "_f058313618037750f01fcf31c9cfa90d.hkvuiqjoua.acm-validations.aws."
  ]
}

resource "aws_route53_record" "blog_coderinserepeat_com_acm_validation_record" {
  type    = "CNAME"
  name    = "_289d0906e6748c47241c099233048980.blog.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 300

  records = [
    "_940dfe1d2424a0191de00892551b4770.hkvuiqjoua.acm-validations.aws."
  ]
}

resource "aws_route53_record" "www_coderinserepeat_com_acm_validation_record" {
  type    = "CNAME"
  name    = "_58306d7cd49149df32d348c64bdb34da.www.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 300

  records = [
    "_d78eff118d2a51edf04d85c798e74019.hkvuiqjoua.acm-validations.aws."
  ]
}

resource "aws_route53_record" "coderinserepeat_com_google_dkim_record" {
  type    = "TXT"
  name    = "google._domainkey.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 300

  records = [
    var.dkim_keys["coderinserepeat.com"]
  ]
}

resource "aws_route53_record" "docker_coderinserepeat_com_NS" {
  type    = "NS"
  name    = "docker.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl     = 60

  records = [
    "ns-1986.awsdns-56.co.uk.",
    "ns-1478.awsdns-56.org.",
    "ns-598.awsdns-10.net.",
    "ns-463.awsdns-57.com."
  ]
}

resource "aws_route53_record" "services_coderinserepeat_com_NS" {
  type       = "NS"
  name       = "services.coderinserepeat.com"
  zone_id    = aws_route53_zone.zone["coderinserepeat.com"].zone_id
  ttl        = 60
  depends_on = [aws_route53_zone.services_coderinserepeat_com]

  records = aws_route53_zone.services_coderinserepeat_com.name_servers
}

resource "aws_route53_record" "test_coderinserepeat_com_A" {
  type    = "A"
  name    = "test.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["coderinserepeat.com"].zone_id

  alias {
    evaluate_target_health = true
    name                   = data.aws_s3_bucket.test_coderinserepeat_com.website_domain
    zone_id                = data.aws_s3_bucket.test_coderinserepeat_com.hosted_zone_id
  }
}

import {
  to = aws_route53_record.coderinserepeat_com_A
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_coderinserepeat.com_A"
}

import {
  to = aws_route53_record.blog_coderinserepeat_com_A
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_blog.coderinserepeat.com_A"
}

import {
  to = aws_route53_record.www_coderinserepeat_com_A
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_www.coderinserepeat.com_A"
}

import {
  to = aws_route53_record.test_coderinserepeat_com_A
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_test.coderinserepeat.com_A"
}

import {
  to = aws_route53_record.coderinserepeat_com_CAA
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_coderinserepeat.com_CAA"
}

import {
  to = aws_route53_record.coderinserepeat_com_MX
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_coderinserepeat.com_MX"
}

import {
  to = aws_route53_record.coderinserepeat_com_TXT
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_coderinserepeat.com_TXT"
}

import {
  to = aws_route53_record.coderinserepeat_com_acm_validation_record
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}__9dbcb052b8c15f562742bbe6ee990ecb.coderinserepeat.com_CNAME"
}

import {
  to = aws_route53_record.blog_coderinserepeat_com_acm_validation_record
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}__289d0906e6748c47241c099233048980.blog.coderinserepeat.com_CNAME"
}

import {
  to = aws_route53_record.www_coderinserepeat_com_acm_validation_record
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}__58306d7cd49149df32d348c64bdb34da.www.coderinserepeat.com_CNAME"
}

import {
  to = aws_route53_record.coderinserepeat_com_google_dkim_record
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_google._domainkey.coderinserepeat.com_TXT"
}

import {
  to = aws_route53_record.docker_coderinserepeat_com_NS
  id = "${aws_route53_zone.zone["coderinserepeat.com"].zone_id}_docker.coderinserepeat.com_NS"
}
