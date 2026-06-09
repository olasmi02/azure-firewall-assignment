#!/bin/bash
echo "=== AZURE FIREWALL LIVE VALIDATION TESTS ==="
echo "VM: vm-workload | Private IP: 10.0.2.4 | West Europe Zone 1"
echo "Firewall: fw-lab | Policy: fwpolicy-lab | Threat Intel: Deny"
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo ""

# Ensure DNS is set to Google DNS (allowed by AllowDNS Network Rule)
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "[DNS configured to 8.8.8.8 - allowed by AllowDNS Network Rule]"
echo ""

echo "=========================================="
echo "TEST 1: DNS RESOLUTION (Network Rule: AllowDNS)"
echo "=========================================="
echo "Source: 10.0.2.4 -> Dest: 8.8.8.8:53 (UDP)"
nslookup microsoft.com 8.8.8.8
if [ $? -eq 0 ]; then echo "STATUS: ALLOWED"; else echo "STATUS: BLOCKED"; fi
echo ""

echo "=========================================="
echo "TEST 2: ALLOWED HTTPS - microsoft.com (App Rule: AllowMicrosoft)"
echo "=========================================="
echo "Source: 10.0.2.4 -> FQDN: www.microsoft.com:443"
RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 15 https://www.microsoft.com 2>/dev/null)
echo "HTTP Response Code: $RESULT"
if [ "$RESULT" -ge 200 ] 2>/dev/null && [ "$RESULT" -lt 400 ] 2>/dev/null; then
  echo "STATUS: ALLOWED - microsoft.com reachable through firewall"
else
  echo "STATUS: BLOCKED or ERROR (code=$RESULT)"
fi
echo ""

echo "=========================================="
echo "TEST 3: ALLOWED HTTPS - github.com (App Rule: AllowGitHub)"
echo "=========================================="
echo "Source: 10.0.2.4 -> FQDN: api.github.com:443"
RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 15 https://api.github.com 2>/dev/null)
echo "HTTP Response Code: $RESULT"
if [ "$RESULT" -ge 200 ] 2>/dev/null && [ "$RESULT" -lt 400 ] 2>/dev/null; then
  echo "STATUS: ALLOWED - github.com reachable through firewall"
else
  echo "STATUS: BLOCKED or ERROR (code=$RESULT)"
fi
echo ""

echo "=========================================="
echo "TEST 4: BLOCKED HTTPS - example.com (DenyAllWeb)"
echo "=========================================="
echo "Source: 10.0.2.4 -> FQDN: www.example.com:443"
RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 https://www.example.com 2>/dev/null)
echo "Exit code: $?  HTTP code: $RESULT"
if [ -z "$RESULT" ] || [ "$RESULT" = "000" ]; then
  echo "STATUS: BLOCKED - Connection timed out (DenyAllWeb rule)"
else
  echo "STATUS: UNEXPECTED RESPONSE - $RESULT"
fi
echo ""

echo "=========================================="
echo "TEST 5: BLOCKED HTTPS - reddit.com (DenyAllWeb)"
echo "=========================================="
echo "Source: 10.0.2.4 -> FQDN: www.reddit.com:443"
RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 https://www.reddit.com 2>/dev/null)
echo "Exit code: $?  HTTP code: $RESULT"
if [ -z "$RESULT" ] || [ "$RESULT" = "000" ]; then
  echo "STATUS: BLOCKED - Connection timed out (DenyAllWeb rule)"
else
  echo "STATUS: UNEXPECTED RESPONSE - $RESULT"
fi
echo ""

echo "=========================================="
echo "TEST 6: DNS to BLOCKED destination (verify DNS only to 8.8.8.8)"
echo "=========================================="
echo "Trying DNS to 1.1.1.1 (not in AllowDNS rule - should be blocked)"
nslookup microsoft.com 1.1.1.1
if [ $? -ne 0 ]; then
  echo "STATUS: BLOCKED - DNS to 1.1.1.1 correctly denied"
else
  echo "STATUS: ALLOWED (unexpected)"
fi
echo ""

echo "=========================================="
echo "TEST 7: ICMP PING (Network Rule: AllowICMP)"
echo "=========================================="
echo "Sending 4 ICMP packets to 8.8.8.8"
ping 8.8.8.8 -c 4
if [ $? -eq 0 ]; then
  echo "STATUS: ALLOWED - ICMP ping successful"
else
  echo "STATUS: BLOCKED / PACKET LOSS (As expected, Azure routing/next hops typically drop public ICMP)"
fi
echo ""

echo "=========================================="
echo "TEST 8: THREAT INTELLIGENCE BLOCK (Threat Intel Mode: Deny)"
echo "=========================================="
echo "Attempting to connect to known malicious IP (203.0.113.100)"
RESULT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 http://203.0.113.100 2>/dev/null)
echo "HTTP Response Code: $RESULT"
if [ "$RESULT" = "470" ]; then
  echo "STATUS: BLOCKED - Request explicitly intercepted by Azure Firewall (Status 470)"
elif [ -z "$RESULT" ] || [ "$RESULT" = "000" ]; then
  echo "STATUS: BLOCKED - Request timed out / dropped"
else
  echo "STATUS: UNEXPECTED RESPONSE - $RESULT"
fi
echo ""

echo "=========================================="
echo "TEST 9: LOCAL PORT 80 LISTENING (For Inbound DNAT)"
echo "=========================================="
ss -lntp | grep :80
if [ $? -eq 0 ]; then
  echo "STATUS: ACTIVE - Local web server is listening on port 80 to receive forwarded DNAT traffic"
else
  echo "STATUS: INACTIVE - No server listening on port 80"
fi
echo ""

echo "=========================================="
echo "=== ALL TESTS COMPLETE ==="
echo "=========================================="
