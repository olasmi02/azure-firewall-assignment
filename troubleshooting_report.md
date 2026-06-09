# Troubleshooting Report – Azure Firewall Lab

## Overview

This report documents the challenges encountered during the deployment of the Azure Firewall lab environment and the steps taken to diagnose and resolve each issue. The troubleshooting process demonstrates practical application of network diagnostics in a cloud environment.

---

## Issue 1: AzureFirewallSubnet Size Too Small

### Problem
When initially planning the subnet allocation, a `/28` prefix was considered for the `AzureFirewallSubnet`. However, deployment failed with:

```
Error: The subnet AzureFirewallSubnet size /28 is too small.
Azure Firewall requires a minimum subnet size of /26.
```

### Root Cause
Azure Firewall is a highly available, auto-scaling service. It reserves IP addresses within the subnet for infrastructure management nodes. A `/26` (64 addresses) is the minimum to accommodate the firewall's scaling requirements.

### Resolution
Updated the subnet prefix from `/28` to `/26`:

```bash
az network vnet subnet update \
  --resource-group rg-azure-firewall-lab \
  --vnet-name vnet-firewall-lab \
  --name AzureFirewallSubnet \
  --address-prefixes 10.0.1.0/26
```

### Lesson Learned
Always provision `AzureFirewallSubnet` with a minimum `/26` CIDR block.

---

## Issue 2: Public IP SKU Mismatch

### Problem
Initially attempted to create the Public IP with the `Basic` SKU:

```bash
az network public-ip create --sku Basic ...
```

This resulted in a deployment error when attaching the IP to the firewall:

```
Error: Azure Firewall requires a Standard SKU public IP address.
Basic SKU public IP addresses are not supported.
```

### Root Cause
Azure Firewall Standard requires a **Standard SKU** static public IP address. Basic SKU IPs lack the zone-redundancy and availability guarantees required by the firewall service.

### Resolution
Recreated the Public IP with the correct SKU:

```bash
az network public-ip create \
  --resource-group rg-azure-firewall-lab \
  --name pip-firewall-lab \
  --sku Standard \
  --allocation-method Static
```

### Lesson Learned
Azure Firewall Standard → Always use Standard SKU Public IPs. Basic IPs are incompatible.

---

## Issue 3: Traffic Not Being Inspected (UDR Missing)

### Problem
After deploying the firewall and configuring rules, test traffic from the VM was bypassing the firewall entirely. The VM could reach the internet without any filtering.

### Diagnosis
Checked the effective routes on the VM's network interface:

```bash
az network nic show-effective-route-table \
  --resource-group rg-azure-firewall-lab \
  --name vm-workload-nic \
  --output table
```

Output showed no custom routes — the VM was using the default Azure system routes.

### Root Cause
The Route Table with the UDR was created but **not associated** with the `WorkloadSubnet`. Without the association, VMs in the subnet continued using Azure's default routing.

### Resolution
Associated the Route Table with the WorkloadSubnet:

```bash
az network vnet subnet update \
  --resource-group rg-azure-firewall-lab \
  --vnet-name vnet-firewall-lab \
  --name WorkloadSubnet \
  --route-table rt-firewall-lab
```

After association, confirmed effective routes showed the custom UDR:

```
Source    State    Address Prefix    Next Hop Type      Next Hop IP
--------  -------  ----------------  -----------------  -----------
User      Active   0.0.0.0/0         VirtualAppliance   10.0.1.4
```

### Lesson Learned
Creating a Route Table is not enough — it must be explicitly **associated** with each subnet that needs forced tunneling.

---

## Issue 4: DNS Resolution Failures Inside VM

### Problem
After enforcing traffic through the firewall, the test VM could not resolve domain names:

```
curl: (6) Could not resolve host: microsoft.com
nslookup: connection timed out; no servers could be reached
```

### Diagnosis
The VM was using Azure's default DNS (168.63.129.16) which was being blocked by the firewall's default-deny rules.

```bash
# Check what DNS server the VM is using
cat /etc/resolv.conf
# nameserver 168.63.129.16
```

### Root Cause
The firewall's Network Rule collection was not yet configured to allow DNS traffic (UDP port 53). All traffic was implicitly denied.

### Resolution
Added a Network Rule to allow DNS:

```bash
az network firewall policy rule-collection-group collection add-filter-collection \
  --resource-group rg-azure-firewall-lab \
  --policy-name fwpolicy-lab \
  --rule-collection-group-name NetworkRuleCollectionGroup \
  --name AllowNetworkRules \
  --collection-priority 100 \
  --action Allow \
  --rule-name AllowDNS \
  --rule-type NetworkRule \
  --source-addresses "10.0.2.0/24" \
  --destination-addresses "8.8.8.8" "8.8.4.4" \
  --ip-protocols UDP \
  --destination-ports 53
```

### Lesson Learned
When deploying a default-deny firewall, DNS must be the **first rule** configured — without it, nothing works, not even downloading updates.

---

## Issue 5: Application Rules Not Working Without DNS

### Problem
Even after configuring Application Rules to allow `*.microsoft.com`, HTTPS connections still failed.

### Root Cause
Application Rules use FQDN matching, which requires DNS resolution to function. Since DNS was blocked (see Issue 4), the firewall could not resolve domain names to compare against FQDN rules.

### Resolution
Resolved after fixing Issue 4 (allowing DNS). Rule evaluation order is:
1. NAT Rules (processed first)
2. Network Rules
3. Application Rules

DNS must be working before application-layer FQDN rules can function.

### Lesson Learned
Azure Firewall processes rules in order: **NAT → Network → Application**. DNS must be permitted at the Network rule level before Application rules can match FQDNs.

---

## Issue 6: Threat Intelligence Not Triggering Alerts

### Problem
After enabling Threat Intelligence in `Alert` mode, no entries appeared in Log Analytics for threat-based blocks.

### Root Cause
Two contributing factors:
1. Log Analytics diagnostic settings were not yet configured (no logs being sent)
2. Test traffic was not directed to any known-malicious IP/domain

### Resolution

**Step 1:** Enable diagnostic settings:
```bash
az monitor diagnostic-settings create \
  --name fw-diagnostics \
  --resource <firewall-resource-id> \
  --workspace <log-analytics-workspace-id> \
  --logs '[{"category":"AzureFirewallNetworkRule","enabled":true},{"category":"AzureFirewallApplicationRule","enabled":true}]'
```

**Step 2:** Switch Threat Intel to `Deny` mode to make blocking visible:
```bash
az network firewall policy update \
  --resource-group rg-azure-firewall-lab \
  --name fwpolicy-lab \
  --threat-intel-mode "Deny"
```

**Step 3:** Query logs in Log Analytics:
```kql
AzureDiagnostics
| where Category == "AzureFirewallNetworkRule"
| where msg_s contains "ThreatIntel"
| project TimeGenerated, msg_s, Action_s
```

---

## Summary of Key Troubleshooting Lessons

| # | Issue | Root Cause | Fix |
|---|-------|------------|-----|
| 1 | Subnet too small | /28 vs required /26 | Use minimum /26 for AzureFirewallSubnet |
| 2 | Public IP SKU mismatch | Basic SKU incompatible | Use Standard SKU Public IP |
| 3 | Traffic bypassing firewall | Route Table not associated | Associate UDR with subnet |
| 4 | DNS failures | UDP/53 not allowed | Add DNS network rule first |
| 5 | App rules not matching | DNS blocked = FQDN unresolvable | Fix DNS before app rules |
| 6 | No threat intel logs | Diagnostic settings missing | Enable Log Analytics diagnostics |

---

## Diagnostic Commands Reference

```bash
# Check firewall provisioning state
az network firewall show \
  --resource-group rg-azure-firewall-lab \
  --name fw-lab \
  --query "provisioningState"

# View effective routes on VM NIC
az network nic show-effective-route-table \
  --resource-group rg-azure-firewall-lab \
  --name <nic-name> --output table

# Check firewall rules
az network firewall policy rule-collection-group list \
  --resource-group rg-azure-firewall-lab \
  --policy-name fwpolicy-lab --output table

# Verify diagnostic settings
az monitor diagnostic-settings list \
  --resource <firewall-resource-id>
```
