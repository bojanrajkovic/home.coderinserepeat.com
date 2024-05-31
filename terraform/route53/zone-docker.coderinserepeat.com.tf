resource "aws_route53_record" "docker_coderinserepeat_com_CAA" {
  type    = "CAA"
  name    = "docker.coderinserepeat.com"
  zone_id = aws_route53_zone.zone["docker.coderinserepeat.com"].zone_id
  ttl     = 300

  records = var.caa_records
}

import {
  to = aws_route53_record.docker_coderinserepeat_com_CAA
  id = "${aws_route53_zone.zone["docker.coderinserepeat.com"].zone_id}_docker.coderinserepeat.com_CAA"
}