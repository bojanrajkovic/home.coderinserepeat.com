variable "caa_records" {
  default = [
    "0 issuewild \";\"",
    "0 issue \"amazon.com\"",
    "0 issue \"letsencrypt.org\"",
    "128 iodef \"mailto:brajkovic@coderinserepeat.com\""
  ]
  description = "Record values to insert into each zone's CAA record set."
  type        = list(string)
}

variable "mx_records" {
  default = [
    "1 ASPMX.L.GOOGLE.COM",
    "5 ALT1.ASPMX.L.GOOGLE.COM",
    "5 ALT2.ASPMX.L.GOOGLE.COM",
    "10 ALT3.ASPMX.L.GOOGLE.COM",
    "10 ALT4.ASPMX.L.GOOGLE.COM"
  ]
  description = "Record values to insert into each zone's MX record set."
  type        = list(string)
}

variable "dkim_keys" {
  type        = map(string)
  description = "DKIM keys for various domains"
}

variable "www_coderinserepeat_com_cloudformation_distribution_id" {
  type        = string
  description = "Cloudfront distribution ID for coderinserepeat.com"
}

variable "test_coderinserepeat_com_cloudformation_distribution_id" {
  type        = string
  description = "Cloudfront distribution ID for test.coderinserepeat.com"
}

variable "handclaps_io_cloudfront_distribution_id" {
  type        = string
  description = "Cloudfront distribution ID for handclaps.io"
}

variable "rajkovic_dev_cloudfront_distribution_id" {
  type        = string
  description = "Cloudfront distribution ID for rajkovic.dev"
}

variable "domains" {
  type        = set(string)
  description = "The set of domains to manage through this Terraform module"
}

variable "domain_zone_mappings" {
  type        = map(string)
  description = "A mapping of domain name to Route53 zone ID for existing domains/zones"
}
