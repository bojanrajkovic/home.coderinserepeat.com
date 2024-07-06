variable "ses_domain" {
  type = string
  description = "The domain name for which to set up SES email sending"
}

variable "ses_senders" {
  type = map(string)
  description = "SES senders to configure"
}

variable "ses_recipients" {
  type = map(string)
  description = "SES recipients to configure" 
}