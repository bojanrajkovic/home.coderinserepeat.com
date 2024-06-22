resource "aws_route53_record" "bojangl_es_CAA" {
  type    = "CAA"
  name    = "bojangl.es"
  zone_id = aws_route53_zone.zone["bojangl.es"].zone_id
  ttl     = 300

  records = var.caa_records
}

resource "aws_route53_record" "bojangl_es_MX" {
  type    = "MX"
  name    = "bojangl.es"
  zone_id = aws_route53_zone.zone["bojangl.es"].zone_id
  ttl     = 300

  records = var.mx_records
}

resource "aws_route53_record" "bojangl_es_TXT" {
  type    = "TXT"
  name    = "bojangl.es"
  zone_id = aws_route53_zone.zone["bojangl.es"].zone_id
  ttl     = 300

  records = [
    "google-site-verification=Evwbjl48JBlBhf9PRIx0lSJff4UKN92dPm_3qudLGvU",
    "keybase-site-verification=44xs1CkLhuCjKM7kM3VpZqonSKRJDkjroiEJtr2pAaQ",
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "bojangl_es_google_dkim_record" {
  type    = "TXT"
  name    = "google._domainkey.bojangl.es"
  zone_id = aws_route53_zone.zone["bojangl.es"].zone_id
  ttl     = 300

  records = [
    var.dkim_keys["bojangl.es"]
  ]
}

import {
  to = aws_route53_record.bojangl_es_CAA
  id = "${aws_route53_zone.zone["bojangl.es"].zone_id}_bojangl.es_CAA"
}

import {
  to = aws_route53_record.bojangl_es_MX
  id = "${aws_route53_zone.zone["bojangl.es"].zone_id}_bojangl.es_MX"
}

import {
  to = aws_route53_record.bojangl_es_TXT
  id = "${aws_route53_zone.zone["bojangl.es"].zone_id}_bojangl.es_TXT"
}

import {
  to = aws_route53_record.bojangl_es_google_dkim_record
  id = "${aws_route53_zone.zone["bojangl.es"].zone_id}_google._domainkey.bojangl.es_TXT"
}
