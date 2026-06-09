# Screenshots Guide for Submission

To satisfy the rubric requirements, you need to capture **5 screenshots** from the Azure Portal and your local verification terminal. 

Once you take these screenshots, save them with the exact filenames listed below and place them in this `screenshots/` folder. The `README.md` and `deployment_report.md` are already configured with markdown links that will automatically embed and display these screenshots on GitHub once you push them.

---

### 1. Network Rules Screenshot
* **Filename**: `network_rules.png` (or `.jpg`)
* **How to Capture**:
  1. In the Azure Portal search bar, type **Firewall Policies** and select `fwpolicy-lab`.
  2. Under the **Settings** menu on the left, click on **Rule Collection Groups** (or **Rules (classic)**).
  3. Click on the `NetworkRuleCollectionGroup` to expand the rules.
  4. Take a screenshot showing the `AllowDNS` and `AllowICMP` rules.

### 2. Application Rules Screenshot
* **Filename**: `application_rules.png` (or `.jpg`)
* **How to Capture**:
  1. Open the same `fwpolicy-lab` policy in the Azure Portal.
  2. Under **Settings** -> **Rule Collection Groups**, click on the `AppRuleCollectionGroup`.
  3. Take a screenshot showing the `AllowWebTraffic` collection (allowing `*.microsoft.com`, `*.github.com`) and the `DenyAllWeb` collection.

### 3. NAT Rules Screenshot
* **Filename**: `nat_rules.png` (or `.jpg`)
* **How to Capture**:
  1. Open `fwpolicy-lab` in the Azure Portal.
  2. Navigate to **Settings** -> **Rule Collection Groups** and click on `NATRuleCollectionGroup`.
  3. Take a screenshot showing `InboundNAT` (translating inbound Port `8080` to IP `10.0.2.4` Port `80`).

### 4. Route Table (Next Hop) Screenshot
* **Filename**: `route_table.png` (or `.jpg`)
* **How to Capture**:
  1. In the Azure Portal search bar, type **Route Tables** and select `rt-firewall-lab`.
  2. Click on **Routes** under the **Settings** menu on the left.
  3. Take a screenshot showing the default route `0.0.0.0/0` with Next Hop Type `Virtual Appliance` and Next Hop IP Address `10.0.1.4`.

### 5. Traffic Filtering Verification Screenshot
* **Filename**: `traffic_verification.png` (or `.jpg`)
* **How to Capture**:
  1. Run the local verification curl test command in your PowerShell/Terminal:
     ```powershell
     curl.exe -I http://20.61.208.52:8080
     ```
  2. Capture a screenshot of the terminal showing the successful `HTTP/1.0 200 OK` connection to the Python server through the DNAT rule.
  3. Alternatively, you can screenshot the `logs/validation_results.txt` output showing the allowed/blocked test results.
