variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "frontend_image" {
  description = "Docker image for the frontend"
  type        = string
}

variable "backend_image" {
  description = "Docker image for the backend"
  type        = string
}