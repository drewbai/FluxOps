variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Lifecycle management toggles and settings
variable "enable_management_policy" {
  description = "Enable storage management policy for cost optimization"
  type        = bool
  default     = true
}

variable "logs_cool_after_days" {
  description = "Move logs to Cool tier after N days"
  type        = number
  default     = 7
}

variable "logs_delete_after_days" {
  description = "Delete logs after N days"
  type        = number
  default     = 30
}
