# Azure Backup Solutions - Customer Walkthrough Guide

## Overview
This progressive walkthrough demonstrates the differences and similarities between Azure's three backup approaches: Manual Managed Disk Snapshots, Recovery Services Vault (RSV), and Azure Backup Vault. Use this guide with your existing lab environment to showcase each solution's unique value proposition.

---

## Phase 1: Manual Managed Disk Snapshots
*"The Foundation Technology"*

### Demo Steps:
1. **Navigate to a managed disk** in your lab VM
   - Azure Portal → Virtual Machines → [Your VM] → Disks → Click on OS/Data disk
   - Show the "Create Snapshot" button

2. **Create a manual snapshot**
   - Click "Create Snapshot"
   - Choose "Incremental" snapshot type
      - Basics: Full or Incremental
      - Encryption: Choose PMK or CMK
      - Networking: Explain the different options
      - Advanced: Requires Entra ID auth for any export/downlod operations
         - Disk Backup Reader - to read disk/snapshot metadata
         - Disk Snapshot Contributor - to create snapshots
         - Additional data access permissions if trying to export/download snapshot data
   - Explain: *"This is the underlying technology all Azure backup solutions use"*
      - Snapshot resource appears in the resource group

3. **Key Points to Highlight:**
   - **Technology Foundation**: All Azure backup solutions use this same snapshot API
      - **Not full copies** - Snapshots are incremental references that store only changed blocks, not complete disk duplicates
      - **First snapshot = baseline**, subsequent snapshots = deltas - Azure automatically reconstructs the full disk by combining the base with incremental changes during restore
      - **Block-level efficiency** - Only changed storage blocks are captured, making snapshots typically 10-20% the size of the source disk
      - **Instant accessibility** - Despite being incremental references, snapshots provide immediate access to reconstruct complete disk data
      - **Reference chain dependency** - Snapshots link together in a chain, which is why there's a 500 snapshot limit per disk
      - **Azure-managed storage** - Stored in proprietary Azure infrastructure (not VHD files in your storage accounts like the old unmanaged disk model)
      - **Standard HDD tier** - All snapshots stored on Standard HDD regardless of source disk type, keeping costs predictable
   - **Immediate Availability**: Snapshot appears instantly in the same subscription as an azure resource
   - **Cost Model**: Pay only for incremental storage (~10-20% of source disk)
   - **Manual Process**: No automation, scheduling, or lifecycle management

### Customer Value Discussion:
- **Best For**: One-time backups before changes, testing, development environments
- **Limitations**: No automation, no retention policies, manual cleanup required
- **FSI Consideration**: Lacks audit trails and automated compliance reporting
   - Only Basic activity logging
   - No policy enforcement documentation
   - No retention compliance tracking
   - No centralized compliance reporting
   - No business continuity documentation

---

## Phase 2: Recovery Services Vault (RSV)
*"The Traditional Enterprise Backup"*

### Demo Steps:
1. **Show existing RSV configuration**
   - Azure Portal → Recovery Services Vaults → [Your RSV]
   - Navigate to "Backup Items" → Show protected VMs

2. **Examine VM backup policy**
   - Backup policies → View daily backup schedule
   - Show retention settings (daily, weekly, monthly, yearly)

3. **Demonstrate backup process**
   - Protected items → Azure Virtual Machine → Select a VM
   - Show recent backup jobs and recovery points
   - Explain the two-phase process: Snapshot → Vault transfer

4. **Show restore capabilities**
   - Click "Restore VM" to show restore options
   - Highlight: Create new VM, Replace existing, Restore disks

### Key Points to Highlight:
- **Application Consistency**: Coordinates with VSS/scripts for transactional consistency
- **Hybrid Integration**: Same vault can protect on-premises and Azure workloads
- **Long-term Retention**: Years of retention with automated lifecycle management
- **Vault Transfer**: Data moved to vault storage for durability and compliance
- **Agent Dependency**: Requires backup extension on VMs

### Customer Value Discussion:
- **Best For**: Production VMs, compliance requirements, disaster recovery
- **FSI Advantages**: Application-consistent backups for databases, audit trails, long-term retention
- **Trade-offs**: Slower recovery due to vault transfer, higher costs for long-term retention

---

## Phase 3: Azure Backup Vault - Operational Recovery
*"The Modern Operational Approach"*

### Demo Steps:
1. **Show Backup Vault configuration**
   - Azure Portal → Backup Vault → [Your Backup Vault]
   - Navigate to "Backup Instances" → Show protected managed disks

2. **Examine backup policy differences**
   - Backup policies → Show hourly backup options (1-24 hours)
   - Highlight: Operational tier vs. Vault tier retention
   - Explain: Maximum 180-200 snapshots, shorter retention periods

3. **Show snapshot location**
   - Navigate to the Snapshots service: Azure Portal → Search "Snapshots" → Select "Snapshots"
   - Explain: *"Same snapshots as manual process, just automated"*

4. **Demonstrate rapid recovery**
   - Show restore options → Highlight speed advantages
   - Explain: No vault transfer needed, local snapshot restore

### Key Points to Highlight:
- **Same Technology**: Uses identical snapshot API as manual snapshots
- **Operational Focus**: Designed for frequent, rapid recovery scenarios
- **Local Storage**: Snapshots remain with source disk for speed
- **No Agent**: Works without VM extensions or agents
- **Cost Optimization**: No data transfer fees, only snapshot storage costs

### Customer Value Discussion:
- **Best For**: Operational recovery, frequent backups, rapid RTO requirements
- **FSI Use Cases**: Trading desk recovery, rapid rollback scenarios, cost-sensitive environments
- **Limitations**: Crash-consistent only, shorter retention, no long-term archival

---

## Phase 4: Comparative Analysis
*"The Strategic Decision Framework"*

### Side-by-Side Demonstration:
1. **Create the same backup using all three methods**
   - Manual snapshot: Show immediate creation
   - RSV: Show backup job initiation and transfer process
   - Backup Vault: Show automated snapshot creation

2. **Compare recovery scenarios**
   - Show recovery speed differences
   - Demonstrate consistency levels
   - Compare cost implications

### Decision Matrix for Customers:

| Requirement | Manual Snapshots | Recovery Services Vault | Backup Vault |
|-------------|------------------|-------------------------|--------------|
| **Automation** | ❌ Manual only | ✅ Full automation | ✅ Full automation |
| **Frequency** | On-demand | Daily (max 3x) | Hourly (max 24x) |
| **Consistency** | Crash-consistent | Application-consistent | Crash-consistent |
| **Retention** | Manual cleanup | Years with lifecycle | Days to months |
| **Recovery Speed** | Fast (local) | Slower (vault transfer) | Fast (local) |
| **FSI Compliance** | ❌ Limited | ✅ Full compliance | ⚠️ Operational only |
| **Cost Model** | Snapshot storage only | Service + storage + egress | Service + snapshot storage |
| **Multi-cloud** | ❌ Azure only | ⚠️ Limited | ❌ Azure only |

---

## Phase 5: Real-World Architecture Patterns
*"How FSI Organizations Actually Deploy These"*

### Pattern 1: Complementary Architecture
```
Production VMs:
├── Recovery Services Vault (Long-term, compliance)
├── Backup Vault (Operational recovery)
└── Manual Snapshots (Change management)
```

**Demo**: Show same VM protected by multiple solutions
**Explain**: Different solutions for different recovery scenarios

### Pattern 2: Tiered Approach
```
Critical Systems: RSV + Backup Vault
Standard Systems: Backup Vault only
Dev/Test: Manual Snapshots
```

**Demo**: Show different protection levels across VM types
**Explain**: Risk-based backup strategy alignment

### Pattern 3: Hybrid Integration
```
On-premises: RSV (MARS/DPM agents)
Azure VMs: RSV (same vault)
Azure Disks: Backup Vault (operational)
```

**Demo**: Show hybrid protection in single RSV
**Explain**: Unified management across environments

---

## Phase 6: Customer Engagement Framework
*"Guiding the Conversation"*

### Discovery Questions:
1. **"What are your RTO/RPO requirements?"**
   - < 1 hour: Backup Vault + Manual snapshots
   - 4-24 hours: Recovery Services Vault
   - Mixed requirements: Complementary approach

2. **"What compliance frameworks apply?"**
   - FINRA/SEC: Recovery Services Vault required
   - Internal policies: May allow Backup Vault
   - Cost-sensitive: Backup Vault + manual snapshots

3. **"How complex are your applications?"**
   - Database workloads: RSV (application consistency)
   - Stateless applications: Backup Vault sufficient
   - Development: Manual snapshots acceptable

### Objection Handling:
- **"Why not just use manual snapshots?"**: Show lifecycle management complexity
- **"This seems expensive"**: Demonstrate TCO including operational overhead
- **"We already have third-party tools"**: Show complementary value, not replacement

---

## Phase 7: Next Steps and Action Items
*"Converting the Demo to Deployment"*

### Immediate Actions:
1. **Assessment Workshop**: Use built-in Azure Backup Assessment tool
2. **Pilot Design**: Start with non-critical workloads using Backup Vault
3. **Policy Framework**: Develop backup policies aligned with data classification
4. **Cost Modeling**: Use Azure Calculator for different scenarios

### Long-term Roadmap:
1. **Month 1**: Deploy Backup Vault for operational workloads
2. **Month 2**: Implement RSV for critical systems and compliance
3. **Month 3**: Integrate with disaster recovery strategy
4. **Ongoing**: Optimize based on usage patterns and cost analysis

---

## Demo Script Quick Reference

### Opening (2 minutes):
*"Today we'll explore three approaches to protecting your Azure VMs and data. Each serves different business needs, and many customers use all three in a complementary strategy."*

### Manual Snapshots (5 minutes):
*"This is the foundation - the same technology everything else builds on. Great for one-time needs but lacks enterprise features."*

### Recovery Services Vault (8 minutes):
*"This is your traditional enterprise backup - comprehensive, compliant, but designed for disaster recovery timeframes."*

### Backup Vault (8 minutes):
*"This is operational recovery - same technology as manual, but with enterprise automation for rapid, frequent backups."*

### Comparison (7 minutes):
*"Now you can see how each serves different scenarios. The magic happens when you combine them strategically."*

### Architecture Patterns (10 minutes):
*"Here's how successful financial services organizations actually deploy these solutions in practice."*

### Wrap-up (5 minutes):
*"The key insight: these aren't competing solutions - they're complementary tools for different recovery scenarios and business requirements."*

---

## Additional Resources

### Microsoft Documentation:
- [Azure Backup Architecture Overview](https://learn.microsoft.com/en-us/azure/backup/backup-architecture)
- [Recovery Services Vault Overview](https://learn.microsoft.com/en-us/azure/backup/backup-azure-recovery-services-vault-overview)
- [Backup Vault Overview](https://learn.microsoft.com/en-us/azure/backup/backup-vault-overview)
- [Azure Managed Disk Snapshots](https://learn.microsoft.com/en-us/azure/virtual-machines/snapshot-copy-managed-disk)

### FSI-Specific Resources:
- [Azure Financial Services Compliance](https://docs.microsoft.com/en-us/azure/compliance/)
- [Azure Security Center for Financial Services](https://docs.microsoft.com/en-us/azure/security-center/)
- [Azure Backup Security Features](https://learn.microsoft.com/en-us/azure/backup/security-overview)

---

*This walkthrough is designed to be completed in 45-60 minutes with adequate time for questions and discussion. Adjust timing based on customer engagement level and technical depth required.*