#!/bin/bash

resource_group=$(az group list | jq '.[0].name')

sed -i "s/resource_group = \"[^\"]*\"/resource_group = $resource_group/" terraform.tfvars


rm *.tfstate
rm *.tfstate.backup
