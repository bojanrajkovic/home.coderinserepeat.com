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
    "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4/Q/0tH836jK51686T0bcibjbViNSGCbr+BEhA3xwp3gslWswACFqslTtfwQOlL48inI85C8\" \"vE17SqkJBfJ2A9rFO0FrHHK5CK3ebdhuv+Hu7laq4I+5nRm/Awv9ExrqvOztsOmL+kP5SWXKtc+cx4u2PiSjNAAHfTuu+BMpi7iSixhtLKqnK+6RTndlCIIsX0cvnxJmSzbtJX\" \"XiwyyDc8WGyNOl7W6d8qEop9bb7TfuhVSU297xOOhCj8lc4s/spiQZ21eWxWq+JZHXpm8RkMAA4tRuMFkrDR/3o+wZnV37+nzDEcci14Tc9L9QdXD7nRA0I2JFKCxpTdAWgRpKjwIDAQAB"
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