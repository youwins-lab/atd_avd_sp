# MPLS_SR_DCI_FABRIC

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
| DC1 | l3leaf | s1-brdr1 | 192.168.0.100/24 | ceos | Provisioned | - |
| DC1 | l3leaf | s1-brdr2 | 192.168.0.101/24 | ceos | Provisioned | - |
| DCI | rr | s1-core1 | 192.168.0.102/24 | ceos | Provisioned | - |
| DCI | pe | s1-core2 | 192.168.0.103/24 | ceos | Provisioned | - |
| DC1 | l3leaf | s1-leaf1 | 192.168.0.12/24 | ceos | Provisioned | - |
| DC1 | l3leaf | s1-leaf2 | 192.168.0.13/24 | ceos | Provisioned | - |
| DC1 | l3leaf | s1-leaf3 | 192.168.0.14/24 | ceos | Provisioned | - |
| DC1 | l3leaf | s1-leaf4 | 192.168.0.15/24 | ceos | Provisioned | - |
| DC1 | spine | s1-spine1 | 192.168.0.10/24 | ceos | Provisioned | - |
| DC1 | spine | s1-spine2 | 192.168.0.11/24 | ceos | Provisioned | - |
| DC2 | l3leaf | s2-brdr1 | 192.168.0.200/24 | ceos | Provisioned | - |
| DC2 | l3leaf | s2-brdr2 | 192.168.0.201/24 | ceos | Provisioned | - |
| DCI | rr | s2-core1 | 192.168.0.202/24 | ceos | Provisioned | - |
| DCI | pe | s2-core2 | 192.168.0.203/24 | ceos | Provisioned | - |
| DC2 | l3leaf | s2-leaf1 | 192.168.0.22/24 | ceos | Provisioned | - |
| DC2 | l3leaf | s2-leaf2 | 192.168.0.23/24 | ceos | Provisioned | - |
| DC2 | l3leaf | s2-leaf3 | 192.168.0.24/24 | ceos | Provisioned | - |
| DC2 | l3leaf | s2-leaf4 | 192.168.0.25/24 | ceos | Provisioned | - |
| DC2 | spine | s2-spine1 | 192.168.0.20/24 | ceos | Provisioned | - |
| DC2 | spine | s2-spine2 | 192.168.0.21/24 | ceos | Provisioned | - |

> Provision status is based on Ansible inventory declaration and do not represent real status from CloudVision.

### Fabric Switches with inband Management IP

| POD | Type | Node | Management IP | Inband Interface |
| --- | ---- | ---- | ------------- | ---------------- |

## Fabric Topology

| Type | Node | Node Interface | Peer Type | Peer Node | Peer Interface |
| ---- | ---- | -------------- | --------- | --------- | -------------- |
| l3leaf | s1-brdr1 | Ethernet1 | mlag_peer | s1-brdr2 | Ethernet1 |
| l3leaf | s1-brdr1 | Ethernet2 | spine | s1-spine1 | Ethernet7 |
| l3leaf | s1-brdr1 | Ethernet3 | spine | s1-spine2 | Ethernet7 |
| l3leaf | s1-brdr1 | Ethernet4 | rr | s1-core1 | Ethernet2 |
| l3leaf | s1-brdr1 | Ethernet5 | pe | s1-core2 | Ethernet2 |
| l3leaf | s1-brdr1 | Ethernet6 | mlag_peer | s1-brdr2 | Ethernet6 |
| l3leaf | s1-brdr2 | Ethernet2 | spine | s1-spine1 | Ethernet8 |
| l3leaf | s1-brdr2 | Ethernet3 | spine | s1-spine2 | Ethernet8 |
| l3leaf | s1-brdr2 | Ethernet4 | rr | s1-core1 | Ethernet3 |
| l3leaf | s1-brdr2 | Ethernet5 | pe | s1-core2 | Ethernet3 |
| rr | s1-core1 | Ethernet1 | pe | s1-core2 | Ethernet1 |
| rr | s1-core1 | Ethernet4 | rr | s2-core1 | Ethernet4 |
| rr | s1-core1 | Ethernet6 | pe | s1-core2 | Ethernet6 |
| pe | s1-core2 | Ethernet4 | pe | s2-core2 | Ethernet4 |
| l3leaf | s1-leaf1 | Ethernet1 | mlag_peer | s1-leaf2 | Ethernet1 |
| l3leaf | s1-leaf1 | Ethernet2 | spine | s1-spine1 | Ethernet2 |
| l3leaf | s1-leaf1 | Ethernet3 | spine | s1-spine2 | Ethernet2 |
| l3leaf | s1-leaf1 | Ethernet6 | mlag_peer | s1-leaf2 | Ethernet6 |
| l3leaf | s1-leaf2 | Ethernet2 | spine | s1-spine1 | Ethernet3 |
| l3leaf | s1-leaf2 | Ethernet3 | spine | s1-spine2 | Ethernet3 |
| l3leaf | s1-leaf3 | Ethernet1 | mlag_peer | s1-leaf4 | Ethernet1 |
| l3leaf | s1-leaf3 | Ethernet2 | spine | s1-spine1 | Ethernet4 |
| l3leaf | s1-leaf3 | Ethernet3 | spine | s1-spine2 | Ethernet4 |
| l3leaf | s1-leaf3 | Ethernet6 | mlag_peer | s1-leaf4 | Ethernet6 |
| l3leaf | s1-leaf4 | Ethernet2 | spine | s1-spine1 | Ethernet5 |
| l3leaf | s1-leaf4 | Ethernet3 | spine | s1-spine2 | Ethernet5 |
| l3leaf | s2-brdr1 | Ethernet1 | mlag_peer | s2-brdr2 | Ethernet1 |
| l3leaf | s2-brdr1 | Ethernet2 | spine | s2-spine1 | Ethernet7 |
| l3leaf | s2-brdr1 | Ethernet3 | spine | s2-spine2 | Ethernet7 |
| l3leaf | s2-brdr1 | Ethernet4 | rr | s2-core1 | Ethernet2 |
| l3leaf | s2-brdr1 | Ethernet5 | pe | s2-core2 | Ethernet2 |
| l3leaf | s2-brdr1 | Ethernet6 | mlag_peer | s2-brdr2 | Ethernet6 |
| l3leaf | s2-brdr2 | Ethernet2 | spine | s2-spine1 | Ethernet8 |
| l3leaf | s2-brdr2 | Ethernet3 | spine | s2-spine2 | Ethernet8 |
| l3leaf | s2-brdr2 | Ethernet4 | rr | s2-core1 | Ethernet3 |
| l3leaf | s2-brdr2 | Ethernet5 | pe | s2-core2 | Ethernet3 |
| rr | s2-core1 | Ethernet1 | pe | s2-core2 | Ethernet1 |
| rr | s2-core1 | Ethernet6 | pe | s2-core2 | Ethernet6 |
| l3leaf | s2-leaf1 | Ethernet1 | mlag_peer | s2-leaf2 | Ethernet1 |
| l3leaf | s2-leaf1 | Ethernet2 | spine | s2-spine1 | Ethernet2 |
| l3leaf | s2-leaf1 | Ethernet3 | spine | s2-spine2 | Ethernet2 |
| l3leaf | s2-leaf1 | Ethernet6 | mlag_peer | s2-leaf2 | Ethernet6 |
| l3leaf | s2-leaf2 | Ethernet2 | spine | s2-spine1 | Ethernet3 |
| l3leaf | s2-leaf2 | Ethernet3 | spine | s2-spine2 | Ethernet3 |
| l3leaf | s2-leaf3 | Ethernet1 | mlag_peer | s2-leaf4 | Ethernet1 |
| l3leaf | s2-leaf3 | Ethernet2 | spine | s2-spine1 | Ethernet4 |
| l3leaf | s2-leaf3 | Ethernet3 | spine | s2-spine2 | Ethernet4 |
| l3leaf | s2-leaf3 | Ethernet6 | mlag_peer | s2-leaf4 | Ethernet6 |
| l3leaf | s2-leaf4 | Ethernet2 | spine | s2-spine1 | Ethernet5 |
| l3leaf | s2-leaf4 | Ethernet3 | spine | s2-spine2 | Ethernet5 |

## Fabric IP Allocation

### Fabric Point-To-Point Links

| Uplink IPv4 Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ---------------- | ------------------- | ------------------ | ------------------ |
| 10.101.0.0/22 | 1024 | 24 | 2.35 % |
| 10.102.0.0/22 | 1024 | 24 | 2.35 % |

### Point-To-Point Links Node Allocation

| Node | Node Interface | Node IP Address | Peer Node | Peer Interface | Peer IP Address |
| ---- | -------------- | --------------- | --------- | -------------- | --------------- |
| s1-brdr1 | Ethernet2 | 10.101.1.141/31 | s1-spine1 | Ethernet7 | 10.101.1.140/31 |
| s1-brdr1 | Ethernet3 | 10.101.1.143/31 | s1-spine2 | Ethernet7 | 10.101.1.142/31 |
| s1-brdr1 | Ethernet4 | 172.16.1.0/31 | s1-core1 | Ethernet2 | 172.16.1.1/31 |
| s1-brdr1 | Ethernet5 | 172.16.1.2/31 | s1-core2 | Ethernet2 | 172.16.1.3/31 |
| s1-brdr2 | Ethernet2 | 10.101.1.145/31 | s1-spine1 | Ethernet8 | 10.101.1.144/31 |
| s1-brdr2 | Ethernet3 | 10.101.1.147/31 | s1-spine2 | Ethernet8 | 10.101.1.146/31 |
| s1-brdr2 | Ethernet4 | 172.16.1.4/31 | s1-core1 | Ethernet3 | 172.16.1.5/31 |
| s1-brdr2 | Ethernet5 | 172.16.1.6/31 | s1-core2 | Ethernet3 | 172.16.1.7/31 |
| s1-core1 | Ethernet1 | 10.0.0.0/31 | s1-core2 | Ethernet1 | 10.0.0.1/31 |
| s1-core1 | Ethernet4 | 10.0.0.8/31 | s2-core1 | Ethernet4 | 10.0.0.9/31 |
| s1-core1 | Ethernet6 | 10.0.0.2/31 | s1-core2 | Ethernet6 | 10.0.0.3/31 |
| s1-core2 | Ethernet4 | 10.0.0.10/31 | s2-core2 | Ethernet4 | 10.0.0.11/31 |
| s1-leaf1 | Ethernet2 | 10.101.0.45/31 | s1-spine1 | Ethernet2 | 10.101.0.44/31 |
| s1-leaf1 | Ethernet3 | 10.101.0.47/31 | s1-spine2 | Ethernet2 | 10.101.0.46/31 |
| s1-leaf2 | Ethernet2 | 10.101.0.49/31 | s1-spine1 | Ethernet3 | 10.101.0.48/31 |
| s1-leaf2 | Ethernet3 | 10.101.0.51/31 | s1-spine2 | Ethernet3 | 10.101.0.50/31 |
| s1-leaf3 | Ethernet2 | 10.101.0.53/31 | s1-spine1 | Ethernet4 | 10.101.0.52/31 |
| s1-leaf3 | Ethernet3 | 10.101.0.55/31 | s1-spine2 | Ethernet4 | 10.101.0.54/31 |
| s1-leaf4 | Ethernet2 | 10.101.0.57/31 | s1-spine1 | Ethernet5 | 10.101.0.56/31 |
| s1-leaf4 | Ethernet3 | 10.101.0.59/31 | s1-spine2 | Ethernet5 | 10.101.0.58/31 |
| s2-brdr1 | Ethernet2 | 10.102.3.29/31 | s2-spine1 | Ethernet7 | 10.102.3.28/31 |
| s2-brdr1 | Ethernet3 | 10.102.3.31/31 | s2-spine2 | Ethernet7 | 10.102.3.30/31 |
| s2-brdr1 | Ethernet4 | 172.16.2.0/31 | s2-core1 | Ethernet2 | 172.16.2.1/31 |
| s2-brdr1 | Ethernet5 | 172.16.2.2/31 | s2-core2 | Ethernet2 | 172.16.2.3/31 |
| s2-brdr2 | Ethernet2 | 10.102.3.33/31 | s2-spine1 | Ethernet8 | 10.102.3.32/31 |
| s2-brdr2 | Ethernet3 | 10.102.3.35/31 | s2-spine2 | Ethernet8 | 10.102.3.34/31 |
| s2-brdr2 | Ethernet4 | 172.16.2.4/31 | s2-core1 | Ethernet3 | 172.16.2.5/31 |
| s2-brdr2 | Ethernet5 | 172.16.2.6/31 | s2-core2 | Ethernet3 | 172.16.2.7/31 |
| s2-core1 | Ethernet1 | 10.0.0.4/31 | s2-core2 | Ethernet1 | 10.0.0.5/31 |
| s2-core1 | Ethernet6 | 10.0.0.6/31 | s2-core2 | Ethernet6 | 10.0.0.7/31 |
| s2-leaf1 | Ethernet2 | 10.102.0.85/31 | s2-spine1 | Ethernet2 | 10.102.0.84/31 |
| s2-leaf1 | Ethernet3 | 10.102.0.87/31 | s2-spine2 | Ethernet2 | 10.102.0.86/31 |
| s2-leaf2 | Ethernet2 | 10.102.0.89/31 | s2-spine1 | Ethernet3 | 10.102.0.88/31 |
| s2-leaf2 | Ethernet3 | 10.102.0.91/31 | s2-spine2 | Ethernet3 | 10.102.0.90/31 |
| s2-leaf3 | Ethernet2 | 10.102.0.93/31 | s2-spine1 | Ethernet4 | 10.102.0.92/31 |
| s2-leaf3 | Ethernet3 | 10.102.0.95/31 | s2-spine2 | Ethernet4 | 10.102.0.94/31 |
| s2-leaf4 | Ethernet2 | 10.102.0.97/31 | s2-spine1 | Ethernet5 | 10.102.0.96/31 |
| s2-leaf4 | Ethernet3 | 10.102.0.99/31 | s2-spine2 | Ethernet5 | 10.102.0.98/31 |

### Loopback Interfaces (BGP EVPN Peering)

| Loopback Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ------------- | ------------------- | ------------------ | ------------------ |
| 192.168.255.0/24 | 256 | 20 | 7.82 % |

### Loopback0 Interfaces Node Allocation

| POD | Node | Loopback0 |
| --- | ---- | --------- |
| DC1 | s1-brdr1 | 192.168.255.100/32 |
| DC1 | s1-brdr2 | 192.168.255.101/32 |
| DCI | s1-core1 | 192.168.255.102/32 |
| DCI | s1-core2 | 192.168.255.103/32 |
| DC1 | s1-leaf1 | 192.168.255.12/32 |
| DC1 | s1-leaf2 | 192.168.255.13/32 |
| DC1 | s1-leaf3 | 192.168.255.14/32 |
| DC1 | s1-leaf4 | 192.168.255.15/32 |
| DC1 | s1-spine1 | 192.168.255.10/32 |
| DC1 | s1-spine2 | 192.168.255.11/32 |
| DC2 | s2-brdr1 | 192.168.255.200/32 |
| DC2 | s2-brdr2 | 192.168.255.201/32 |
| DCI | s2-core1 | 192.168.255.202/32 |
| DCI | s2-core2 | 192.168.255.203/32 |
| DC2 | s2-leaf1 | 192.168.255.22/32 |
| DC2 | s2-leaf2 | 192.168.255.23/32 |
| DC2 | s2-leaf3 | 192.168.255.24/32 |
| DC2 | s2-leaf4 | 192.168.255.25/32 |
| DC2 | s2-spine1 | 192.168.255.20/32 |
| DC2 | s2-spine2 | 192.168.255.21/32 |

### ISIS CLNS interfaces

| POD | Node | CLNS Address |
| --- | ---- | ------------ |
| DCI | s1-core1 | 49.0001.1921.6825.5102.00 |
| DCI | s1-core2 | 49.0001.1921.6825.5103.00 |
| DCI | s2-core1 | 49.0001.1921.6825.5202.00 |
| DCI | s2-core2 | 49.0001.1921.6825.5203.00 |

### VTEP Loopback VXLAN Tunnel Source Interfaces (VTEPs Only)

| VTEP Loopback Pool | Available Addresses | Assigned addresses | Assigned Address % |
| ------------------ | ------------------- | ------------------ | ------------------ |
| 192.168.254.0/24 | 256 | 12 | 4.69 % |

### VTEP Loopback Node allocation

| POD | Node | Loopback1 |
| --- | ---- | --------- |
| DC1 | s1-brdr1 | 192.168.254.100/32 |
| DC1 | s1-brdr2 | 192.168.254.100/32 |
| DC1 | s1-leaf1 | 192.168.254.12/32 |
| DC1 | s1-leaf2 | 192.168.254.12/32 |
| DC1 | s1-leaf3 | 192.168.254.14/32 |
| DC1 | s1-leaf4 | 192.168.254.14/32 |
| DC2 | s2-brdr1 | 192.168.254.200/32 |
| DC2 | s2-brdr2 | 192.168.254.200/32 |
| DC2 | s2-leaf1 | 192.168.254.22/32 |
| DC2 | s2-leaf2 | 192.168.254.22/32 |
| DC2 | s2-leaf3 | 192.168.254.24/32 |
| DC2 | s2-leaf4 | 192.168.254.24/32 |
