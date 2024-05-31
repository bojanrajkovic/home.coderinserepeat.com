data "aws_route53_zone" "root_zone" {
  name = var.root_zone
}

resource "aws_iam_user" "external_dns_iam_user" {
  name = var.external_dns_iam_user_name
}

resource "aws_iam_access_key" "external_dns_access_keys" {
  depends_on = [aws_iam_user.external_dns_iam_user]
  user       = aws_iam_user.external_dns_iam_user.id
}

resource "aws_iam_user_policy_attachment" "external_dns_iam_user_policy_attachment" {
  depends_on = [aws_iam_policy.external_dns_r53_policy, aws_iam_user.external_dns_iam_user]
  user       = aws_iam_user.external_dns_iam_user.id
  policy_arn = aws_iam_policy.external_dns_r53_policy.arn
}

resource "aws_iam_policy" "external_dns_r53_policy" {
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "route53:ChangeResourceRecordSets"

        ],
        "Resource" = [
          "arn:aws:route53:::hostedzone/${data.aws_route53_zone.root_zone.zone_id}"
        ]
      },
      {
        "Effect" = "Allow",
        "Action" = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource"
        ]
        "Resource" = [
          "*"
        ]
      }
    ]
  })
}
