# s2-brdr1

## Table of Contents

- [Management](#management)
  - [Management Interfaces](#management-interfaces)
  - [Management API HTTP](#management-api-http)
- [Authentication](#authentication)
  - [Enable Password](#enable-password)
- [MLAG](#mlag)
  - [MLAG Summary](#mlag-summary)
  - [MLAG Device Configuration](#mlag-device-configuration)
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
  - [VLAN Interfaces](#vlan-interfaces)
  - [VXLAN Interface](#vxlan-interface)
- [Routing](#routing)
  - [Service Routing Protocols Model](#service-routing-protocols-model)
  - [Virtual Router MAC Address](#virtual-router-mac-address)
  - [IP Routing](#ip-routing)
  - [IPv6 Routing](#ipv6-routing)
  - [Static Routes](#static-routes)
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
| Management0 | OOB_MANAGEMENT | oob | default | 192.168.0.200/24 | 192.168.0.1 |

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
   ip address 192.168.0.200/24
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

## MLAG

### MLAG Summary

| Domain-id | Local-interface | Peer-address | Peer-link |
| --------- | --------------- | ------------ | --------- |
| BrdrLeafs | Vlan4094 | 10.102.253.143 | Port-Channel1000 |

Dual primary detection is disabled.

### MLAG Device Configuration

```eos
!
mlag configuration
   domain-id BrdrLeafs
   local-interface Vlan4094
   peer-address 10.102.253.143
   peer-link Port-Channel1000
```

## Spanning Tree

### Spanning Tree Summary

STP mode: **rapid-pvst**

#### Rapid-PVST Instance and Priority

| Instance(s) | Priority |
| -------- | -------- |
| 1-4094 | 0 |

#### Global Spanning-Tree Settings

- Spanning Tree disabled for VLANs: **4093-4094**

### Spanning Tree Device Configuration

```eos
!
spanning-tree mode rapid-pvst
no spanning-tree vlan-id 4093-4094
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
| 3016 | MLAG_L3_VRF_tenant-a | MLAG |
| 4093 | MLAG_L3 | MLAG |
| 4094 | MLAG | MLAG |

### VLANs Device Configuration

```eos
!
vlan 16
   name TenantA-VLAN16
!
vlan 17
   name TenantA-VLAN17
!
vlan 3016
   name MLAG_L3_VRF_tenant-a
   trunk group MLAG
!
vlan 4093
   name MLAG_L3
   trunk group MLAG
!
vlan 4094
   name MLAG
   trunk group MLAG
```

## Interfaces

### Ethernet Interfaces

#### Ethernet Interfaces Summary

##### L2

| Interface | Description | Mode | VLANs | Native VLAN | Trunk Group | Channel-Group |
| --------- | ----------- | ---- | ----- | ----------- | ----------- | ------------- |
| Ethernet1 | MLAG_s2-brdr2_Ethernet1 | *trunk | *- | *- | *MLAG | 1000 |
| Ethernet6 | MLAG_s2-brdr2_Ethernet6 | *trunk | *- | *- | *MLAG | 1000 |

*Inherited from Port-Channel Interface

##### IPv4

| Interface | Description | Channel Group | IP Address | VRF | MTU | Shutdown | ACL In | ACL Out |
| --------- | ----------- | ------------- | ---------- | --- | --- | -------- | ------ | ------- |
| Ethernet2 | P2P_s2-spine1_Ethernet7 | - | 10.102.3.29/31 | default | 9214 | False | - | - |
| Ethernet3 | P2P_s2-spine2_Ethernet7 | - | 10.102.3.31/31 | default | 9214 | False | - | - |
| Ethernet4 | P2P_s2-core1_Ethernet2 | - | 172.16.2.0/31 | default | 9214 | False | - | - |
| Ethernet5 | P2P_s2-core2_Ethernet2 | - | 172.16.2.2/31 | default | 9214 | False | - | - |

#### Ethernet Interfaces Device Configuration

```eos
!
interface Ethernet1
   description MLAG_s2-brdr2_Ethernet1
   no shutdown
   channel-group 1000 mode active
!
interface Ethernet2
   description P2P_s2-spine1_Ethernet7
   no shutdown
   mtu 9214
   no switchport
   ip address 10.102.3.29/31
!
interface Ethernet3
   description P2P_s2-spine2_Ethernet7
   no shutdown
   mtu 9214
   no switchport
   ip address 10.102.3.31/31
!
interface Ethernet4
   description P2P_s2-core1_Ethernet2
   no shutdown
   mtu 9214
   no switchport
   ip address 172.16.2.0/31
   mpls ldp interface
   mpls ip
!
interface Ethernet5
   description P2P_s2-core2_Ethernet2
   no shutdown
   mtu 9214
   no switchport
   ip address 172.16.2.2/31
   mpls ldp interface
   mpls ip
!
interface Ethernet6
   description MLAG_s2-brdr2_Ethernet6
   no shutdown
   channel-group 1000 mode active
```

### Port-Channel Interfaces

#### Port-Channel Interfaces Summary

##### L2

| Interface | Description | Mode | VLANs | Native VLAN | Trunk Group | LACP Fallback Timeout | LACP Fallback Mode | MLAG ID | EVPN ESI |
| --------- | ----------- | ---- | ----- | ----------- | ----------- | --------------------- | ------------------ | ------- | -------- |
| Port-Channel1000 | MLAG_s2-brdr2_Port-Channel1000 | trunk | - | - | MLAG | - | - | - | - |

#### Port-Channel Interfaces Device Configuration

```eos
!
interface Port-Channel1000
   description MLAG_s2-brdr2_Port-Channel1000
   no shutdown
   switchport mode trunk
   switchport trunk group MLAG
   switchport
```

### Loopback Interfaces

#### Loopback Interfaces Summary

##### IPv4

| Interface | Description | VRF | IP Address |
| --------- | ----------- | --- | ---------- |
| Loopback0 | ROUTER_ID | default | 192.168.255.200/32 |
| Loopback1 | VXLAN_TUNNEL_SOURCE | default | 192.168.254.200/32 |

##### IPv6

| Interface | Description | VRF | IPv6 Addresses |
| --------- | ----------- | --- | -------------- |
| Loopback0 | ROUTER_ID | default | - |
| Loopback1 | VXLAN_TUNNEL_SOURCE | default | - |

#### Loopback Interfaces Device Configuration

```eos
!
interface Loopback0
   description ROUTER_ID
   no shutdown
   ip address 192.168.255.200/32
!
interface Loopback1
   description VXLAN_TUNNEL_SOURCE
   no shutdown
   ip address 192.168.254.200/32
```

### VLAN Interfaces

#### VLAN Interfaces Summary

| Interface | Description | VRF | MTU | Shutdown |
| --------- | ----------- | --- | --- | -------- |
| Vlan16 | Tenant-A stretched subnet VLAN16 | tenant-a | 9014 | False |
| Vlan17 | Tenant-A stretched subnet VLAN17 | tenant-a | 9014 | False |
| Vlan3016 | MLAG_L3_VRF_tenant-a | tenant-a | 9214 | False |
| Vlan4093 | MLAG_L3 | default | 9214 | False |
| Vlan4094 | MLAG | default | 9214 | False |

##### IPv4

| Interface | VRF | IP Address | IP Address Virtual | IP Router Virtual Address | ACL In | ACL Out |
| --------- | --- | ---------- | ------------------ | ------------------------- | ------ | ------- |
| Vlan16 | tenant-a | - | 10.16.16.1/24 | - | - | - |
| Vlan17 | tenant-a | - | 10.17.17.1/24 | - | - | - |
| Vlan3016 | tenant-a | 10.255.17.142/31 | - | - | - | - |
| Vlan4093 | default | 10.102.255.142/31 | - | - | - | - |
| Vlan4094 | default | 10.102.253.142/31 | - | - | - | - |

#### VLAN Interfaces Device Configuration

```eos
!
interface Vlan16
   description Tenant-A stretched subnet VLAN16
   no shutdown
   mtu 9014
   vrf tenant-a
   ip address virtual 10.16.16.1/24
!
interface Vlan17
   description Tenant-A stretched subnet VLAN17
   no shutdown
   mtu 9014
   vrf tenant-a
   ip address virtual 10.17.17.1/24
!
interface Vlan3016
   description MLAG_L3_VRF_tenant-a
   no shutdown
   mtu 9214
   vrf tenant-a
   ip address 10.255.17.142/31
!
interface Vlan4093
   description MLAG_L3
   no shutdown
   mtu 9214
   ip address 10.102.255.142/31
!
interface Vlan4094
   description MLAG
   no shutdown
   mtu 9214
   no autostate
   ip address 10.102.253.142/31
```

### VXLAN Interface

#### VXLAN Interface Summary

| Setting | Value |
| ------- | ----- |
| Source Interface | Loopback1 |
| UDP port | 4789 |
| EVPN MLAG Shared Router MAC | mlag-system-id |

##### VLAN to VNI, Flood List and Multicast Group Mappings

| VLAN | VNI | Flood List | Multicast Group |
| ---- | --- | ---------- | --------------- |
| 16 | 10016 | - | - |
| 17 | 10017 | - | - |

##### VRF to VNI and Multicast Group Mappings

| VRF | VNI | Overlay Multicast Group to Encap Mappings |
| --- | --- | ----------------------------------------- |
| tenant-a | 50016 | - |

#### VXLAN Interface Device Configuration

```eos
!
interface Vxlan1
   description s2-brdr1_VTEP
   vxlan source-interface Loopback1
   vxlan virtual-router encapsulation mac-address mlag-system-id
   vxlan udp-port 4789
   vxlan vlan 16 vni 10016
   vxlan vlan 17 vni 10017
   vxlan vrf tenant-a vni 50016
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

### Router BGP

ASN Notation: asplain

#### Router BGP Summary

| BGP AS | Router ID |
| ------ | --------- |
| 65199 | 192.168.255.200 |

| BGP Tuning |
| ---------- |
| no bgp default ipv4-unicast |
| distance bgp 20 200 200 |
| neighbor default send-community |
| graceful-restart restart-time 300 |
| graceful-restart |
| bgp bestpath d-path |
| update wait-install |
| no bgp default ipv4-unicast |
| maximum-paths 4 |

#### Router BGP Peer Groups

##### EVPN-OVERLAY-LOCAL-PEERS

| Settings | Value |
| -------- | ----- |
| Address Family | evpn |
| Source | Loopback0 |
| BFD | True |
| Ebgp multihop | 3 |
| Send community | all |
| Maximum routes | 0 (no limit) |

##### EVPN-OVERLAY-REMOTE-PEERS

| Settings | Value |
| -------- | ----- |
| Address Family | evpn |
| Source | Loopback0 |
| BFD | True |
| Ebgp multihop | 15 |
| Send community | all |
| Maximum routes | 0 (no limit) |

##### IPV4-UNDERLAY-PEERS

| Settings | Value |
| -------- | ----- |
| Address Family | ipv4 |
| Send community | all |
| Maximum routes | 256000 |

##### IPVPN-GATEWAY-PEERS

| Settings | Value |
| -------- | ----- |
| Address Family | mpls |
| Source | Loopback0 |
| BFD | True |
| Send community | all |
| Maximum routes | 0 (no limit) |

##### MLAG-IPV4-UNDERLAY-PEER

| Settings | Value |
| -------- | ----- |
| Address Family | ipv4 |
| Remote AS | 65199 |
| Next-hop self | True |
| Send community | all |
| Maximum routes | 256000 |

#### BGP Neighbors

| Neighbor | Remote AS | VRF | Shutdown | Send-community | Maximum-routes | Allowas-in | BFD | RIB Pre-Policy Retain | Route-Reflector Client | Passive | TTL Max Hops |
| -------- | --------- | --- | -------- | -------------- | -------------- | ---------- | --- | --------------------- | ---------------------- | ------- | ------------ |
| 10.102.3.28 | 65100 | default | - | Inherited from peer group IPV4-UNDERLAY-PEERS | Inherited from peer group IPV4-UNDERLAY-PEERS | - | - | - | - | - | - |
| 10.102.3.30 | 65100 | default | - | Inherited from peer group IPV4-UNDERLAY-PEERS | Inherited from peer group IPV4-UNDERLAY-PEERS | - | - | - | - | - | - |
| 10.102.255.143 | Inherited from peer group MLAG-IPV4-UNDERLAY-PEER | default | - | Inherited from peer group MLAG-IPV4-UNDERLAY-PEER | Inherited from peer group MLAG-IPV4-UNDERLAY-PEER | - | - | - | - | - | - |
| 172.16.2.1 | 1 | default | - | Inherited from peer group IPV4-UNDERLAY-PEERS | Inherited from peer group IPV4-UNDERLAY-PEERS | - | - | - | - | - | - |
| 172.16.2.3 | 1 | default | - | Inherited from peer group IPV4-UNDERLAY-PEERS | Inherited from peer group IPV4-UNDERLAY-PEERS | - | - | - | - | - | - |
| 192.168.255.20 | 65100 | default | - | Inherited from peer group EVPN-OVERLAY-LOCAL-PEERS | Inherited from peer group EVPN-OVERLAY-LOCAL-PEERS | - | Inherited from peer group EVPN-OVERLAY-LOCAL-PEERS | - | - | - | - |
| 192.168.255.21 | 65100 | default | - | Inherited from peer group EVPN-OVERLAY-LOCAL-PEERS | Inherited from peer group EVPN-OVERLAY-LOCAL-PEERS | - | Inherited from peer group EVPN-OVERLAY-LOCAL-PEERS | - | - | - | - |
| 192.168.255.100 | 65099 | default | - | Inherited from peer group EVPN-OVERLAY-REMOTE-PEERS | Inherited from peer group EVPN-OVERLAY-REMOTE-PEERS | - | Inherited from peer group EVPN-OVERLAY-REMOTE-PEERS | - | - | - | - |
| 192.168.255.101 | 65099 | default | - | Inherited from peer group EVPN-OVERLAY-REMOTE-PEERS | Inherited from peer group EVPN-OVERLAY-REMOTE-PEERS | - | Inherited from peer group EVPN-OVERLAY-REMOTE-PEERS | - | - | - | - |
| 192.168.255.202 | 1 | default | - | Inherited from peer group IPVPN-GATEWAY-PEERS | Inherited from peer group IPVPN-GATEWAY-PEERS | - | Inherited from peer group IPVPN-GATEWAY-PEERS | - | - | - | - |
| 192.168.255.203 | 1 | default | - | Inherited from peer group IPVPN-GATEWAY-PEERS | Inherited from peer group IPVPN-GATEWAY-PEERS | - | Inherited from peer group IPVPN-GATEWAY-PEERS | - | - | - | - |
| 10.255.17.143 | Inherited from peer group MLAG-IPV4-UNDERLAY-PEER | tenant-a | - | Inherited from peer group MLAG-IPV4-UNDERLAY-PEER | Inherited from peer group MLAG-IPV4-UNDERLAY-PEER | - | - | - | - | - | - |

#### Router BGP EVPN Address Family

- VPN import pruning is **enabled**

##### EVPN Peer Groups

| Peer Group | Activate | Route-map In | Route-map Out | Peer-tag In | Peer-tag Out | Encapsulation | Next-hop-self Source Interface |
| ---------- | -------- | ------------ | ------------- | ----------- | ------------ | ------------- | ------------------------------ |
| EVPN-OVERLAY-LOCAL-PEERS | True | - | - | - | - | default | - |
| EVPN-OVERLAY-REMOTE-PEERS | True | - | - | - | - | default | - |

##### EVPN DCI Gateway Summary

| Settings | Value |
| -------- | ----- |
| Local Domain | 65199:1 |
| Remote Domain Peer Groups | EVPN-OVERLAY-REMOTE-PEERS |
| L3 Gateway Configured | True |
| L3 Gateway Inter-domain | True |

#### Router BGP VPN-IPv4 Address Family

##### VPN-IPv4 Peer Groups

| Peer Group | Activate | Route-map In | Route-map Out | RCF In | RCF Out | Peer-tag In | Peer-tag Out |
| ---------- | -------- | ------------ | ------------- | ------ | ------- | ----------- | ------------ |
| IPVPN-GATEWAY-PEERS | True | - | - | - | - | - | - |

#### Router BGP VLANs

| VLAN | Route-Distinguisher | Both Route-Target | Import Route Target | Export Route-Target | Redistribute |
| ---- | ------------------- | ----------------- | ------------------- | ------------------- | ------------ |
| 16 | 192.168.255.200:10016 | 10016:10016<br>remote 10016:10016 | - | - | learned |
| 17 | 192.168.255.200:10017 | 10017:10017<br>remote 10017:10017 | - | - | learned |

#### Router BGP VRFs

| VRF | Route-Distinguisher | Redistribute | Graceful Restart |
| --- | ------------------- | ------------ | ---------------- |
| tenant-a | 192.168.255.200:16 | connected | - |

#### Router BGP Device Configuration

```eos
!
router bgp 65199
   router-id 192.168.255.200
   update wait-install
   no bgp default ipv4-unicast
   maximum-paths 4
   no bgp default ipv4-unicast
   distance bgp 20 200 200
   neighbor default send-community
   graceful-restart restart-time 300
   graceful-restart
   bgp bestpath d-path
   neighbor EVPN-OVERLAY-LOCAL-PEERS peer group
   neighbor EVPN-OVERLAY-LOCAL-PEERS update-source Loopback0
   neighbor EVPN-OVERLAY-LOCAL-PEERS bfd
   neighbor EVPN-OVERLAY-LOCAL-PEERS ebgp-multihop 3
   neighbor EVPN-OVERLAY-LOCAL-PEERS password 7 <removed>
   neighbor EVPN-OVERLAY-LOCAL-PEERS send-community
   neighbor EVPN-OVERLAY-LOCAL-PEERS maximum-routes 0
   neighbor EVPN-OVERLAY-REMOTE-PEERS peer group
   neighbor EVPN-OVERLAY-REMOTE-PEERS update-source Loopback0
   neighbor EVPN-OVERLAY-REMOTE-PEERS bfd
   neighbor EVPN-OVERLAY-REMOTE-PEERS ebgp-multihop 15
   neighbor EVPN-OVERLAY-REMOTE-PEERS password 7 <removed>
   neighbor EVPN-OVERLAY-REMOTE-PEERS send-community
   neighbor EVPN-OVERLAY-REMOTE-PEERS maximum-routes 0
   neighbor IPV4-UNDERLAY-PEERS peer group
   neighbor IPV4-UNDERLAY-PEERS password 7 <removed>
   neighbor IPV4-UNDERLAY-PEERS send-community
   neighbor IPV4-UNDERLAY-PEERS maximum-routes 256000
   neighbor IPVPN-GATEWAY-PEERS peer group
   neighbor IPVPN-GATEWAY-PEERS update-source Loopback0
   neighbor IPVPN-GATEWAY-PEERS bfd
   neighbor IPVPN-GATEWAY-PEERS send-community
   neighbor IPVPN-GATEWAY-PEERS maximum-routes 0
   neighbor MLAG-IPV4-UNDERLAY-PEER peer group
   neighbor MLAG-IPV4-UNDERLAY-PEER remote-as 65199
   neighbor MLAG-IPV4-UNDERLAY-PEER next-hop-self
   neighbor MLAG-IPV4-UNDERLAY-PEER description s2-brdr2
   neighbor MLAG-IPV4-UNDERLAY-PEER route-map RM-MLAG-PEER-IN in
   neighbor MLAG-IPV4-UNDERLAY-PEER password 7 <removed>
   neighbor MLAG-IPV4-UNDERLAY-PEER send-community
   neighbor MLAG-IPV4-UNDERLAY-PEER maximum-routes 256000
   neighbor 10.102.3.28 peer group IPV4-UNDERLAY-PEERS
   neighbor 10.102.3.28 remote-as 65100
   neighbor 10.102.3.28 description s2-spine1_Ethernet7
   neighbor 10.102.3.30 peer group IPV4-UNDERLAY-PEERS
   neighbor 10.102.3.30 remote-as 65100
   neighbor 10.102.3.30 description s2-spine2_Ethernet7
   neighbor 10.102.255.143 peer group MLAG-IPV4-UNDERLAY-PEER
   neighbor 10.102.255.143 description s2-brdr2_Vlan4093
   neighbor 172.16.2.1 peer group IPV4-UNDERLAY-PEERS
   neighbor 172.16.2.1 remote-as 1
   neighbor 172.16.2.1 description s2-core1_Ethernet2
   neighbor 172.16.2.3 peer group IPV4-UNDERLAY-PEERS
   neighbor 172.16.2.3 remote-as 1
   neighbor 172.16.2.3 description s2-core2_Ethernet2
   neighbor 192.168.255.20 peer group EVPN-OVERLAY-LOCAL-PEERS
   neighbor 192.168.255.20 remote-as 65100
   neighbor 192.168.255.20 description s2-spine1_Loopback0
   neighbor 192.168.255.21 peer group EVPN-OVERLAY-LOCAL-PEERS
   neighbor 192.168.255.21 remote-as 65100
   neighbor 192.168.255.21 description s2-spine2_Loopback0
   neighbor 192.168.255.100 peer group EVPN-OVERLAY-REMOTE-PEERS
   neighbor 192.168.255.100 remote-as 65099
   neighbor 192.168.255.100 description s1-brdr1_Loopback0
   neighbor 192.168.255.101 peer group EVPN-OVERLAY-REMOTE-PEERS
   neighbor 192.168.255.101 remote-as 65099
   neighbor 192.168.255.101 description s1-brdr2_Loopback0
   neighbor 192.168.255.202 peer group IPVPN-GATEWAY-PEERS
   neighbor 192.168.255.202 remote-as 1
   neighbor 192.168.255.202 description s2-core1
   neighbor 192.168.255.202 ebgp-multihop 15
   neighbor 192.168.255.203 peer group IPVPN-GATEWAY-PEERS
   neighbor 192.168.255.203 remote-as 1
   neighbor 192.168.255.203 description s2-core2
   neighbor 192.168.255.203 ebgp-multihop 15
   redistribute connected route-map RM-CONN-2-BGP
   !
   vlan 16
      rd 192.168.255.200:10016
      rd evpn domain remote 192.168.255.200:10016
      route-target both 10016:10016
      route-target import export evpn domain remote 10016:10016
      redistribute learned
   !
   vlan 17
      rd 192.168.255.200:10017
      rd evpn domain remote 192.168.255.200:10017
      route-target both 10017:10017
      route-target import export evpn domain remote 10017:10017
      redistribute learned
   !
   address-family evpn
      neighbor EVPN-OVERLAY-LOCAL-PEERS activate
      neighbor EVPN-OVERLAY-REMOTE-PEERS activate
      neighbor EVPN-OVERLAY-REMOTE-PEERS domain remote
      domain identifier 65199:1
      route import match-failure action discard
      neighbor default next-hop-self received-evpn-routes route-type ip-prefix inter-domain
   !
   address-family ipv4
      no neighbor EVPN-OVERLAY-LOCAL-PEERS activate
      no neighbor EVPN-OVERLAY-REMOTE-PEERS activate
      neighbor IPV4-UNDERLAY-PEERS activate
      no neighbor IPVPN-GATEWAY-PEERS activate
      neighbor MLAG-IPV4-UNDERLAY-PEER activate
   !
   address-family vpn-ipv4
      neighbor IPVPN-GATEWAY-PEERS activate
      neighbor default encapsulation mpls next-hop-self source-interface Loopback0
      domain identifier 1:2
   !
   vrf tenant-a
      rd 192.168.255.200:16
      route-target import evpn 16:16
      route-target export evpn 16:16
      router-id 192.168.255.200
      update wait-install
      neighbor 10.255.17.143 peer group MLAG-IPV4-UNDERLAY-PEER
      neighbor 10.255.17.143 description s2-brdr2_Vlan3016
      redistribute connected route-map RM-CONN-2-BGP-VRFS
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
| LDP Enabled | True |
| LDP Router ID | 192.168.255.200 |
| LDP Interface Disabled Default | True |
| LDP Transport-Address Interface | Loopback0 |

### MPLS Interfaces

| Interface | MPLS IP Enabled | LDP Enabled | IGP Sync |
| --------- | --------------- | ----------- | -------- |
| Ethernet4 | True | True | - |
| Ethernet5 | True | True | - |

### MPLS Device Configuration

```eos
!
mpls ip
!
mpls ldp
   router-id 192.168.255.200
   transport-address interface Loopback0
   interface disabled default
   no shutdown
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
| 20 | permit 192.168.254.0/24 eq 32 |

##### PL-MLAG-PEER-VRFS

| Sequence | Action |
| -------- | ------ |
| 10 | permit 10.255.17.142/31 |

#### Prefix-lists Device Configuration

```eos
!
ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
   seq 10 permit 192.168.255.0/24 eq 32
   seq 20 permit 192.168.254.0/24 eq 32
!
ip prefix-list PL-MLAG-PEER-VRFS
   seq 10 permit 10.255.17.142/31
```

### Route-maps

#### Route-maps Summary

##### RM-CONN-2-BGP

| Sequence | Type | Match | Set | Sub-Route-Map | Continue |
| -------- | ---- | ----- | --- | ------------- | -------- |
| 10 | permit | ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY | - | - | - |

##### RM-CONN-2-BGP-VRFS

| Sequence | Type | Match | Set | Sub-Route-Map | Continue |
| -------- | ---- | ----- | --- | ------------- | -------- |
| 10 | deny | ip address prefix-list PL-MLAG-PEER-VRFS | - | - | - |
| 20 | permit | - | - | - | - |

##### RM-MLAG-PEER-IN

| Sequence | Type | Match | Set | Sub-Route-Map | Continue |
| -------- | ---- | ----- | --- | ------------- | -------- |
| 10 | permit | - | origin incomplete | - | - |

#### Route-maps Device Configuration

```eos
!
route-map RM-CONN-2-BGP permit 10
   match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
!
route-map RM-CONN-2-BGP-VRFS deny 10
   match ip address prefix-list PL-MLAG-PEER-VRFS
!
route-map RM-CONN-2-BGP-VRFS permit 20
!
route-map RM-MLAG-PEER-IN permit 10
   description Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
   set origin incomplete
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
