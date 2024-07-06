data "aws_route53_zone" "services_domain" {
  name = var.ses_domain
}

resource "aws_ses_domain_identity" "services_domain_ses_identity" {
 domain = var.ses_domain
}

resource "aws_route53_record" "services_amazonses_identity_record" {
  zone_id = data.aws_route53_zone.services_domain.zone_id
  name = "_amazonses.${var.ses_domain}"
  type = "TXT"
  records = [aws_ses_domain_identity.services_domain_ses_identity.verification_token]
  ttl = "60"
}

resource "aws_ses_domain_identity_verification" "services_ses_verification" {
  depends_on = [aws_route53_record.services_amazonses_identity_record]
  
  domain = var.ses_domain
}

resource "aws_ses_domain_dkim" "services_domain_ses_dkim" {
  depends_on = [ aws_ses_domain_identity_verification.services_ses_verification ]
  
  domain = var.ses_domain
}

resource "aws_route53_record" "services_amazonses_dkim_record" {
  count   = 3
  zone_id = data.aws_route53_zone.services_domain.zone_id
  name    = "${aws_ses_domain_dkim.services_domain_ses_dkim.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.services_domain_ses_dkim.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "services_amazonses_dmarc_record" {
  zone_id = data.aws_route53_zone.services_domain.zone_id
  name = "_dmarc.${var.ses_domain}"
  type = "TXT"
  ttl = "600"
  records = ["v=DMARC1; p=quarantine;"]
}

resource "aws_iam_user" "sender_users" {
  depends_on = [ aws_ses_domain_identity_verification.services_ses_verification ]
  for_each = var.ses_senders

  name = "SesEmailSender-${each.key}"
}

resource "aws_iam_access_key" "sender_access_keys" {
  for_each = var.ses_senders

  user = aws_iam_user.sender_users[each.key].name
}

data "aws_iam_policy_document" "policy" {
  for_each = var.ses_senders

  statement {
    actions = ["ses:SendEmail", "ses:SendRawEmail"]
    resources = concat(
      [aws_ses_domain_identity.services_domain_ses_identity.arn],
      [for recipient in aws_ses_email_identity.email_recipients : recipient.arn]
    )
  }
}

resource "aws_iam_policy" "policy" {
  for_each = var.ses_senders

  policy = data.aws_iam_policy_document.policy[each.key].json
}

resource "aws_iam_user_policy_attachment" "user_policy" {
  for_each = var.ses_senders

  user       = aws_iam_user.sender_users[each.key].name
  policy_arn = aws_iam_policy.policy[each.key].arn
}

output "sender_emails" {
  value = var.ses_senders
}

output "smtp_username" {
  value = {
    for key, access_key in aws_iam_access_key.sender_access_keys : key => access_key.id
  }
}

output "smtp_password" {
  value = {
    for key, access_key in aws_iam_access_key.sender_access_keys : key => access_key.ses_smtp_password_v4
  }
  sensitive = true
}