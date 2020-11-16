output "edmz_vpc_id" {
  value = data.aws_vpc.edmz_vpc.id
}
 
# output "edmz_subnet_id" {
#   value = data.aws_subnet.edmz_subnet.id
# }
# 
# output "edmz_igw" {
#   value = "data.aws_internet_gateway.edmz_igw"
# }
 
output "idmz_vpc_id" {
  value = data.aws_vpc.idmz_vpc.id
}
 
# output "idmz_subnet_id" {
#   value = data.aws_subnet.idmz_subnet.id
# }
# 
# output "idmz_igw" {
#  value = "data.aws_internet_gateway.idmz_igw"
#}

output "edmz_subnet_ids" {
  value = "${zipmap(data.aws_subnet.edmz_subnet.*.tags.Name, data.aws_subnet.edmz_subnet.*.id)}"
}

output "idmz_subnet_ids" {
  value = "${zipmap(data.aws_subnet.idmz_subnet.*.tags.Name, data.aws_subnet.idmz_subnet.*.id)}"
}
