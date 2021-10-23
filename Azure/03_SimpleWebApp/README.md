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

# Security

## Firewall

### Rules

There are three types of rule collections:

* Application rules: Configure fully qualified domain names (FQDNs) that can be accessed from a subnet.
* Network rules: Configure rules that contain source addresses, protocols, destination ports, and destination addresses.
* NAT rules: Configure DNAT rules to allow incoming Internet connections.

Src: [https://docs.microsoft.com/en-us/azure/firewall/firewall-faq](https://docs.microsoft.com/en-us/azure/firewall/firewall-faq)

# Monitoring

Types of Agents:


|                                 | Azure Monitor agent                                   | Diagnostics extension (LAD) | Telegraf agent                | Log Analytics agent                                                             | Dependency agent                                 |
|---------------------------------|-------------------------------------------------------|-----------------------------|-------------------------------|---------------------------------------------------------------------------------|--------------------------------------------------|
| Environments supported          | Azure Other cloud (Azure Arc) On-premises (Azure Arc) | Azure                       | Azure Other cloud On-premises | Azure Other cloud On-premises                                                   | Azure Other cloud On-premises                    |
| Agent requirements              | None                                                  | None                        | None                          | None                                                                            | Requires Log Analytics agent                     |
| Data collected                  | Syslog Performance                                    | Syslog Performance          | Performance                   | Syslog Performance                                                              | Process dependencies Network connection metrics  |
| Data sent to                    | Azure Monitor Logs Azure Monitor Metrics1             | Azure Storage Event Hub     | Azure Monitor Metrics         | Azure Monitor Logs                                                              | Azure Monitor Logs (through Log Analytics agent) |
| Services and features supported | Log Analytics Metrics explorer                        |                             | Metrics explorer              | VM insights Log Analytics Azure Automation Azure Security Center Azure Sentinel | VM insights Service Map                          |

The Azure Monitor agent is meant to replace the Log Analytics agent, Azure Diagnostic extension and Telegraf agent for both Windows and Linux machines. 

Src: [https://docs.microsoft.com/en-gb/azure/azure-monitor/agents/agents-overview](https://docs.microsoft.com/en-gb/azure/azure-monitor/agents/agents-overview):e

> The Azure Monitor agent replaces the following legacy agents that are currently used by Azure Monitor to collect guest data from virtual machines (view known gaps):
> * Log Analytics agent: Sends data to a Log Analytics workspace and supports VM insights and monitoring solutions.
> * Diagnostics extension: Sends data to Azure Monitor Metrics (Windows only), Azure Event Hubs, and Azure Storage.
> * Telegraf agent: Sends data to Azure Monitor Metrics (Linux only).



## Metrics Namespace

Supported metrics with Azure Monitor: [https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-supported](https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-supported)

Deploy Monitoring and Dependency Agents: [https://stackoverflow.com/questions/66633650/terraform-enable-vm-insights](https://stackoverflow.com/questions/66633650/terraform-enable-vm-insights)

Install Azure Monitor agent: [https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-install](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-install)
