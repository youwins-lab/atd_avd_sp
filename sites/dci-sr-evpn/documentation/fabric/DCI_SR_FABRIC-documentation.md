# DCI_SR_FABRIC

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
| DC1 | l3leaf | eos1 | 192.168.0.10/24 | ceos | Provisioned | - |
| WAN | p | eos2 | 192.168.0.11/24 | ceos | Provisioned | - |
| DC2 | spine | eos3 | 192.168.0.12/24 | ceos | Provisioned | - |
| DC2 | l3leaf | eos4 | 192.168.0.13/24 | ceos | Provisioned | - |
| WAN | rr | eos5 | 192.168.0.14/24 | ceos | Provisioned | - |
| DC1 | spine | eos6 | 192.168.0.15/24 | ceos | Provisioned | - |
| DC2 | l3leaf | eos7 | 192.168.0.16/24 | ceos | Provisioned | - |
| DC1 | l3leaf | eos8 | 192.168.0.17/24 | ceos | Provisioned | - |

> Provision status is based on Ansible inventory declaration and do not represent real status from CloudVision.

### Fabric Switches with inband Management IP

| POD | Type | Node | Management IP | Inband Interface |
| --- | ---- | ---- | ------------- | ---------------- |

## Fabric Topology

| Type | Node | Node Interface | Peer Type | Peer Node | Peer Interface |
| ---- | ---- | -------------- | --------- | --------- | -------------- |
| l3leaf | eos1 | Ethernet1 | p | eos2 | Ethernet5 |
| l3leaf | eos1 | Ethernet4 | spine | eos6 | Ethernet4 |
| l3leaf | eos1 | Ethernet5 | rr | eos5 | Ethernet4 |
| p | eos2 | Ethernet2 | l3leaf | eos4 | Ethernet4 |
| p | eos2 | Ethernet3 | rr | eos5 | Ethernet3 |
| spine | eos3 | Ethernet2 | l3leaf | eos7 | Ethernet1 |
| spine | eos3 | Ethernet5 | l3leaf | eos4 | Ethernet5 |
| l3leaf | eos4 | Ethernet3 | rr | eos5 | Ethernet1 |
| spine | eos6 | Ethernet2 | l3leaf | eos8 | Ethernet3 |

## Fabric IP Allocation

### Fabric Point-To-Point Links

| Uplink IPv4 Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ---------------- | ------------------- | ------------------ | ------------------ |
| 10.101.0.0/24 | 256 | 4 | 1.57 % |
| 10.102.0.0/24 | 256 | 4 | 1.57 % |

### Point-To-Point Links Node Allocation

| Node | Node Interface | Node IP Address | Peer Node | Peer Interface | Peer IP Address |
| ---- | -------------- | --------------- | --------- | -------------- | --------------- |
| eos1 | Ethernet1 | 10.1.2.1/24 | eos2 | Ethernet5 | 10.1.2.2/24 |
| eos1 | Ethernet4 | 10.101.0.19/31 | eos6 | Ethernet4 | 10.101.0.18/31 |
| eos1 | Ethernet5 | 10.1.5.1/24 | eos5 | Ethernet4 | 10.1.5.5/24 |
| eos2 | Ethernet2 | 10.2.4.2/24 | eos4 | Ethernet4 | 10.2.4.4/24 |
| eos2 | Ethernet3 | 10.2.5.2/24 | eos5 | Ethernet3 | 10.2.5.5/24 |
| eos3 | Ethernet2 | 10.102.0.30/31 | eos7 | Ethernet1 | 10.102.0.31/31 |
| eos3 | Ethernet5 | 10.102.0.24/31 | eos4 | Ethernet5 | 10.102.0.25/31 |
| eos4 | Ethernet3 | 10.4.5.4/24 | eos5 | Ethernet1 | 10.4.5.5/24 |
| eos6 | Ethernet2 | 10.101.0.32/31 | eos8 | Ethernet3 | 10.101.0.33/31 |

### Loopback Interfaces (BGP EVPN Peering)

| Loopback Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ------------- | ------------------- | ------------------ | ------------------ |
| 192.168.255.0/24 | 256 | 8 | 3.13 % |

### Loopback0 Interfaces Node Allocation

| POD | Node | Loopback0 |
| --- | ---- | --------- |
| DC1 | eos1 | 192.168.255.10/32 |
| WAN | eos2 | 192.168.255.11/32 |
| DC2 | eos3 | 192.168.255.12/32 |
| DC2 | eos4 | 192.168.255.13/32 |
| WAN | eos5 | 192.168.255.14/32 |
| DC1 | eos6 | 192.168.255.15/32 |
| DC2 | eos7 | 192.168.255.16/32 |
| DC1 | eos8 | 192.168.255.17/32 |

### ISIS CLNS interfaces

| POD | Node | CLNS Address |
| --- | ---- | ------------ |
| DC1 | eos1 | 49.0001.1921.6825.5010.00 |
| WAN | eos2 | 49.0001.1921.6825.5011.00 |
| DC2 | eos4 | 49.0001.1921.6825.5013.00 |
| WAN | eos5 | 49.0001.1921.6825.5014.00 |

### VTEP Loopback VXLAN Tunnel Source Interfaces (VTEPs Only)

| VTEP Loopback Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ------------------ | ------------------- | ------------------ | ------------------ |
| 10.255.1.0/24 | 256 | 4 | 1.57 % |

### VTEP Loopback Node allocation

| POD | Node | Loopback1 |
| --- | ---- | --------- |
| DC1 | eos1 | 10.255.1.10/32 |
| DC2 | eos4 | 10.255.1.13/32 |
| DC2 | eos7 | 10.255.1.16/32 |
| DC1 | eos8 | 10.255.1.17/32 |
