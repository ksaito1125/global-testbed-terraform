variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "pc_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}
