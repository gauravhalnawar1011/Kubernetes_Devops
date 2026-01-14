locals {
#   formatted_project_name = lower(var.project_name)
  new_tag = merge(var.default_tags,var.environment_tags)
  formatted_bucket_name = replace(replace(
  substr(lower(var.bucket_name),0,63)," ",""
  ),"!","")

  port_list = split(",",var.allowed_ports)
  sg_rules = [ for port in local.port_list :
  {
    name = "port-${port}" # string intepolution 
    port = port
    description = "allow traffic on port ${port}"
  }

  ]
  instance_size = lookup(var.instance_sizes,var.environment,"t2.micro")
  all_location = concat(var.default_location,var.user_location)
  unique_locations = toset(var.default_location)

  positive_cost = [for cost in var.monthly_costs : abs(cost)]
  max_cost = max(local.positive_cost...)
  min_cost = min(local.positive_cost...)
  total_cost = sum(local.positive_cost)
  avg_cost = local.total_cost / length(local.positive_cost)
  current_timestamp = timestamp()
  format1 = formatdate("yyyyMMdd",local.current_timestamp)
  format2 = formatdate("YYYY-MM-DD",local.current_timestamp)
  timestamp_name = "backup-${local.format1}"
  config_file_exists = fileexists("./config.json")
  config_data = local.config_file_exists ? jsondecode(file("./config.json")) : {}
}



# for the replacing the string spcae replced by -
locals {
  formatted_project_name = lower(replace(var.project_name," ","-"))
}
#how to works 1st replce will work "hello WORLD" -> "hello-WORLD"

#then it passes through the lower function "hello WORLD" -> hello-world

# for the merge function let add s3 resorces 

resource "aws_s3_bucket" "main" {
    bucket = local.formatted_bucket_name
    tags = local.new_tag
}
