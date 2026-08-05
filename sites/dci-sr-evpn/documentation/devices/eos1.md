# eos1

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
  - [Loopback Interfaces](#loopback-interfaces)
  - [VLAN Interfaces](#vlan-interfaces)
  - [VXLAN Interface](#vxlan-interface)
- [Routing](#routing)
  - [Service Routing Protocols Model](#service-routing-protocols-model)
  - [Virtual Router MAC Address](#virtual-router-mac-address)
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
- [Filters](#filters)
  - [Prefix-lists](#prefix-lists)
  - [Route-maps](#route-maps)
- [VRF Instances](#vrf-instances)
  - [VRF Instances Summary](#vrf-instances-summary)
  - [VRF Instances Device Configuration](#vrf-instances-device-configuration)

## Management

### Management Interfaces

#### Management Interfaces Summary

##### IPv4

| Management Interface | Description | Type | VRF | IP Address | Gateway |
| -------------------- | ----------- | ---- | --- | ---------- | ------- |
| Management0 | OOB_MANAGEMENT | oob | default | 192.168.0.10/24 | 192.168.0.1 |

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
   ip address 192.168.0.10/24
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

STP mode: **rapid-pvst**

#### Rapid-PVST Instance and Priority

| Instance(s) | Priority |
| -------- | -------- |
| 1-4094 | 0 |

### Spanning Tree Device Configuration

```eos
!
spanning-tree mode rapid-pvst
spanning-tree vlan-id 1-4094 priority 0
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
| 16 | TenantA-VLAN16 | - |
| 17 | TenantA-VLAN17 | - |

### VLANs Device Configuration

```eos
!
vlan 16
   name TenantA-VLAN16
!
vlan 17
   name TenantA-VLAN17
```

## Interfaces

### Ethernet Interfaces

#### Ethernet Interfaces Summary

##### L2

| Interface | Description | Mode | VLANs | Native VLAN | Trunk Group | Channel-Group |
| --------- | ----------- | ---- | ----- | ----------- | ----------- | ------------- |

*Inherited from Port-Channel Interface

##### IPv4

| Interface | Description | Channel Group | IP Address | VRF | MTU | Shutdown | ACL In | ACL Out |
| --------- | ----------- | ------------- | ---------- | --- | --- | -------- | ------ | ------- |
| Ethernet1 | P2P_eos2_Ethernet5 | - | 10.1.2.1/24 | default | 9214 | False | - | - |
| Ethernet4 | P2P_eos6_Ethernet4 | - | 10.101.0.19/31 | default | 9214 | False | - | - |
| Ethernet5 | P2P_eos5_Ethernet4 | - | 10.1.5.1/24 | default | 9214 | False | - | - |

##### ISIS

| Interface | Channel Group | ISIS Instance | ISIS BFD | ISIS Metric | Mode | ISIS Circuit Type | Hello Padding | ISIS Authentication Mode |
| --------- | ------------- | ------------- | -------- | ----------- | ---- | ----------------- | ------------- | ------------------------ |
| Ethernet1 | - | CORE | - | 10 | point-to-point | level-2 | - | - |
| Ethernet5 | - | CORE | - | 10 | point-to-point | level-2 | - | - |

#### Ethernet Interfaces Device Configuration

```eos
!
interface Ethernet1
   description P2P_eos2_Ethernet5
   no shutdown
   mtu 9214
   no switchport
   ip address 10.1.2.1/24
   mpls ip
   isis enable CORE
   isis circuit-type level-2
   isis metric 10
   isis network point-to-point
!
interface Ethernet4
   description P2P_eos6_Ethernet4
   no shutdown
   mtu 9214
   no switchport
   ip address 10.101.0.19/31
!
interface Ethernet5
   description P2P_eos5_Ethernet4
   no shutdown
   mtu 9214
   no switchport
   ip address 10.1.5.1/24
   mpls ip
   isis enable CORE
   isis circuit-type level-2
   isis metric 10
   isis network point-to-point
```

### Loopback Interfaces

#### Loopback Interfaces Summary

##### IPv4

| Interface | Description | VRF | IP Address |
| --------- | ----------- | --- | ---------- |
| Loopback0 | ROUTER_ID | default | 192.168.255.10/32 |
| Loopback1 | VXLAN_TUNNEL_SOURCE | default | 10.255.1.10/32 |

##### IPv6

| Interface | Description | VRF | IPv6 Addresses |
| --------- | ----------- | --- | -------------- |
| Loopback0 | ROUTER_ID | default | - |
| Loopback1 | VXLAN_TUNNEL_SOURCE | default | - |

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
   ip address 192.168.255.10/32
   node-segment ipv4 index 10
   isis enable CORE
   isis passive
!
interface Loopback1
   description VXLAN_TUNNEL_SOURCE
   no shutdown
   ip address 10.255.1.10/32
```

### VLAN Interfaces

#### VLAN Interfaces Summary

| Interface | Description | VRF | MTU | Shutdown |
| --------- | ----------- | --- | --- | -------- |
| Vlan16 | Tenant-A stretched subnet VLAN16 | tenant-a | 9014 | False |
| Vlan17 | Tenant-A stretched subnet VLAN17 | tenant-a | 9014 | False |

##### IPv4

| Interface | VRF | IP Address | IP Address Virtual | IP Router Virtual Address | ACL In | ACL Out |
| --------- | --- | ---------- | ------------------ | ------------------------- | ------ | ------- |
| Vlan16 | tenant-a | - | 172.16.16.254/24 | - | - | - |
| Vlan17 | tenant-a | - | 172.16.17.254/24 | - | - | - |

#### VLAN Interfaces Device Configuration

```eos
!
interface Vlan16
   description Tenant-A stretched subnet VLAN16
   no shutdown
   mtu 9014
   vrf tenant-a
   ip address virtual 172.16.16.254/24
!
interface Vlan17
   description Tenant-A stretched subnet VLAN17
   no shutdown
   mtu 9014
   vrf tenant-a
   ip address virtual 172.16.17.254/24
```

### VXLAN Interface

#### VXLAN Interface Summary

| Setting | Value |
| ------- | ----- |
| Source Interface | Loopback1 |
| UDP port | 4789 |

##### VLAN to VNI, Flood List and Multicast Group Mappings

| VLAN | VNI | Flood List | Multicast Group |
| ---- | --- | ---------- | --------------- |
| 16 | 10016 | - | - |
| 17 | 10017 | - | - |

##### VRF to VNI and Multicast Group Mappings

| VRF | VNI | Overlay Multicast Group to Encap Mappings |
| --- | --- | ----------------------------------------- |
| tenant-a | 1000 | - |

#### VXLAN Interface Device Configuration

```eos
!
interface Vxlan1
   description eos1_VTEP
   vxlan source-interface Loopback1
   vxlan udp-port 4789
   vxlan vlan 16 vni 10016
   vxlan vlan 17 vni 10017
   vxlan vrf tenant-a vni 1000
```

## Routing

### Service Routing Protocols Model

Multi agent routing protocol model enabled

```eos
!
service routing protocols model multi-agent
```

### Virtual Router MAC Address

#### Virtual Router MAC Address Summary

Virtual Router MAC Address: 00:1c:73:00:00:01

#### Virtual Router MAC Address Device Configuration

```eos
!
ip virtual-router mac-address 00:1c:73:00:00:01
```

### IP Routing

#### IP Routing Summary

| VRF | Routing Enabled |
| --- | --------------- |
| default | True |
| tenant-a | True |

#### IP Routing Device Configuration

```eos
!
ip routing
ip routing vrf tenant-a
```

### IPv6 Routing

#### IPv6 Routing Summary

| VRF | Routing Enabled |
| --- | --------------- |
| default | False |
| default | false |
| tenant-a | false |

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
| Net-ID | 49.0001.1921.6825.5010.00 |
| Type | level-2 |
| Router-ID | 192.168.255.10 |
| Log Adjacency Changes | True |
| SR MPLS Enabled | True |

#### ISIS Interfaces Summary

| Interface | ISIS Instance | ISIS Metric | Interface Mode |
| --------- | ------------- | ----------- | -------------- |
| Ethernet1 | CORE | 10 | point-to-point |
| Ethernet5 | CORE | 10 | point-to-point |
| Loopback0 | CORE | - | passive |

#### ISIS Segment-routing Node-SID

| Loopback | IPv4 Index | IPv6 Index |
| -------- | ---------- | ---------- |
| Loopback0 | 10 | - |

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
   net 49.0001.1921.6825.5010.00
   router-id ipv4 192.168.255.10
   is-type level-2
   log-adjacency-changes
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
| 1 | 192.168.255.10 |

| BGP Tuning |
| ---------- |
| no bgp default ipv4-unicast |
| distance bgp 20 200 200 |
| neighbor default send-community |
| graceful-restart restart-time 300 |
| graceful-restart |
| update wait-install |
| no bgp default ipv4-unicast |
| maximum-paths 4 |

#### Router BGP Peer Groups

##### EVPN-OVERLAY-PEERS

| Settings | Value |
| -------- | ----- |
| Address Family | evpn |
| Source | Loopback0 |
| BFD | True |
| Ebgp multihop | 3 |
| Send community | all |
| Maximum routes | 0 (no limit) |

##### IPV4-UNDERLAY-PEERS

| Settings | Value |
| -------- | ----- |
| Address Family | ipv4 |
| Send community | all |
| Maximum routes | 256000 |

##### MPLS-OVERLAY-PEERS

| Settings | Value |
| -------- | ----- |
| Remote AS | 1 |
| Source | Loopback0 |
| BFD | True |
| Send community | all |
| Maximum routes | 0 (no limit) |

#### BGP Neighbors

| Neighbor | Remote AS | VRF | Shutdown | Send-community | Maximum-routes | Allowas-in | BFD | RIB Pre-Policy Retain | Route-Reflector Client | Passive | TTL Max Hops |
| -------- | --------- | --- | -------- | -------------- | -------------- | ---------- | --- | --------------------- | ---------------------- | ------- | ------------ |
| 10.101.0.18 | 65110 | default | - | Inherited from peer group IPV4-UNDERLAY-PEERS | Inherited from peer group IPV4-UNDERLAY-PEERS | - | - | - | - | - | - |
| 192.168.255.14 | Inherited from peer group MPLS-OVERLAY-PEERS | default | - | Inherited from peer group MPLS-OVERLAY-PEERS | Inherited from peer group MPLS-OVERLAY-PEERS | - | Inherited from peer group MPLS-OVERLAY-PEERS | - | - | - | - |
| 192.168.255.15 | 65110 | default | - | Inherited from peer group EVPN-OVERLAY-PEERS | Inherited from peer group EVPN-OVERLAY-PEERS | - | Inherited from peer group EVPN-OVERLAY-PEERS | - | - | - | - |

#### Router BGP EVPN Address Family

- VPN import pruning is **enabled**

##### EVPN Peer Groups

| Peer Group | Activate | Route-map In | Route-map Out | Peer-tag In | Peer-tag Out | Encapsulation | Next-hop-self Source Interface |
| ---------- | -------- | ------------ | ------------- | ----------- | ------------ | ------------- | ------------------------------ |
| EVPN-OVERLAY-PEERS | True | - | - | - | - | default | - |
| MPLS-OVERLAY-PEERS | True | - | - | - | - | mpls | Loopback0 |

##### EVPN DCI Gateway Summary

| Settings | Value |
| -------- | ----- |
| Local Domain | 65110:1 |
| Remote Domain | 1:1 |
| Remote Domain Peer Groups | MPLS-OVERLAY-PEERS |
| L3 Gateway Configured | True |
| L3 Gateway Inter-domain | True |

#### Router BGP VLANs

| VLAN | Route-Distinguisher | Both Route-Target | Import Route Target | Export Route-Target | Redistribute |
| ---- | ------------------- | ----------------- | ------------------- | ------------------- | ------------ |
| 16 | 192.168.255.10:10016 | 10016:10016<br>remote 10016:10016 | - | - | learned |
| 17 | 192.168.255.10:10017 | 10017:10017<br>remote 10017:10017 | - | - | learned |

#### Router BGP VRFs

| VRF | Route-Distinguisher | Redistribute | Graceful Restart |
| --- | ------------------- | ------------ | ---------------- |
| tenant-a | 192.168.255.10:1000 | connected | - |

#### Router BGP Device Configuration

```eos
!
router bgp 1
   router-id 192.168.255.10
   update wait-install
   no bgp default ipv4-unicast
   maximum-paths 4
   no bgp default ipv4-unicast
   distance bgp 20 200 200
   neighbor default send-community
   graceful-restart restart-time 300
   graceful-restart
   neighbor EVPN-OVERLAY-PEERS peer group
   neighbor EVPN-OVERLAY-PEERS update-source Loopback0
   neighbor EVPN-OVERLAY-PEERS bfd
   neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
   neighbor EVPN-OVERLAY-PEERS password 7 <removed>
   neighbor EVPN-OVERLAY-PEERS send-community
   neighbor EVPN-OVERLAY-PEERS maximum-routes 0
   neighbor IPV4-UNDERLAY-PEERS peer group
   neighbor IPV4-UNDERLAY-PEERS password 7 <removed>
   neighbor IPV4-UNDERLAY-PEERS send-community
   neighbor IPV4-UNDERLAY-PEERS maximum-routes 256000
   neighbor MPLS-OVERLAY-PEERS peer group
   neighbor MPLS-OVERLAY-PEERS remote-as 1
   neighbor MPLS-OVERLAY-PEERS update-source Loopback0
   neighbor MPLS-OVERLAY-PEERS bfd
   neighbor MPLS-OVERLAY-PEERS description WAN Core Route Reflector
   neighbor MPLS-OVERLAY-PEERS password 7 <removed>
   neighbor MPLS-OVERLAY-PEERS send-community
   neighbor MPLS-OVERLAY-PEERS maximum-routes 0
   neighbor 10.101.0.18 peer group IPV4-UNDERLAY-PEERS
   neighbor 10.101.0.18 remote-as 65110
   neighbor 10.101.0.18 description eos6_Ethernet4
   neighbor 192.168.255.14 peer group MPLS-OVERLAY-PEERS
   neighbor 192.168.255.14 description eos5_Loopback0_RR
   neighbor 192.168.255.15 peer group EVPN-OVERLAY-PEERS
   neighbor 192.168.255.15 remote-as 65110
   neighbor 192.168.255.15 description eos6_Loopback0
   redistribute connected route-map RM-CONN-2-BGP
   !
   vlan 16
      rd 192.168.255.10:10016
      rd evpn domain remote 192.168.255.10:10016
      route-target both 10016:10016
      route-target import export evpn domain remote 10016:10016
      redistribute learned
   !
   vlan 17
      rd 192.168.255.10:10017
      rd evpn domain remote 192.168.255.10:10017
      route-target both 10017:10017
      route-target import export evpn domain remote 10017:10017
      redistribute learned
   !
   address-family evpn
      neighbor EVPN-OVERLAY-PEERS activate
      neighbor MPLS-OVERLAY-PEERS activate
      neighbor MPLS-OVERLAY-PEERS encapsulation mpls next-hop-self source-interface Loopback0
      neighbor MPLS-OVERLAY-PEERS domain remote
      domain identifier 65110:1
      domain identifier 1:1 remote
      route import match-failure action discard
      neighbor default next-hop-self received-evpn-routes route-type ip-prefix inter-domain
   !
   address-family ipv4
      no neighbor EVPN-OVERLAY-PEERS activate
      neighbor IPV4-UNDERLAY-PEERS activate
   !
   vrf tenant-a
      rd 192.168.255.10:1000
      route-target import evpn 1000:1000
      route-target export evpn 1000:1000
      router-id 192.168.255.10
      redistribute connected
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
| Ethernet1 | True | - | - |
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

## Filters

### Prefix-lists

#### Prefix-lists Summary

##### PL-LOOPBACKS-EVPN-OVERLAY

| Sequence | Action |
| -------- | ------ |
| 10 | permit 192.168.255.0/24 eq 32 |
| 20 | permit 10.255.1.0/24 eq 32 |

#### Prefix-lists Device Configuration

```eos
!
ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
   seq 10 permit 192.168.255.0/24 eq 32
   seq 20 permit 10.255.1.0/24 eq 32
```

### Route-maps

#### Route-maps Summary

##### RM-CONN-2-BGP

| Sequence | Type | Match | Set | Sub-Route-Map | Continue |
| -------- | ---- | ----- | --- | ------------- | -------- |
| 10 | permit | ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY | - | - | - |

#### Route-maps Device Configuration

```eos
!
route-map RM-CONN-2-BGP permit 10
   match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
```

## VRF Instances

### VRF Instances Summary

| VRF Name | IP Routing |
| -------- | ---------- |
| tenant-a | enabled |

### VRF Instances Device Configuration

```eos
!
vrf instance tenant-a
```
