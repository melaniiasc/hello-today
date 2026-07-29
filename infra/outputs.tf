output "bucket_name" {
  value = module.s3_bucket.s3_bucket_bucket_domain_name
}
output "bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}
