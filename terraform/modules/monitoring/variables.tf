variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "guardian-eks-cluster"
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic"
  type        = string
}