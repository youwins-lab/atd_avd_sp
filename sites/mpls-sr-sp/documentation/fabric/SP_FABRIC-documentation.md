# SP_FABRIC

## Table of Contents

- [Fabric Switches and Management IP](#fabric-switches-and-management-ip)
  - [Fabric Switches with inband Management IP](#fabric-switches-with-inband-management-ip)
- [Fabric Topology](#fabric-topology)
- [Fabric IP Allocation](#fabric-ip-allocation)
  - [Fabric Point-To-Point Links](#fabric-point-to-point-links)
  - [Point-To-Point Links Node Allocation](#point-to-point-links-node-allocation)
  - [Loopback Interfaces (BGP EVPN Peering)](#loopback-interfaces-bgp-evpn-peering)
  - [Loopback0 Interfaces Node Allocation](#loopback0-interfaces-node-allocation)
  - [ISIS CLNS interfaces](#isis-clns-interfaces)
  - [VTEP Loopback VXLAN Tunnel Source Interfaces (VTEPs Only)](#vtep-loopback-vxlan-tunnel-source-interfaces-vteps-only)
  - [VTEP Loopback Node allocation](#vtep-loopback-node-allocation)

## Fabric Switches and Management IP

| POD | Type | Node | Management IP | Platform | Provisioned in CloudVision | Serial Number |
| --- | ---- | ---- | ------------- | -------- | -------------------------- | ------------- |
| SP_FABRIC | pe | eos1 | 192.168.0.10/24 | ceos | Provisioned | - |
| SP_FABRIC | rr | eos2 | 192.168.0.11/24 | ceos | Provisioned | - |
| SP_FABRIC | pe | eos3 | 192.168.0.12/24 | ceos | Provisioned | - |
| SP_FABRIC | pe | eos4 | 192.168.0.13/24 | ceos | Provisioned | - |
| SP_FABRIC | rr | eos5 | 192.168.0.14/24 | ceos | Provisioned | - |
| SP_FABRIC | pe | eos6 | 192.168.0.15/24 | ceos | Provisioned | - |
| SP_FABRIC | pe | eos7 | 192.168.0.16/24 | ceos | Provisioned | - |
| SP_FABRIC | pe | eos8 | 192.168.0.17/24 | ceos | Provisioned | - |

> Provision status is based on Ansible inventory declaration and do not represent real status from CloudVision.

### Fabric Switches with inband Management IP

| POD | Type | Node | Management IP | Inband Interface |
| --- | ---- | ---- | ------------- | ---------------- |

## Fabric Topology

| Type | Node | Node Interface | Peer Type | Peer Node | Peer Interface |
| ---- | ---- | -------------- | --------- | --------- | -------------- |
| pe | eos1 | Ethernet1 | rr | eos2 | Ethernet5 |
| pe | eos1 | Ethernet2 | pe | eos7 | Ethernet3 |
| pe | eos1 | Ethernet4 | pe | eos6 | Ethernet4 |
| pe | eos1 | Ethernet5 | rr | eos5 | Ethernet4 |
| rr | eos2 | Ethernet1 | pe | eos3 | Ethernet3 |
| rr | eos2 | Ethernet2 | pe | eos4 | Ethernet4 |
| rr | eos2 | Ethernet3 | rr | eos5 | Ethernet3 |
| rr | eos2 | Ethernet4 | pe | eos6 | Ethernet5 |
| pe | eos3 | Ethernet2 | pe | eos7 | Ethernet1 |
| pe | eos3 | Ethernet4 | rr | eos5 | Ethernet2 |
| pe | eos3 | Ethernet5 | pe | eos4 | Ethernet5 |
| pe | eos4 | Ethernet2 | pe | eos8 | Ethernet1 |
| pe | eos4 | Ethernet3 | rr | eos5 | Ethernet1 |
| rr | eos5 | Ethernet5 | pe | eos6 | Ethernet1 |
| pe | eos6 | Ethernet2 | pe | eos8 | Ethernet3 |

## Fabric IP Allocation

### Fabric Point-To-Point Links

| Uplink IPv4 Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ---------------- | ------------------- | ------------------ | ------------------ |

### Point-To-Point Links Node Allocation

| Node | Node Interface | Node IP Address | Peer Node | Peer Interface | Peer IP Address |
| ---- | -------------- | --------------- | --------- | -------------- | --------------- |
| eos1 | Ethernet1 | 10.1.2.1/24 | eos2 | Ethernet5 | 10.1.2.2/24 |
| eos1 | Ethernet2 | 10.1.7.1/24 | eos7 | Ethernet3 | 10.1.7.7/24 |
| eos1 | Ethernet4 | 10.1.6.1/24 | eos6 | Ethernet4 | 10.1.6.6/24 |
| eos1 | Ethernet5 | 10.1.5.1/24 | eos5 | Ethernet4 | 10.1.5.5/24 |
| eos2 | Ethernet1 | 10.2.3.2/24 | eos3 | Ethernet3 | 10.2.3.3/24 |
| eos2 | Ethernet2 | 10.2.4.2/24 | eos4 | Ethernet4 | 10.2.4.4/24 |
| eos2 | Ethernet3 | 10.2.5.2/24 | eos5 | Ethernet3 | 10.2.5.5/24 |
| eos2 | Ethernet4 | 10.2.6.2/24 | eos6 | Ethernet5 | 10.2.6.6/24 |
| eos3 | Ethernet2 | 10.3.7.3/24 | eos7 | Ethernet1 | 10.3.7.7/24 |
| eos3 | Ethernet4 | 10.3.5.3/24 | eos5 | Ethernet2 | 10.3.5.5/24 |
| eos3 | Ethernet5 | 10.3.4.3/24 | eos4 | Ethernet5 | 10.3.4.4/24 |
| eos4 | Ethernet2 | 10.4.8.4/24 | eos8 | Ethernet1 | 10.4.8.8/24 |
| eos4 | Ethernet3 | 10.4.5.4/24 | eos5 | Ethernet1 | 10.4.5.5/24 |
| eos5 | Ethernet5 | 10.5.6.5/24 | eos6 | Ethernet1 | 10.5.6.6/24 |
| eos6 | Ethernet2 | 10.6.8.6/24 | eos8 | Ethernet3 | 10.6.8.8/24 |

### Loopback Interfaces (BGP EVPN Peering)

| Loopback Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ------------- | ------------------- | ------------------ | ------------------ |
| 10.255.255.0/24 | 256 | 0 | 0.0 % |

### Loopback0 Interfaces Node Allocation

| POD | Node | Loopback0 |
| --- | ---- | --------- |
| SP_FABRIC | eos1 | 1.1.1.1/32 |
| SP_FABRIC | eos2 | 2.2.2.2/32 |
| SP_FABRIC | eos3 | 3.3.3.3/32 |
| SP_FABRIC | eos4 | 4.4.4.4/32 |
| SP_FABRIC | eos5 | 5.5.5.5/32 |
| SP_FABRIC | eos6 | 6.6.6.6/32 |
| SP_FABRIC | eos7 | 7.7.7.7/32 |
| SP_FABRIC | eos8 | 8.8.8.8/32 |

### ISIS CLNS interfaces

| POD | Node | CLNS Address |
| --- | ---- | ------------ |
| SP_FABRIC | eos1 | 49.0001.0010.0100.1001.00 |
| SP_FABRIC | eos2 | 49.0001.0020.0200.2002.00 |
| SP_FABRIC | eos3 | 49.0001.0030.0300.3003.00 |
| SP_FABRIC | eos4 | 49.0001.0040.0400.4004.00 |
| SP_FABRIC | eos5 | 49.0001.0050.0500.5005.00 |
| SP_FABRIC | eos6 | 49.0001.0060.0600.6006.00 |
| SP_FABRIC | eos7 | 49.0001.0070.0700.7007.00 |
| SP_FABRIC | eos8 | 49.0001.0080.0800.8008.00 |

### VTEP Loopback VXLAN Tunnel Source Interfaces (VTEPs Only)

| VTEP Loopback Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ------------------ | ------------------- | ------------------ | ------------------ |

### VTEP Loopback Node allocation

| POD | Node | Loopback1 |
| --- | ---- | --------- |
