variable "platform_mg_name" {
  description = "Name for the Platform management group"
  type        = string
  default     = "mg-platform"
}

variable "landing_zones_mg_name" {
  description = "Name for the Landing Zones management group"
  type        = string
  default     = "mg-landingzones"
}

variable "sandbox_mg_name" {
  description = "Name for the Sandbox management group"
  type        = string
  default     = "mg-sandbox"
}

variable "decommissioned_mg_name" {
  description = "Name for the Decommissioned management group"
  type        = string
  default     = "mg-decommissioned"
}

variable "corp_mg_name" {
  description = "Name for the Corp management group"
  type        = string
  default     = "mg-corp"
}

variable "online_mg_name" {
  description = "Name for the Online management group"
  type        = string
  default     = "mg-online"
}

variable "subscription_id" {
  description = "Subscription ID to associate with the Corp management group"
  type        = string
  default     = ""
}
