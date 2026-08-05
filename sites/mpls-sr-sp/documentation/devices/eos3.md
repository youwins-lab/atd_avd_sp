# eos3

## Table of Contents

- [Management](#management)
  - [Management Interfaces](#management-interfaces)
  - [Management API HTTP](#management-api-http)
- [Authentication](#authentication)
  - [Enable Password](#enable-password)
- [Spanning Tree](#spanning-tree)
  - [Spanning Tree Summary](#spanning-tree-summary)
  - [Spanning Tree Device Configuration](#spanning-tree-device-configuration)
- [Internal VLAN Allocation Policy](#internal-vlan-allocation-policy)
  - [Internal VLAN Allocation Policy Summary](#internal-vlan-allocation-policy-summary)
  - [Internal VLAN Allocation Policy Device Configuration](#internal-vlan-allocation-policy-device-configuration)
- [VLANs](#vlans)
  - [VLANs Summary](#vlans-summary)
  - [VLANs Device Configuration](#vlans-device-configuration)
- [Interfaces](#interfaces)
  - [Ethernet Interfaces](#ethernet-interfaces)
  - [Port-Channel Interfaces](#port-channel-interfaces)
  - [Loopback Interfaces](#loopback-interfaces)
- [Routing](#routing)
  - [Service Routing Protocols Model](#service-routing-protocols-model)
  - [IP Routing](#ip-routing)
  - [IPv6 Routing](#ipv6-routing)
  - [Static Routes](#static-routes)
  - [Router ISIS](#router-isis)
  - [Router BGP](#router-bgp)
- [BFD](#bfd)
  - [Router BFD](#router-bfd)
- [MPLS](#mpls)
  - [MPLS and LDP](#mpls-and-ldp)
  - [MPLS Interfaces](#mpls-interfaces)
  - [MPLS Device Configuration](#mpls-device-configuration)
- [Multicast](#multicast)
  - [IP IGMP Snooping](#ip-igmp-snooping)
- [VRF Instances](#vrf-instances)
  - [VRF Instances Summary](#vrf-instances-summary)
  - [VRF Instances Device Configuration](#vrf-instances-device-configuration)

## Management

### Management Interfaces

#### Management Interfaces Summary

##### IPv4

| Management Interface | Description | Type | VRF | IP Address | Gateway |
| -------------------- | ----------- | ---- | --- | ---------- | ------- |
| Management0 | OOB_MANAGEMENT | oob | default | 192.168.0.12/24 | 192.168.0.1 |

##### IPv6

| Management Interface | Description | Type | VRF | IPv6 Address | IPv6 Gateway | ND RA Disabled | ND RA RX Accept | ND Managed Config Flag | ND Other Config Flag | ND Cache | ND RA DNS Servers |
| -------------------- | ----------- | ---- | --- | ------------ | ------------ | -------------- | --------------- | ---------------------- | -------------------- | -------- | ----------------- |
| Management0 | OOB_MANAGEMENT | oob | default | - | - | - | - | - | - | - | - |

#### Management Interfaces Device Configuration

```eos
!
interface Management0
   description OOB_MANAGEMENT
   no shutdown
   ip address 192.168.0.12/24
```

### Management API HTTP

#### Management API HTTP Summary

| HTTP | HTTPS | UNIX-Socket | Default Services | Session Timeout |
| ---- | ----- | ----------- | ---------------- | --------------- |
| False | True | - | - | 1440 minutes |

#### Management API VRF Access

| VRF Name | IPv4 ACL | IPv6 ACL |
| -------- | -------- | -------- |
| default | - | - |

#### Management API HTTP Device Configuration

```eos
!
management api http-commands
   protocol https
   no shutdown
   !
   vrf default
      no shutdown
```

## Authentication

### Enable Password

Enable password has been disabled

## Spanning Tree

### Spanning Tree Summary

STP mode: **none**

### Spanning Tree Device Configuration

```eos
!
spanning-tree mode none
```

## Internal VLAN Allocation Policy

### Internal VLAN Allocation Policy Summary

| Policy Allocation | Range Beginning | Range Ending |
| ----------------- | --------------- | ------------ |
| ascending | 1006 | 1199 |

### Internal VLAN Allocation Policy Device Configuration

```eos
!
vlan internal order ascending range 1006 1199
```

## VLANs

### VLANs Summary

| VLAN ID | Name | Trunk Groups |
| ------- | ---- | ------------ |
| 100 | CUST2-L2VPN | - |

### VLANs Device Configuration

```eos
!
vlan 100
   name CUST2-L2VPN
```

## Interfaces

### Ethernet Interfaces

#### Ethernet Interfaces Summary

##### L2

| Interface | Description | Mode | VLANs | Native VLAN | Trunk Group | Channel-Group |
| --------- | ----------- | ---- | ----- | ----------- | ----------- | ------------- |
| Ethernet1 | CUST2_eos9 | *access | *100 | *- | *- | 1 |

*Inherited from Port-Channel Interface

##### IPv4

| Interface | Description | Channel Group | IP Address | VRF | MTU | Shutdown | ACL In | ACL Out |
| --------- | ----------- | ------------- | ---------- | --- | --- | -------- | ------ | ------- |
| Ethernet2 | P2P_eos7_Ethernet1 | - | 10.3.7.3/24 | default | 9214 | False | - | - |
| Ethernet3 | P2P_eos2_Ethernet1 | - | 10.2.3.3/24 | default | 9214 | False | - | - |
| Ethernet4 | P2P_eos5_Ethernet2 | - | 10.3.5.3/24 | default | 9214 | False | - | - |
| Ethernet5 | P2P_eos4_Ethernet5 | - | 10.3.4.3/24 | default | 9214 | False | - | - |
| Ethernet6 | CENTRAL_eos20 | - | 10.3.20.3/24 | CENTRAL | 9214 | False | - | - |

##### ISIS

| Interface | Channel Group | ISIS Instance | ISIS BFD | ISIS Metric | Mode | ISIS Circuit Type | Hello Padding | ISIS Authentication Mode |
| --------- | ------------- | ------------- | -------- | ----------- | ---- | ----------------- | ------------- | ------------------------ |
| Ethernet2 | - | CORE | - | 10 | point-to-point | level-2 | True | - |
| Ethernet3 | - | CORE | - | 10 | point-to-point | level-2 | True | - |
| Ethernet4 | - | CORE | - | 10 | point-to-point | level-2 | True | - |
| Ethernet5 | - | CORE | - | 10 | point-to-point | level-2 | True | - |

#### Ethernet Interfaces Device Configuration

```eos
!
interface Ethernet1
   description CUST2_eos9
   no shutdown
   channel-group 1 mode active
!
interface Ethernet2
   description P2P_eos7_Ethernet1
   no shutdown
   mtu 9214
   no switchport
   ip address 10.3.7.3/24
   mpls ip
   isis enable CORE
   isis circuit-type level-2
   isis metric 10
   isis hello padding
   isis network point-to-point
!
interface Ethernet3
   description P2P_eos2_Ethernet1
   no shutdown
   mtu 9214
   no switchport
   ip address 10.2.3.3/24
   mpls ip
   isis enable CORE
   isis circuit-type level-2
   isis metric 10
   isis hello padding
   isis network point-to-point
!
interface Ethernet4
   description P2P_eos5_Ethernet2
   no shutdown
   mtu 9214
   no switchport
   ip address 10.3.5.3/24
   mpls ip
   isis enable CORE
   isis circuit-type level-2
   isis metric 10
   isis hello padding
   isis network point-to-point
!
interface Ethernet5
   description P2P_eos4_Ethernet5
   no shutdown
   mtu 9214
   no switchport
   ip address 10.3.4.3/24
   mpls ip
   isis enable CORE
   isis circuit-type level-2
   isis metric 10
   isis hello padding
   isis network point-to-point
!
interface Ethernet6
   description CENTRAL_eos20
   no shutdown
   mtu 9214
   no switchport
   vrf CENTRAL
   ip address 10.3.20.3/24
```

### Port-Channel Interfaces

#### Port-Channel Interfaces Summary

##### L2

| Interface | Description | Mode | VLANs | Native VLAN | Trunk Group | LACP Fallback Timeout | LACP Fallback Mode | MLAG ID | EVPN ESI |
| --------- | ----------- | ---- | ----- | ----------- | ----------- | --------------------- | ------------------ | ------- | -------- |
| Port-Channel1 | ROUTER_eos9 | access | 100 | - | - | - | - | - | 0000:0000:278f:707a:a872 |

##### EVPN Multihoming

####### EVPN Multihoming Summary

| Interface | Ethernet Segment Identifier | Multihoming Redundancy Mode | Route Target |
| --------- | --------------------------- | --------------------------- | ------------ |
| Port-Channel1 | 0000:0000:278f:707a:a872 | all-active | 27:8f:70:7a:a8:72 |

#### Port-Channel Interfaces Device Configuration

```eos
!
interface Port-Channel1
   description ROUTER_eos9
   no shutdown
   mtu 9214
   switchport access vlan 100
   switchport mode access
   switchport
   !
   evpn ethernet-segment
      identifier 0000:0000:278f:707a:a872
      redundancy all-active
      route-target import 27:8f:70:7a:a8:72
   lacp system-id 278f.707a.a872
```

### Loopback Interfaces

#### Loopback Interfaces Summary

##### IPv4

| Interface | Description | VRF | IP Address |
| --------- | ----------- | --- | ---------- |
| Loopback0 | ROUTER_ID | default | 3.3.3.3/32 |

##### IPv6

| Interface | Description | VRF | IPv6 Addresses |
| --------- | ----------- | --- | -------------- |
| Loopback0 | ROUTER_ID | default | - |

##### ISIS

| Interface | ISIS instance | ISIS metric | Interface mode |
| --------- | ------------- | ----------- | -------------- |
| Loopback0 | CORE | - | passive |

#### Loopback Interfaces Device Configuration

```eos
!
interface Loopback0
   description ROUTER_ID
   no shutdown
   ip address 3.3.3.3/32
   node-segment ipv4 index 3
   isis enable CORE
   isis passive
```

## Routing

### Service Routing Protocols Model

Multi agent routing protocol model enabled

```eos
!
service routing protocols model multi-agent
```

### IP Routing

#### IP Routing Summary

| VRF | Routing Enabled |
| --- | --------------- |
| default | True |
| CENTRAL | True |

#### IP Routing Device Configuration

```eos
!
ip routing
ip routing vrf CENTRAL
```

### IPv6 Routing

#### IPv6 Routing Summary

| VRF | Routing Enabled |
| --- | --------------- |
| default | False |
| CENTRAL | false |
| default | false |

### Static Routes

#### Static Routes Summary

| VRF | Destination Prefix | Next Hop IP | Exit interface | Administrative Distance | Tag | Route Name | Metric |
| --- | ------------------ | ----------- | -------------- | ----------------------- | --- | ---------- | ------ |
| default | 0.0.0.0/0 | 192.168.0.1 | - | 1 | - | - | - |

#### Static Routes Device Configuration

```eos
!
ip route 0.0.0.0/0 192.168.0.1
```

### Router ISIS

#### Router ISIS Summary

| Settings | Value |
| -------- | ----- |
| Instance | CORE |
| Net-ID | 49.0001.0030.0300.3003.00 |
| Type | level-2 |
| Router-ID | 3.3.3.3 |
| Log Adjacency Changes | True |
| SR MPLS Enabled | True |

#### ISIS Route Timers

| Settings | Value |
| -------- | ----- |
| Local Convergence Delay | 10000 milliseconds |

#### ISIS Interfaces Summary

| Interface | ISIS Instance | ISIS Metric | Interface Mode |
| --------- | ------------- | ----------- | -------------- |
| Ethernet2 | CORE | 10 | point-to-point |
| Ethernet3 | CORE | 10 | point-to-point |
| Ethernet4 | CORE | 10 | point-to-point |
| Ethernet5 | CORE | 10 | point-to-point |
| Loopback0 | CORE | - | passive |

#### ISIS Segment-routing Node-SID

| Loopback | IPv4 Index | IPv6 Index |
| -------- | ---------- | ---------- |
| Loopback0 | 3 | - |

#### ISIS IPv4 Address Family Summary

| Settings | Value |
| -------- | ----- |
| IPv4 Address-family Enabled | True |
| Maximum-paths | 4 |
| TI-LFA Mode | link-protection |

#### Router ISIS Device Configuration

```eos
!
router isis CORE
   net 49.0001.0030.0300.3003.00
   router-id ipv4 3.3.3.3
   is-type level-2
   log-adjacency-changes
   timers local-convergence-delay 10000 protected-prefixes
   !
   address-family ipv4 unicast
      maximum-paths 4
      fast-reroute ti-lfa mode link-protection
   !
   segment-routing mpls
      no shutdown
```

### Router BGP

ASN Notation: asplain

#### Router BGP Summary

| BGP AS | Router ID |
| ------ | --------- |
| 65000 | 3.3.3.3 |

| BGP Tuning |
| ---------- |
| no bgp default ipv4-unicast |
| distance bgp 20 200 200 |
| graceful-restart restart-time 300 |
| graceful-restart |
| update wait-install |
| no bgp default ipv4-unicast |
| maximum-paths 4 |

#### Router BGP Peer Groups

##### MPLS-OVERLAY-PEERS

| Settings | Value |
| -------- | ----- |
| Address Family | mpls |
| Remote AS | 65000 |
| Source | Loopback0 |
| BFD | True |
| Send community | all |
| Maximum routes | 0 (no limit) |

#### BGP Neighbors

| Neighbor | Remote AS | VRF | Shutdown | Send-community | Maximum-routes | Allowas-in | BFD | RIB Pre-Policy Retain | Route-Reflector Client | Passive | TTL Max Hops |
| -------- | --------- | --- | -------- | -------------- | -------------- | ---------- | --- | --------------------- | ---------------------- | ------- | ------------ |
| 2.2.2.2 | Inherited from peer group MPLS-OVERLAY-PEERS | default | - | Inherited from peer group MPLS-OVERLAY-PEERS | Inherited from peer group MPLS-OVERLAY-PEERS | - | Inherited from peer group MPLS-OVERLAY-PEERS | - | - | - | - |
| 5.5.5.5 | Inherited from peer group MPLS-OVERLAY-PEERS | default | - | Inherited from peer group MPLS-OVERLAY-PEERS | Inherited from peer group MPLS-OVERLAY-PEERS | - | Inherited from peer group MPLS-OVERLAY-PEERS | - | - | - | - |
| 10.3.20.20 | 65020 | CENTRAL | - | - | 0 (no limit) | - | - | - | - | - | - |

#### Router BGP EVPN Address Family

##### EVPN Peer Groups

| Peer Group | Activate | Route-map In | Route-map Out | Peer-tag In | Peer-tag Out | Encapsulation | Next-hop-self Source Interface |
| ---------- | -------- | ------------ | ------------- | ----------- | ------------ | ------------- | ------------------------------ |
| MPLS-OVERLAY-PEERS | True | - | - | - | - | default | - |

##### EVPN Neighbor Default Encapsulation

| Neighbor Default Encapsulation | Next-hop-self Source Interface |
| ------------------------------ | ------------------------------ |
| mpls | Loopback0 |

#### Router BGP VPN-IPv4 Address Family

##### VPN-IPv4 Peer Groups

| Peer Group | Activate | Route-map In | Route-map Out | RCF In | RCF Out | Peer-tag In | Peer-tag Out |
| ---------- | -------- | ------------ | ------------- | ------ | ------- | ----------- | ------------ |
| MPLS-OVERLAY-PEERS | True | - | - | - | - | - | - |

#### Router BGP VLANs

| VLAN | Route-Distinguisher | Both Route-Target | Import Route Target | Export Route-Target | Redistribute |
| ---- | ------------------- | ----------------- | ------------------- | ------------------- | ------------ |
| 100 | 3.3.3.3:10100 | 10100:10100 | - | - | learned |

#### Router BGP VRFs

| VRF | Route-Distinguisher | Redistribute | Graceful Restart |
| --- | ------------------- | ------------ | ---------------- |
| CENTRAL | 3.3.3.3:199 | connected | - |

#### Router BGP Device Configuration

```eos
!
router bgp 65000
   router-id 3.3.3.3
   update wait-install
   no bgp default ipv4-unicast
   maximum-paths 4
   no bgp default ipv4-unicast
   distance bgp 20 200 200
   graceful-restart restart-time 300
   graceful-restart
   neighbor MPLS-OVERLAY-PEERS peer group
   neighbor MPLS-OVERLAY-PEERS remote-as 65000
   neighbor MPLS-OVERLAY-PEERS update-source Loopback0
   neighbor MPLS-OVERLAY-PEERS bfd
   neighbor MPLS-OVERLAY-PEERS password 7 <removed>
   neighbor MPLS-OVERLAY-PEERS send-community
   neighbor MPLS-OVERLAY-PEERS maximum-routes 0
   neighbor 2.2.2.2 peer group MPLS-OVERLAY-PEERS
   neighbor 2.2.2.2 description eos2_Loopback0
   neighbor 5.5.5.5 peer group MPLS-OVERLAY-PEERS
   neighbor 5.5.5.5 description eos5_Loopback0
   !
   vlan 100
      rd 3.3.3.3:10100
      route-target both 10100:10100
      redistribute learned
   !
   address-family evpn
      neighbor default encapsulation mpls next-hop-self source-interface Loopback0
      neighbor MPLS-OVERLAY-PEERS activate
   !
   address-family ipv4
      no neighbor MPLS-OVERLAY-PEERS activate
   !
   address-family vpn-ipv4
      neighbor MPLS-OVERLAY-PEERS activate
      neighbor default encapsulation mpls next-hop-self source-interface Loopback0
   !
   vrf CENTRAL
      rd 3.3.3.3:199
      route-target import vpn-ipv4 199:199
      route-target import vpn-ipv4 101:101
      route-target import vpn-ipv4 104:104
      route-target export vpn-ipv4 199:199
      router-id 3.3.3.3
      update wait-install
      neighbor 10.3.20.20 remote-as 65020
      neighbor 10.3.20.20 description eos20
      neighbor 10.3.20.20 maximum-routes 0
      redistribute connected
      !
      address-family ipv4
         neighbor 10.3.20.20 activate
```

## BFD

### Router BFD

#### Router BFD Multihop Summary

| Interval | Minimum RX | Multiplier |
| -------- | ---------- | ---------- |
| 300 | 300 | 3 |

#### Router BFD Device Configuration

```eos
!
router bfd
   multihop interval 300 min-rx 300 multiplier 3
```

## MPLS

### MPLS and LDP

#### MPLS and LDP Summary

| Setting | Value |
| -------- | ---- |
| MPLS IP Enabled | True |
| LDP Enabled | False |
| LDP Router ID | - |
| LDP Interface Disabled Default | - |
| LDP Transport-Address Interface | - |

### MPLS Interfaces

| Interface | MPLS IP Enabled | LDP Enabled | IGP Sync |
| --------- | --------------- | ----------- | -------- |
| Ethernet2 | True | - | - |
| Ethernet3 | True | - | - |
| Ethernet4 | True | - | - |
| Ethernet5 | True | - | - |

### MPLS Device Configuration

```eos
!
mpls ip
```

## Multicast

### IP IGMP Snooping

#### IP IGMP Snooping Summary

| IGMP Snooping | Fast Leave | Interface Restart Query | Proxy | Restart Query Interval | Robustness Variable |
| ------------- | ---------- | ----------------------- | ----- | ---------------------- | ------------------- |
| Enabled | - | - | - | - | - |

#### IP IGMP Snooping Device Configuration

```eos
```

## VRF Instances

### VRF Instances Summary

| VRF Name | IP Routing |
| -------- | ---------- |
| CENTRAL | enabled |

### VRF Instances Device Configuration

```eos
!
vrf instance CENTRAL
   description Centralized L3VPN Shared Service
```
