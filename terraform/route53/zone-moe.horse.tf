resource "aws_route53_record" "moe_horse_CAA" {
  type    = "CAA"
  name    = "moe.horse"
  zone_id = aws_route53_zone.zone["moe.horse"].zone_id
  ttl     = 300

  records = var.caa_records
}

resource "aws_route53_record" "moe_horse_MX" {
  type    = "MX"
  name    = "moe.horse"
  zone_id = aws_route53_zone.zone["moe.horse"].zone_id
  ttl     = 300

  records = var.mx_records
}

resource "aws_route53_record" "moe_horse_TXT" {
  type    = "TXT"
  name    = "moe.horse"
  zone_id = aws_route53_zone.zone["moe.horse"].zone_id
  ttl     = 300

  records = [
    "google-site-verification=zVa7R0RIsQaKG1Q55qp9QApkU0SJ4Y9-guNlGvIBW_M",
    "keybase-site-verification=ROF9nSu4-JOS7ioz-ua9Oj2yPL1OBe8PCrAfhgVMvAc",
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "moe_horse_google_dkim_record" {
  type    = "TXT"
  name    = "google._domainkey.moe.horse"
  zone_id = aws_route53_zone.zone["moe.horse"].zone_id
  ttl     = 300

  records = [
    var.dkim_keys["moe.horse"]
  ]
}

resource "aws_route53_record" "moe_horse_atproto_record" {
  type    = "TXT"
  name    = "_atproto.moe.horse"
  zone_id = aws_route53_zone.zone["moe.horse"].zone_id
  ttl     = 300

  records = [
    "did=did:plc:bzixhqxsk6vymo25nvlv5bcn"
  ]
}

import {
  to = aws_route53_record.moe_horse_CAA
  id = "${aws_route53_zone.zone["moe.horse"].zone_id}_moe.horse_CAA"
}

import {
  to = aws_route53_record.moe_horse_MX
  id = "${aws_route53_zone.zone["moe.horse"].zone_id}_moe.horse_MX"
}

import {
  to = aws_route53_record.moe_horse_TXT
  id = "${aws_route53_zone.zone["moe.horse"].zone_id}_moe.horse_TXT"
}

import {
  to = aws_route53_record.moe_horse_atproto_record
  id = "${aws_route53_zone.zone["moe.horse"].zone_id}__atproto.moe.horse_TXT"
}

import {
  to = aws_route53_record.moe_horse_google_dkim_record
  id = "${aws_route53_zone.zone["moe.horse"].zone_id}_google._domainkey.moe.horse_TXT"
}
