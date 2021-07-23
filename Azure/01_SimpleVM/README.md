# Create VM on Azure

## Prepare Docker to run the Terraform scripts

Create docker instance
```
docker run -it --name terraform-azure ubuntu /bin/bash
```

Deploy Azure CLI and Terraform in Docker

```
# Install Azure CLI
apt update -y
apt install -y curl
curl -sL https://aka.ms/InstallAzureCLIDeb |  bash
az login

# Install Terraform
apt-get update &&  apt-get install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg |  apt-key add -
apt-get update && apt-get install terraform
terraform -help
```

Generate SSH key for the Docker account
```
ssh-keygen
```

