# Azure Virtual Network Security – Azure Firewall Lab

[![GitHub](https://img.shields.io/badge/GitHub-azure--firewall--assignment-blue?logo=github)](https://github.com/olasmi02/azure-firewall-assignment)

## Overview

This project demonstrates enterprise-grade network security on Microsoft Azure using **Azure Firewall**, a fully managed, stateful Firewall-as-a-Service (FWaaS). The lab transitions from basic Network Security Groups (NSGs) to centralized, policy-driven traffic control with full monitoring and threat intelligence integration.

---

## Architecture Summary

```
Internet
    │
    ▼
[Public IP: pip-firewall-lab]
    │
    ▼
┌─────────────────────────────────────────┐
│     VNet: vnet-firewall-lab             │
│     Address Space: 10.0.0.0/16          │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  AzureFirewallSubnet             │   │
│  │  10.0.1.0/26                     │   │
│  │  ┌────────────────────────────┐  │   │
│  │  │  Azure Firewall            │  │   │
│  │  │  (fw-lab)                  │  │   │
│  │  │  Private IP: 10.0.1.4      │  │   │
│  │  └────────────────────────────┘  │   │
│  └──────────────────────────────────┘   │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  WorkloadSubnet                  │   │
│  │  10.0.2.0/24                     │   │
│  │  ┌────────────────────────────┐  │   │
│  │  │  Test VM (vm-workload)     │  │   │
│  │  │  10.0.2.4                  │  │   │
│  │  └────────────────────────────┘  │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
         │
         ▼
  Route Table (rt-firewall-lab)
  Default Route: 0.0.0.0/0 → 10.0.1.4 (Firewall)
```

---

## Repository Structure

```
azure-firewall-assignment/
├── README.md                    ← This file
├── architecture_diagram.md      ← Detailed network topology & design
├── deployment_report.md         ← Step-by-step deployment guide with CLI outputs
├── troubleshooting_report.md    ← Issues encountered and how they were resolved
├── configs/
│   ├── firewall_policy_export.json   ← Exported firewall policy configuration
│   ├── firewall_rules.json      ← Network, Application & NAT rule collections
│   └── route_table.json         ← Route table UDR configuration
├── logs/
│   ├── network_rule_logs.txt    ← Traffic filtering evidence (allowed traffic)
│   ├── app_rule_logs.txt        ← Application rule filtering logs
│   └── validation_results.txt   ← Connectivity test results
└── screenshots/
    └── README.md                ← Instructions & placeholders for required screenshots
```

---

## Completed Tasks

| # | Task | Status |
|---|------|--------|
| 1 | Network Preparation (VNet + Subnets) | ✅ Complete |
| 2 | Firewall Deployment | ✅ Complete |
| 3 | Route Table & UDR Configuration | ✅ Complete |
| 4 | Network Rules | ✅ Complete |
| 5 | Application Rules | ✅ Complete |
| 6 | NAT Rules | ✅ Complete |
| 7 | Threat Intelligence | ✅ Complete |
| 8 | Validation & Troubleshooting | ✅ Complete |
| 9 | Monitoring Setup | ✅ Complete |

---

## Key Configurations

### Network Rules
- Allow DNS (UDP/53) from WorkloadSubnet → 8.8.8.8
- Allow ICMP from WorkloadSubnet for diagnostics

### Application Rules
- Allow HTTPS to `*.microsoft.com`
- Allow HTTPS to `*.github.com`
- Deny all other outbound HTTP/HTTPS

### NAT Rules
- DNAT: Public IP port 8080 → Internal VM port 80

### Threat Intelligence
- Mode: **Alert and Deny** (blocks known malicious IPs/domains)

---

## Resources Deployed

| Resource | Name | Location |
|----------|------|----------|
| Resource Group | `rg-azure-firewall-lab` | West Europe |
| Virtual Network | `vnet-firewall-lab` | West Europe |
| Azure Firewall | `fw-lab` | West Europe |
| Firewall Policy | `fwpolicy-lab` | West Europe |
| Public IP | `pip-firewall-lab` | West Europe |
| Route Table | `rt-firewall-lab` | West Europe |
| Log Analytics Workspace | `law-firewall-lab` | West Europe |

---

## How to Reproduce

See [`deployment_report.md`](./deployment_report.md) for the complete step-by-step CLI deployment guide.

---

## Author

- **GitHub Username:** olasmi02
- **Repository:** [https://github.com/olasmi02/azure-firewall-assignment](https://github.com/olasmi02/azure-firewall-assignment)
- **Subscription:** Azure for Students
- **Date:** June 2026
- **Firewall Public IP:** 20.61.208.52
- **Firewall Private IP:** 10.0.1.4
