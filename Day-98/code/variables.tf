variable "project_name" {
   default = "project ALPHA Resource"
}

variable "default_tags" {
   default = {
    company = "space9"
    managed_by = "cloud"
   }
}

variable "environment_tags" {
   default = {
    environment = "dev"
    cost_center = "cc-123"
   }
}

variable "bucket_name" {
    default = "ProjectAlphaStorageBucket with CAPS and spces!!!"
  
}

variable "allowed_ports" {
   default = "80,443,8080.443,3306" # it an string so now we have make it as the lsit 
}

variable "instance_sizes" {
    default = {
        dev = "t2.micro"
        staging = "t3.small"
        prod =  "t3.large"
    }
  
}

variable "environment" {
  default = "dev"
}

variable "instance_type" {
  
  default = "t2.micro"
  validation {
    condition = length(var.instance_type) >= 2 && length(var.instance_type) <=20
    error_message = "instance type mut 2 and 20 charaters long"
  }
  validation {
    condition = can(regex("^t[2-3]\\.",var.instance_type))
    error_message = "instance type must start with t2 or t3"
}
}

variable "backup_name" {
    default = "daily-backup"
    validation {
    
    condition = endswith(var.backup_name,"_backup")
    error_message = "Backup Name Must end with '_backup'"
    
    }
}

variable "credntials" {
    default = "xyz"
    sensitive = true
  
}
variable "user_location" {
    default = ["us-west-1", "us-west-2", "us-east-1"]  #list doesnt allow dublicate vlaues 
  
}



variable "default_location" {
    default = ["us-west-1"]
  
}


variable "monthly_costs" {
  type        = list(number)
  description = "Monthly infrastructure costs (can include negative values for credits)"
  default     = [-50, 100, 75, 200]
}

