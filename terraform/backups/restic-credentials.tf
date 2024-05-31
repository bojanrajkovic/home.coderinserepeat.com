resource "aws_iam_user" "restic_iam_user" {
  name = "restic"
}

resource "aws_iam_access_key" "restic_access_keys" {
  depends_on = [aws_iam_user.restic_iam_user]
  user       = aws_iam_user.restic_iam_user.id
}

resource "aws_iam_user_policy_attachment" "restic_iam_user_policy_attachment" {
  depends_on = [aws_iam_user.restic_iam_user]
  user       = aws_iam_user.restic_iam_user.id
  policy_arn = aws_iam_policy.restic_s3_policy.arn
}

data "aws_s3_bucket" "backups" {
  bucket = "bojans-backups"
}

resource "aws_iam_policy" "restic_s3_policy" {
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:*",
        ],
        "Resource" = [
          "${data.aws_s3_bucket.backups.arn}",
          "${data.aws_s3_bucket.backups.arn}/*"
        ]
      }
    ]
  })
}