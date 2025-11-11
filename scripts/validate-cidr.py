#!/usr/bin/env python3
"""
CIDR Overlap Validation Script
Validates that CIDR ranges for Canada Central don't overlap
"""

import ipaddress
import sys
from typing import List, Tuple

# Canada Central CIDR Allocations
CIDR_RANGES = {
    "canada_central": {
        "hub_vnet": "10.0.0.0/16",
        "spoke_vnet": "10.1.0.0/16",
        "service_cidr": "10.100.0.0/16",
        "pod_cidr": "10.244.0.0/16"
    }
}

def check_overlap(cidr1: str, cidr2: str) -> bool:
    """Check if two CIDR ranges overlap"""
    net1 = ipaddress.ip_network(cidr1)
    net2 = ipaddress.ip_network(cidr2)
    return net1.overlaps(net2)

def validate_cidrs() -> Tuple[bool, List[str]]:
    """Validate all CIDR ranges for overlaps"""
    errors = []
    all_cidrs = []
    
    # Flatten all CIDRs with metadata
    for region, ranges in CIDR_RANGES.items():
        for network_type, cidr in ranges.items():
            all_cidrs.append((region, network_type, cidr))
    
    # Check each pair for overlaps
    for i, (region1, type1, cidr1) in enumerate(all_cidrs):
        for region2, type2, cidr2 in all_cidrs[i+1:]:
            if check_overlap(cidr1, cidr2):
                errors.append(
                    f"❌ OVERLAP: {region1}/{type1} ({cidr1}) "
                    f"overlaps with {region2}/{type2} ({cidr2})"
                )
    
    return len(errors) == 0, errors

def print_cidr_table():
    """Print formatted CIDR allocation table"""
    print("\n" + "="*80)
    print("Canada Central - CIDR Allocation Table".center(80))
    print("="*80)
    print(f"{'Network Type':<20} {'CIDR Range':<20}")
    print("-"*80)

    ranges = CIDR_RANGES["canada_central"]
    print(f"{'Hub VNet':<20} {ranges['hub_vnet']:<20}")
    print(f"{'Spoke VNet':<20} {ranges['spoke_vnet']:<20}")
    print(f"{'Service CIDR':<20} {ranges['service_cidr']:<20}")
    print(f"{'Pod CIDR':<20} {ranges['pod_cidr']:<20}")
    print("="*80 + "\n")

def main():
    """Main validation logic"""
    print_cidr_table()

    print("🔍 Validating CIDR ranges for overlaps...\n")

    is_valid, errors = validate_cidrs()

    if is_valid:
        print("✅ SUCCESS: No CIDR overlaps detected!")
        print("   All networks are properly isolated.\n")
        sys.exit(0)
    else:
        print("❌ FAILED: CIDR overlaps detected!\n")
        for error in errors:
            print(f"   {error}")
        print("\n⚠️  Fix these overlaps before deploying infrastructure.\n")
        sys.exit(1)

if __name__ == "__main__":
    main()