resource "aws_ses_email_identity" "email_recipients" {
  for_each = var.ses_recipients

  email = each.value
}