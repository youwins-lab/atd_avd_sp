# DCI MPLS-SR EVPN WAN Core 랩 가이드

AVD로 **MPLS Segment Routing WAN 코어**를 만들고, 그 위에 DC1 / DC2 두 EVPN VXLAN 도메인을
**Multidomain EVPN Gateway**로 이어 붙이는 실습입니다. 최종 목표는 Tenant A의 VLAN 16 / 17에
붙은 호스트들이 DC를 넘어 서로 PING이 되는 것입니다.

- 대상 site: `sites/dci-sr-evpn`
- 전제: `README.md`의 환경 설정(STEP #1~#3)이 끝나 있어야 합니다.

---

## 0. 이 랩에서 배우는 것

| 개념 | 왜 중요한가 |
|---|---|
| ISIS Segment Routing (SR-MPLS) | LDP 없이 IGP만으로 MPLS 라벨 경로를 만든다. Node-SID = 목적지 라벨 |
| MPLS 데이터 플레인 | VXLAN이 아닌 MPLS로 오버레이 트래픽을 캡슐화 |
| iBGP RR / RR Client | 코어를 확장 가능하게 만드는 오버레이 구조 (풀메시 회피) |
| EVPN Multidomain Gateway | 서로 다른 EVPN 도메인(VXLAN ↔ MPLS)을 이어 붙이는 경계 장비 |
| L2 + L3 결합 게이트웨이 | Type-2(MAC-IP)를 Type-5(IP-Prefix)로도 재광고 → L2 스트레치 + L3 라우팅 동시 제공 |
| Domain identifier / D-path | 도메인 간 재광고 시 루프를 막는 장치 |

---

## 1. 토폴로지

### 1-1. 논리 구성

```
   ┌──────────── DC1 EVPN VXLAN ────────────┐        ┌──────────── DC2 EVPN VXLAN ────────────┐
   │                                        │        │                                        │
   │   host1-DC1        host2-DC1           │        │   host1-DC2        host2-DC2           │
   │    (eos15)          (eos18)            │        │    (eos10)          (eos19)            │
   │       └───────┬───────┘                │        │       └───────┬───────┘                │
   │          leaf1-DC1 (eos8)              │        │          leaf1-DC2 (eos7)              │
   │            AS 65012                    │        │            AS 65212                    │
   │               │                        │        │               │                        │
   │         spine1-DC1 (eos6)              │        │         spine1-DC2 (eos3)              │
   │            AS 65110                    │        │            AS 65220                    │
   │               │                        │        │               │                        │
   │        BL1-DC1 / GW11 (eos1) ══════════╪════════╪══════ BL1-DC2 / GW21 (eos4)            │
   └────────────────┼───────────────────────┘        └────────────────┼───────────────────────┘
                    │                                                 │
                    │        MPLS-SR WAN Core (BGP AS 1)              │
                    ├──────────────── P1 (eos2) ──────────────────────┤
                    └──────────────── RR (eos5) ──────────────────────┘
```

- `══` 구간이 **Remote EVPN 도메인**입니다. GW11 ↔ RR ↔ GW21 iBGP(AS 1), MPLS 캡슐화.
- 각 DC 내부는 **Local EVPN 도메인** — eBGP EVPN, VXLAN 캡슐화.
- GW 2대는 두 도메인에 동시에 속하면서 라우트를 재광고합니다.

### 1-2. 장비 매핑 (관리 IP는 바꾸지 않습니다)

| 랩 가이드 역할 | 장비 | 관리 IP | Loopback0 | VTEP (Lo1) | Node SID | BGP AS |
|---|---|---|---|---|---|---|
| RR | eos5 | 192.168.0.14 | 192.168.255.14 | — | 14 | 1 |
| P1 | eos2 | 192.168.0.11 | 192.168.255.11 | — | 11 | 1 |
| BL1-DC1 (GW11) | eos1 | 192.168.0.10 | 192.168.255.10 | 10.255.1.10 | 10 | 1 |
| BL1-DC2 (GW21) | eos4 | 192.168.0.13 | 192.168.255.13 | 10.255.1.13 | 13 | 1 |
| spine1-DC1 | eos6 | 192.168.0.15 | 192.168.255.15 | — | — | 65110 |
| leaf1-DC1 | eos8 | 192.168.0.17 | 192.168.255.17 | 10.255.1.17 | — | 65012 |
| spine1-DC2 | eos3 | 192.168.0.12 | 192.168.255.12 | — | — | 65220 |
| leaf1-DC2 | eos7 | 192.168.0.16 | 192.168.255.16 | 10.255.1.16 | — | 65212 |
| host1-DC1 | eos15 | 192.168.0.24 | — | — | — | — |
| host2-DC1 | eos18 | 192.168.0.27 | — | — | — | — |
| host1-DC2 | eos10 | 192.168.0.19 | — | — | — | — |
| host2-DC2 | eos19 | 192.168.0.28 | — | — | — | — |

> **핵심 규칙**: `Loopback0 = 192.168.255.<관리 IP 마지막 옥텟>`, `Node SID = 같은 숫자`.
> AVD에서는 노드 `id`를 관리 IP 마지막 옥텟으로 잡고 `loopback_ipv4_pool: 192.168.255.0/24`만
> 지정하면 자동으로 나옵니다. VTEP도 `vtep_loopback_ipv4_pool: 10.255.1.0/24`로 동일.

**미사용 장비**: `eos9`, `eos11`, `eos12`, `eos13`, `eos14`, `eos16`, `eos17`, `eos20`
— 현재 배선상 코어나 DC 패브릭에 넣을 자리가 없어 유휴 상태로 둡니다. 인벤토리의 `UNUSED`
그룹에 있고 어떤 플레이북의 대상도 아니므로 설정이 내려가지 않습니다.

### 1-3. 물리 링크 (실제 LLDP 확인값)

**WAN 코어 (ISIS-SR)** — IP는 랩 초기 상태 값을 그대로 사용

| A | 포트 | B | 포트 | 서브넷 |
|---|---|---|---|---|
| eos1 (GW11) | Et1 | eos2 (P1) | Et5 | 10.1.2.0/24 |
| eos1 (GW11) | Et5 | eos5 (RR) | Et4 | 10.1.5.0/24 |
| eos4 (GW21) | Et4 | eos2 (P1) | Et2 | 10.2.4.0/24 |
| eos4 (GW21) | Et3 | eos5 (RR) | Et1 | 10.4.5.0/24 |
| eos2 (P1) | Et3 | eos5 (RR) | Et3 | 10.2.5.0/24 |

**DC 패브릭 (eBGP)** — P2P IP는 AVD가 `uplink_ipv4_pool`에서 자동 할당

| A | 포트 | B | 포트 |
|---|---|---|---|
| eos1 (GW11) | Et4 | eos6 (spine1-DC1) | Et4 |
| eos8 (leaf1-DC1) | Et3 | eos6 (spine1-DC1) | Et2 |
| eos4 (GW21) | Et5 | eos3 (spine1-DC2) | Et5 |
| eos7 (leaf1-DC2) | Et1 | eos3 (spine1-DC2) | Et2 |

**호스트**: eos8:Et2→eos15, eos8:Et5→eos18, eos7:Et2→eos10, eos7:Et4→eos19

### 1-4. Tenant A 서비스

| VLAN | L2 VNI | 서브넷 | 애니캐스트 GW | VRF | L3 VNI |
|---|---|---|---|---|---|
| 16 | 10016 | 172.16.16.0/24 | 172.16.16.254 | tenant-a | 1000 |
| 17 | 10017 | 172.16.17.0/24 | 172.16.17.254 | tenant-a | 1000 |

호스트 주소: host1-DC1 `.51`, host2-DC1 `.52`, host1-DC2 `.53`, host2-DC2 `.54` (두 VLAN 모두)

---

## 2. 실습 진행

### STEP 0 — vault 준비 (최초 1회)

```bash
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml | grep "password:" | awk '{print $2}'`
ansible-vault encrypt_string "$LABPASSPHRASE" --name 'vault_ansible_password' \
  > sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/vault.yml
```

### STEP 1 — 빌드

```bash
make build_dci_sr_evpn
```

`sites/dci-sr-evpn/intended/configs/*.cfg` 8개(eos1~eos8)와 `documentation/`이 생성됩니다.
**배포 전에 반드시 생성된 설정을 눈으로 확인하세요.** 이 랩의 핵심은 "AVD 입력 → 어떤 EOS
설정이 나오는가"를 이해하는 것입니다.

```bash
# SR 언더레이가 어떻게 나왔는지
sed -n '/^router isis/,/^!$/p' sites/dci-sr-evpn/intended/configs/eos5.cfg

# GW의 두 도메인 BGP 설정
sed -n '/^router bgp/,/^!$/p' sites/dci-sr-evpn/intended/configs/eos1.cfg
```

### STEP 2 — 배포

```bash
make deploy_dci_sr_evpn_cvp      # CVP 경유 (change control 자동 생성/실행)
# 또는
make deploy_dci_sr_evpn_eapi     # eAPI 직접 push

make deploy_dci_sr_evpn_hosts    # Tenant A 호스트 (델타 merge)
```

### STEP 3 — 검증

```bash
make verify_dci_sr_evpn          # ANTA (설정 변경 없음)
```

---

## 3. TASK별 확인 포인트

### TASK 1 — MPLS-SR 도메인이 올라왔는가

```bash
ssh arista@192.168.0.14          # RR (eos5)

show isis neighbors
#  -> eos1(GW11), eos2(P1), eos4(GW21) 3개 인접이 UP

show ip route | include 192.168.255.
#  -> 다른 6개 노드의 Loopback0가 "I L2"(ISIS level-2)로 보여야 함

show isis segment-routing prefix-segments
#  -> 각 노드의 Node-SID (10, 11, 13, 14, 15, 16, 17)

show mpls lfib route
#  -> IP(prefix-segment) / IA(adjacency-segment) 라벨 엔트리
```

**왜 이렇게 되는가** — `underlay_routing_protocol: isis-sr` + `underlay_isis_instance_name: CORE`
가 `router isis CORE` + `segment-routing mpls`를 만들고, Loopback0의
`node-segment ipv4 index <id>`가 각 노드를 대표하는 라벨(prefix-SID)을 광고합니다.
LDP가 전혀 없는데도 라벨 경로가 생기는 것이 SR의 핵심입니다.

```bash
ssh arista@192.168.0.10          # GW11 (eos1)
show isis segment-routing adjacency-segments
show mpls segment-routing bindings
```

### TASK 2 — 오버레이(iBGP RR)가 붙었는가

```bash
ssh arista@192.168.0.14          # RR
show bgp evpn summary
#  -> 192.168.255.10 (GW11), 192.168.255.13 (GW21) 두 클라이언트가 Established

show running-config section router bgp
#  -> neighbor MPLS-OVERLAY-PEERS route-reflector-client
#  -> address-family evpn / neighbor default encapsulation mpls
```

**왜 이렇게 되는가** — eos5는 AVD node type `rr`(= `mpls_overlay_role: server`)이고,
GW 2대가 `mpls_route_reflectors: [eos5]`를 갖고 있어 AVD가 서로를 자동으로 찾아
RR ↔ Client 관계를 만듭니다. 코어는 EVPN을 **MPLS로** 캡슐화합니다.

### TASK 3 — Multidomain EVPN Gateway 동작

```bash
ssh arista@192.168.0.10          # GW11 (eos1)

show bgp evpn summary
#  -> 로컬 도메인: 192.168.255.15 (spine1-DC1, eBGP AS 65110)
#  -> 원격 도메인: 192.168.255.14 (RR, iBGP AS 1)

show bgp evpn domain local | include mac-ip
#  -> DC1 호스트(.51/.52)의 MAC-IP 루트

show bgp evpn domain remote
#  -> DC2 호스트(.53/.54)의 루트. next-hop이 192.168.255.13 (GW21 Loopback0)

show bgp evpn route-type imet
#  -> 로컬/원격 양쪽 도메인의 IMET 루트
```

GW 설정에서 눈여겨볼 3줄:

```
neighbor MPLS-OVERLAY-PEERS encapsulation mpls next-hop-self source-interface Loopback0
neighbor MPLS-OVERLAY-PEERS domain remote
neighbor default next-hop-self received-evpn-routes route-type ip-prefix inter-domain
```

| 줄 | 의미 |
|---|---|
| `encapsulation mpls ... source-interface Loopback0` | 코어로 내보낼 때 VXLAN VTEP(Lo1)이 아니라 SR 엔드포인트(Lo0)를 next-hop으로 → 상대 GW가 SR 라벨로 resolve |
| `domain remote` | 이 세션의 EVPN 루트를 "원격 도메인"으로 취급 → 로컬 도메인과 RD/RT를 분리 |
| `next-hop-self ... ip-prefix inter-domain` | L3 게이트웨이 동작. Type-5 IP-Prefix를 재광고할 때 자기 자신을 next-hop으로 |

그리고 VLAN 단위로:

```
vlan 16
   rd 192.168.255.10:10016
   rd evpn domain remote 192.168.255.10:10016
   route-target both 10016:10016
   route-target import export evpn domain remote 10016:10016
```

→ 같은 VLAN이 로컬(VXLAN)과 원격(MPLS) 두 도메인에서 각각 RD/RT를 갖습니다. 이게 L2 스트레치의 실체입니다.

```bash
show bgp evpn instance vlan 16
show ip route vrf tenant-a
#  -> DC1 호스트: "B E ... via VTEP 10.255.1.17 VNI 1000"  (VXLAN)
#  -> DC2 호스트: "B I ... via 192.168.255.13, IS-IS SR tunnel, label ..." (MPLS-SR)
```

**이 두 줄이 이 랩의 결론입니다** — 같은 VRF 안에서 로컬 호스트는 VXLAN으로, 원격 호스트는
MPLS-SR 라벨로 도달합니다.

### TASK 4 — 엔드투엔드 PING

```bash
ssh arista@192.168.0.24          # host1-DC1 (eos15)

ping vrf tenant-a 172.16.16.254   # 로컬 애니캐스트 GW
ping vrf tenant-a 172.16.16.52    # host2-DC1  (같은 DC, 같은 leaf)
ping vrf tenant-a 172.16.16.53    # host1-DC2  (DC 넘어감 - MPLS-SR 코어 경유)
ping vrf tenant-a 172.16.16.54    # host2-DC2
ping vrf tenant-a 172.16.17.51    # 자기 VLAN 17
ping vrf tenant-a 172.16.17.52
ping vrf tenant-a 172.16.17.53
ping vrf tenant-a 172.16.17.54
```

> **`vrf tenant-a`를 빼먹지 마세요.** 호스트의 VLAN 16/17 SVI는 로컬 VRF `tenant-a`에 들어
> 있어서 default VRF로는 통하지 않습니다.

4개 호스트 × 2개 VLAN = 8개 IP가 서로 전부 PING되면 성공입니다.

---

## 4. 문제 해결 순서

문제가 생기면 **아래에서 위로** 올라가며 확인하세요. 하위 계층이 안 되면 상위는 절대 안 됩니다.

| 순서 | 확인 | 명령 |
|---|---|---|
| 1 | 물리/IP | `show ip interface brief` |
| 2 | SR 언더레이 | `show isis neighbors`, `show ip route \| inc 192.168.255.` |
| 3 | MPLS 라벨 | `show mpls lfib route`, `show mpls segment-routing bindings` |
| 4 | DC 언더레이 | `show ip bgp summary` (leaf ↔ spine) |
| 5 | 로컬 EVPN | `show bgp evpn summary` (leaf ↔ spine) |
| 6 | 원격 EVPN | `show bgp evpn summary` (GW ↔ RR) |
| 7 | 도메인 재광고 | `show bgp evpn domain remote` |
| 8 | VRF 라우팅 | `show ip route vrf tenant-a` |
| 9 | 호스트 | `ping vrf tenant-a ...` |

자주 걸리는 지점:

- **2번에서 막힘** — GW의 ISIS는 AVD가 자동 생성하지 않고 `structured_config`로 넣습니다.
  코어 방향 인터페이스(eos1의 Et1/Et5, eos4의 Et4/Et3)에 `isis enable CORE`가 있는지 확인.
- **6번에서 막힘** — GW↔RR은 Loopback0 소스 멀티홉이 아닌 iBGP 직결 세션입니다.
  Loopback0끼리 도달 가능해야 하므로 2번이 먼저 성공해야 합니다.
- **8번에서 원격 호스트만 안 보임** — `domain remote` / `next-hop-self source-interface Loopback0`
  가 빠지면 원격 루트의 next-hop을 라벨로 resolve하지 못합니다.

---

## 5. 더 해보기

1. **SR 경로 확인** — `traceroute` 대신 `show isis segment-routing tunnel`로 GW11→GW21
   경로가 P1 경유인지 RR 경유인지 보고, `isis_metric`을 바꿔 경로를 유도해 보세요.
2. **TI-LFA 동작** — `show isis ti-lfa path`로 백업 경로를 확인하고, 링크 하나를 shutdown해
   수렴 시간을 측정해 보세요.
3. **IP VPN 방식으로 바꾸기** — 랩 원문은 EVPN 또는 IP VPN 중 선택이라고 합니다.
   `overlay_address_families`를 `[vpn-ipv4]`로 바꾸고 `ipvpn_gateway`를 써서 같은 Tenant A를
   MPLS L3VPN으로 실어 보세요.
4. **MLAG leaf 페어** — 지금은 DC당 leaf 1대입니다. 여유 장비가 생기면 leaf 페어 + MLAG
   또는 EVPN Ethernet Segment로 호스트를 이중화해 보세요.

---

## 부록 — AVD 입력이 EOS 설정으로 바뀌는 지점

| 하고 싶은 것 | AVD 입력 파일 / 키 |
|---|---|
| SR 도메인 이름/영역 | `group_vars/WAN_CORE.yml` → `underlay_isis_instance_name`, `isis_area_id` |
| 코어 링크와 IP | `group_vars/DCI_SR_EVPN/wan_topology.yml` → `core_interfaces.p2p_links` |
| Loopback0 / Node SID | 각 노드의 `id` + `loopback_ipv4_pool` |
| RR / Client 관계 | `type: rr` (WAN_RR.yml) + 노드의 `mpls_route_reflectors` |
| Tenant A VLAN/VRF | `group_vars/DCI_SR_EVPN/tenants.yml` |
| 호스트 접속 포트 | `group_vars/DCI_SR_EVPN/ports.yml` → `servers` |
| GW의 멀티도메인 동작 | `group_vars/DC{1,2}_FABRIC.yml` → 노드의 `evpn_gateway` |
| AVD가 안 만들어 주는 것 | 같은 노드의 `structured_config` (GW의 ISIS-SR / MPLS / iBGP 세션) |

`group_vars/**`를 고쳤으면 **항상** `make build_dci_sr_evpn`을 다시 돌리고
`intended/configs/*.cfg`의 diff를 확인하세요. `intended/`와 `documentation/`은 산출물이므로
직접 편집하지 않습니다.
