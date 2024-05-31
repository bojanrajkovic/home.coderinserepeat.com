data "aws_route53_zone" "services_domain" {
  name = var.services_domain
}

resource "aws_iam_user" "cert_manager_iam_user" {
  name = "cert_manager"
}

resource "aws_iam_access_key" "cert_manager_access_keys" {
  depends_on = [aws_iam_user.cert_manager_iam_user]
  user       = aws_iam_user.cert_manager_iam_user.id
}

resource "aws_iam_user_policy_attachment" "cert_manager_iam_user_policy_attachment" {
  depends_on = [aws_iam_policy.cert_manager_r53_policy, aws_iam_user.cert_manager_iam_user]
  user       = aws_iam_user.cert_manager_iam_user.id
  policy_arn = aws_iam_policy.cert_manager_r53_policy.arn
}

resource "aws_iam_policy" "cert_manager_r53_policy" {
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect"   = "Allow",
        "Action"   = "route53:GetChange",
        "Resource" = "arn:aws:route53:::change/*"
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        "Resource" = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.services_domain.zone_id}"
      },
      {
        "Effect"   = "Allow",
        "Action"   = "route53:ListHostedZonesByName",
        "Resource" = "*"
      }
    ]
  })
}
