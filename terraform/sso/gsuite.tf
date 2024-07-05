resource "aws_iam_saml_provider" "gsuite" {
  name                   = "gsuite"
  saml_metadata_document = file("../../secrets/sso/GoogleIDPMetadata.xml")
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "gsuite-saml-poweruser-role" {
  max_session_duration = 3600
  managed_policy_arns  = ["arn:aws:iam::aws:policy/PowerUserAccess"]

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithSAML"
      Condition = {
        StringEquals = {
          "SAML:aud" = "https://signin.aws.amazon.com/saml"
        }
      }
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:saml-provider/gsuite"
      }
    }]
    Version = "2012-10-17"
  })
}

import {
  to = aws_iam_role.gsuite-saml-poweruser-role
  id = "gsuite-saml-poweruser-role"
}
