# 🧭 SharePoint Device Inventory Automation

This PowerShell project automates the creation and configuration of a complete **Device Inventory List** in SharePoint Online using the **PnP.PowerShell module**.

It’s designed for IT administrators who need a repeatable, script-based way to build a structured hardware tracking system—covering laptops, monitors, docks, and accessories—without relying on manual list configuration.

---

## 🚀 Features

✅ **Fully Automated Setup**
- Builds a complete SharePoint list from scratch  
- Automatically creates all required fields and data types  
- Applies default values and column formatting

✅ **Customizable Schema**
- Fields include:
  - Employee Name (Person field)
  - Company (Choice field)
  - Laptop Model & MAC Address
  - New or Used status
  - Previous Owner
  - Monitor Model & Quantity
  - Dock Included
  - Date Ordered, Order #, and Tracking Number
  - Status (Pending, Issued, Returned, Replaced)

✅ **Dynamic Views**
Automatically generates helpful views for operations:
- **Pending** (Status = Pending)  
- **Issued** (Status = Issued)  
- **Orders - Last 30 Days** (Date Ordered within the last month)  
- **CompanyA / CompanyB** (filtered by company choice)

✅ **UI Enhancements**
- Removes the unnecessary *Title* column  
- Applies conditional color formatting to **Status** for quick visual tracking

✅ **Version Control Ready**
- All site-specific and organization identifiers are replaced with placeholders, making it safe to reuse or publish publicly.

---

## 🧩 Requirements

| Dependency | Minimum Version | Purpose |
|-------------|------------------|----------|
| **PowerShell** | 7.x or later | Execution environment |
| **PnP.PowerShell** | 2.x or later | Module used to manage SharePoint Online |

To install PnP.PowerShell:

```powershell
Install-Module PnP.PowerShell -Scope CurrentUser
