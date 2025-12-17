# ASR Demo Lab

This repository demonstrates deployment and testing of Azure Site Recovery (ASR) for virtual machines using Bicep templates and supporting scripts.

## Overview

- **deploy.bicep**: This Bicep template automates the creation of resources needed to demo ASR for VMs on Azure. It sets up resource groups in a source and target region, virtual networks, monitoring/log analytics, ASR and backup vaults, automation accounts, and supporting storage accounts. It is parameterized for flexible configuration.
- **deployit.ps1**: PowerShell script to simplify deployment. It handles Azure login, context setup, and triggers the Bicep deployment with specified parameters.
- **deployparam.yaml**: Parameter file containing all user-customizable deployment values, including subscription, regions, admin password, VNet/IP settings, VM configurations, and more.

## Quick Start

1. Edit `deployparam.yaml` with your desired Azure settings (subscriptionId, regions, VM details, etc.)
2. From a PowerShell prompt, run the deployment script:
   ```powershell
   ./deployit.ps1
   ```

The script will log in to Azure (if needed), set the context, and deploy all resources as described in the Bicep template.

## Repository Structure

- `.devcontainer/` : Dev container setup (for codespaces/VSCode).
- `DOCUMENTATION/` : Project documentation (see for details on configuration and testing).
- `MODULES/` : Nested Bicep modules for sub-components (network, site recovery, storage, etc).
- `deploy.bicep` : Main Bicep template for infrastructure.
- `deployit.ps1` : Main deployment automation script.
- `deployparam.yaml` : Editable parameters for deployment.
- `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `LICENSE` : Community and support files.

## License

This project is licensed under the MIT License.

---

> For any issues, please refer to the SUPPORT.md file or open a GitHub issue.
