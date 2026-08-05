# MPLS Segment Routing EVPN DCI 랩 (`sites/dci-mpls-sr`)

DC1 / DC2 두 개의 EVPN-VXLAN L3LS 패브릭을, **ISIS Segment Routing(MPLS) DCI 코어**로 연결하는
독립 site 입니다. `sites/dc1` / `sites/dc2` 와 완전히 별개의 inventory / group_vars 를 가지며,
같은 물리 장비를 다른 설계로 재구성합니다.

> **주의 — 이 랩을 배포하면 기존 `sites/dc1` / `sites/dc2` 설정이 덮어써집니다.**
> 같은 ATD 장비(`s1-*`, `s2-*`)를 쓰기 때문에 IP 체계·BGP AS·VLAN 이 모두 바뀝니다.
> 원래 랩으로 돌아가려면 `make build_dc1 && make deploy_dc1_cvp` (+ `deploy_dc2_*`,
> `deploy_dc{n}_dci_cvp`, `deploy_dc{n}_host_cvp`) 를 다시 실행하세요.

## 이 랩이 만드는 것

```
       DC1 (EVPN-VXLAN)                MPLS-SR DCI Core (AS 1)              DC2 (EVPN-VXLAN)
  ┌──────────────────────┐        ┌───────────────────────────┐        ┌──────────────────────┐
  │ s1-spine1/2  AS 65000│        │  s1-core1 (RR)  s2-core1  │        │ s2-spine1/2  AS 65100│
  │ s1-leaf1/2   AS 65001│        │      (RR)                 │        │ s2-leaf1/2   AS 65101│
  │ s1-leaf3/4   AS 65002│        │  s1-core2 (PE)  s2-core2  │        │ s2-leaf3/4   AS 65102│
  │ s1-brdr1/2   AS 65099├────────┤      (PE)                 ├────────┤ s2-brdr1/2   AS 65199│
  └──────────────────────┘  eBGP  └───────────────────────────┘  eBGP  └──────────────────────┘
                          vpn-ipv4     ISIS "CORE" + SR MPLS      vpn-ipv4
                                       iBGP RR / RR Client
```

| 도메인 | Ansible 그룹 | 언더레이 | 오버레이 |
|---|---|---|---|
| DC1 | `DC1_FABRIC` | eBGP | eBGP EVPN (VXLAN) |
| DC2 | `DC2_FABRIC` | eBGP | eBGP EVPN (VXLAN) |
| DCI 코어 | `DCI_CORE` | ISIS-SR (프로세스명 `CORE`, area 49.0001) | iBGP `vpn-ipv4` + `evpn` (AS 1, RR/Client) |

세 도메인이 서로의 facts 를 참조하므로(Border Leaf 의 `evpn_gateway.remote_peers`, 코어의 RR/Client
관계) AVD 상으로는 **하나의 패브릭**입니다 — `fabric_name: MPLS_SR_DCI_FABRIC`, 한 개의 플레이에서
같이 빌드됩니다.

## 장비 / IP 할당

MGMT 망(192.168.0.0/24, GW 192.168.0.1)은 기존 랩 체계를 그대로 씁니다. 나머지는 이 랩 전용입니다.

**핵심 규칙: node `id` = MGMT IP 마지막 옥텟 → `Loopback0 = 192.168.255.<id>/32`,
ISIS-SR Node-SID index = `<id>`.**

| 장비 | MGMT | id | Loopback0 | 역할 |
|---|---|---|---|---|
| s1-spine1 / s1-spine2 | .10 / .11 | 10 / 11 | 192.168.255.10 / .11 | DC1 spine |
| s1-leaf1 ~ s1-leaf4 | .12 ~ .15 | 12 ~ 15 | 192.168.255.12 ~ .15 | DC1 l3leaf (MLAG 페어 2조) |
| s1-brdr1 / s1-brdr2 | .100 / .101 | 100 / 101 | 192.168.255.100 / .101 | DC1 Border Leaf = EVPN + IP-VPN 게이트웨이 |
| s1-core1 / s1-core2 | .102 / .103 | 102 / 103 | 192.168.255.102 / .103 | DC1 측 코어 (RR / PE) |
| s2-spine1 / s2-spine2 | .20 / .21 | 20 / 21 | 192.168.255.20 / .21 | DC2 spine |
| s2-leaf1 ~ s2-leaf4 | .22 ~ .25 | 22 ~ 25 | 192.168.255.22 ~ .25 | DC2 l3leaf |
| s2-brdr1 / s2-brdr2 | .200 / .201 | 200 / 201 | 192.168.255.200 / .201 | DC2 Border Leaf |
| s2-core1 / s2-core2 | .202 / .203 | 202 / 203 | 192.168.255.202 / .203 | DC2 측 코어 (RR / PE) |
| s1-host1/2, s2-host1/2 | .16/.17, .26/.27 | — | — | 테스트 엔드포인트 (정적 설정) |

| 대역 | 용도 |
|---|---|
| `192.168.255.0/24` | Loopback0 (Router-ID / SR Router-ID / BGP peering) — 전 장비 공통 |
| `192.168.254.0/24` | Loopback1 (VTEP) — leaf / border leaf |
| `10.0.0.0/24` | MPLS-SR 코어 내부 P2P (ISIS-SR 활성) |
| `172.16.1.0/24` / `172.16.2.0/24` | DC1 / DC2 Border Leaf ↔ 코어 핸드오프 |
| `10.101.0.0/22` / `10.102.0.0/22` | DC1 / DC2 leaf→spine 업링크 P2P |
| `10.101.252.0/23`, `10.101.254.0/23` | DC1 MLAG 피어 / MLAG L3 피어 |
| `10.102.252.0/23`, `10.102.254.0/23` | DC2 MLAG 피어 / MLAG L3 피어 |
| `10.255.16.0/23` | Tenant-A VRF 의 MLAG iBGP 피어링 |
| `10.16.16.0/24` / `10.17.17.0/24` | Tenant-A VLAN 16 / 17 스트레치 서브넷 (애니캐스트 GW `.1`) |

> MLAG / VRF iBGP 피어링 풀이 `/23` 인 이유: 이 풀들은 **node id 를 인덱스로 `/31` 씩 잘라** 씁니다.
> Border Leaf 의 id 가 200/201 이라 `/24`(=`/31` 128개)로는 주소가 모자랍니다.

## Tenant-A — 무엇을 스트레치하는가

`group_vars/DCI_MPLS_SR/tenants.yml` 에 한 번만 정의하고 DC1/DC2 양쪽 leaf 가 같은 정의를 봅니다.

- VRF `tenant-a` (vrf_id 16, VNI 50016)
- VLAN 16 → `10.16.16.0/24`, 애니캐스트 GW `10.16.16.1` (DC1/DC2 동일), L2 VNI 10016
- VLAN 17 → `10.17.17.0/24`, 애니캐스트 GW `10.17.17.1` (DC1/DC2 동일), L2 VNI 10017

DCI 코어(`rr`/`pe`)는 `filter.tenants: []` 로 이 테넌트를 받지 않습니다 — 코어는 VPN 라우트를
중계/반사하고 SR 트랜스포트만 제공하며, 로컬 VRF/SVI 를 갖지 않습니다.

## Border Leaf = 두 개의 게이트웨이를 겸함

`s{1,2}-brdr1/2` 는 서로 다른 두 DCI 경로를 **동시에** 제공합니다. 이게 이 랩의 핵심입니다.

1. **`evpn_gateway` (EVPN-VXLAN 멀티도메인 게이트웨이)**
   상대 DC 의 Border Leaf 와 Loopback0 소스 eBGP EVPN 멀티홉 세션(`EVPN-OVERLAY-REMOTE-PEERS`).
   `evpn_l2` 로 VLAN 16/17 의 Type-2/Type-3 를 재생성하고, `evpn_l3.inter_domain` 으로 IP-Prefix
   경로에 next-hop-self 를 겁니다. 데이터 플레인은 VXLAN 이고, 그 VXLAN 이 MPLS-SR 코어 위를
   IP 로 지나갑니다.

2. **`ipvpn_gateway` (EVPN ↔ IP-VPN 게이트웨이)**
   로컬 코어 2대(AS 1)와 Loopback0 소스 eBGP `vpn-ipv4` 멀티홉 세션(`IPVPN-GATEWAY-PEERS`).
   `tenant-a` 를 IP-VPN(MPLS) 로 내보내 "DCI Remote IP VPN" 경로를 만듭니다.
   `enable_d_path: true` 로 EVPN 도메인(`65x99:1`)과 IP-VPN 도메인(`1:2`) 사이 루프를 막습니다.

### 핸드오프 링크 위에는 BGP 세션이 두 개 올라갑니다

이 부분이 처음 보면 헷갈리는 지점입니다. Border Leaf ↔ 코어 P2P 링크(`172.16.x.x/31`) 하나에:

| 세션 | 피어 그룹 | 소스 | 대상 주소 | 하는 일 |
|---|---|---|---|---|
| 싱글홉 IPv4 unicast | `IPV4-UNDERLAY-PEERS` (BL) / `DCn-UNDERLAY-PEERS` (코어) | 인터페이스 | P2P 주소 | BL 의 Loopback0/Loopback1 광고, 코어 Loopback0 학습 |
| 멀티홉 `vpn-ipv4` | `IPVPN-GATEWAY-PEERS` (BL) / `DCn-GW-PEERS` (코어) | Loopback0 | Loopback0 | IP-VPN 라우트 교환 |

**순서가 중요합니다.** AVD 의 `ipvpn_gateway` 는 Loopback0 를 update-source 로 쓰는 멀티홉 세션을
만들기 때문에, `ipvpn_gateway.remote_peers` 는 P2P 주소가 아니라 **코어의 Loopback0** 를 가리켜야
하고, 그 Loopback0 까지의 IPv4 경로는 싱글홉 세션이 먼저 만들어 줘야 합니다.

그리고 싱글홉 세션이 실어 나르는 Border Leaf Loopback0/Loopback1 은 코어의 iBGP(ipv4 unicast)를
타고 반대편 DC 까지 전달됩니다 — 이게 있어야 1번의 멀티도메인 EVPN 세션과 VXLAN 터널이 성립합니다.
그래서 `DCI_CORE.yml` 의 `custom_structured_configuration_router_bgp` 에서 iBGP 오버레이 피어
그룹에 `address-family ipv4` 를 활성화합니다.

### MPLS 도메인 경계 — SR 과 LDP 를 나눠 쓰는 이유

- **코어 내부**(`10.0.0.0/24` 링크)는 요구사항대로 **순수 ISIS Segment Routing** 입니다.
  LDP 없음. Node-SID 는 Loopback0 에 `node-segment ipv4 index <id>`, TI-LFA(link protection) 활성.
- **핸드오프 링크**에만 **LDP** 를 켭니다. Border Leaf 는 ISIS/SR 를 돌리지 않는 EVPN-VXLAN 패브릭
  장비이므로, 코어가 Border Leaf 의 Loopback0(= `vpn-ipv4` next-hop)를 라벨로 resolve 하려면
  도메인 경계에서 LDP 가 필요합니다. 반대 방향(BL → 코어 Loopback0)도 마찬가지입니다.
- 핸드오프 인터페이스는 코어 쪽에서 **ISIS passive** 로 넣습니다. Border Leaf 와 인접(adjacency)은
  맺지 않지만 `172.16.x.x/31` 프리픽스가 SR 도메인 IGP 에 실려서, 반대편 코어가 이 주소를
  next-hop 으로 갖는 eBGP 경로를 resolve 할 수 있습니다.

## 물리 배선

ATD 장비 배선은 고정이며, `group_vars/DCI_MPLS_SR/dci_topology.yml` 의 `core_interfaces` 가 이를
그대로 반영합니다 (기존 `sites/dc1/dci_configs/*.cfg` 의 배선과 동일).

| 링크 | 인터페이스 | 프로파일 |
|---|---|---|
| s1-core1 ↔ s1-core2 | Et1↔Et1, Et6↔Et6 | `SR_CORE` (ISIS-SR) |
| s2-core1 ↔ s2-core2 | Et1↔Et1, Et6↔Et6 | `SR_CORE` |
| s1-core1 ↔ s2-core1 | Et4↔Et4 | `SR_CORE` (광역 DCI) |
| s1-core2 ↔ s2-core2 | Et4↔Et4 | `SR_CORE` (광역 DCI) |
| s{n}-brdr1 ↔ s{n}-core1 / core2 | Et4→core1 Et2, Et5→core2 Et2 | `DCI_HANDOFF` |
| s{n}-brdr2 ↔ s{n}-core1 / core2 | Et4→core1 Et3, Et5→core2 Et3 | `DCI_HANDOFF` |
| leaf → spine | Et2/Et3 → spine Et2~Et5 | AVD 자동 |
| brdr → spine | Et2/Et3 → spine Et7/Et8 | AVD 자동 |
| host → leaf | host Et1/Et2 → leaf Et4 (MLAG Po1) | AVD 자동(leaf 쪽) |

코어 간 링크가 2개씩인 것은 SR 의 ECMP / TI-LFA 우회를 보여주기 위한 것입니다.

## 파일 구성

```
sites/dci-mpls-sr/
├── inventory.yml                     # 3개 도메인 + 정적 설정 호스트
├── group_vars/
│   ├── DCI_MPLS_SR/                  # 전 장비 공통 (= fabric_name 상위 그룹)
│   │   ├── main.yml                  #   fabric_name, 접속정보, MGMT, cv tags
│   │   ├── vault.yml                 #   랩 비밀번호 (ansible-vault, gitignore)
│   │   ├── dci_topology.yml          #   core_interfaces (링크 양쪽이 다 봐야 하므로 최상위)
│   │   ├── tenants.yml               #   Tenant-A (DC1/DC2 공유)
│   │   └── ports.yml                 #   servers: (leaf 쪽 호스트 포트 자동 생성)
│   ├── DC1_FABRIC.yml / DC2_FABRIC.yml   # spine/l3leaf/border leaf 노드 정의
│   ├── DCI_CORE.yml                  # ISIS-SR + iBGP RR/PE 코어
│   └── DC{1,2}_{SPINES,LEAFS,BORDER_LEAFS}.yml, DCI_CORE_{RR,PE}.yml  # 자리표시자
├── host_configs/*.cfg                # s{1,2}-host1/2 정적 설정 (AVD 대상 아님)
├── intended/                         # 빌드 산출물 — 직접 수정하지 말 것
└── documentation/                    # 빌드 산출물 (fabric md + topology/p2p CSV)
```

## 사용법

```bash
# 0) 최초 1회 - 랩 비밀번호를 vault 로 암호화 (루트 README 환경설정 절차와 동일)
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml | grep "password:" | awk '{print $2}'`
ansible-vault encrypt_string "$LABPASSPHRASE" --name 'vault_ansible_password' \
  > sites/dci-mpls-sr/group_vars/DCI_MPLS_SR/vault.yml

# 1) 빌드 - DC1 + DC2 + 코어를 한 번에
make build_dci_mpls_sr

# 2) 배포 (택 1)
make deploy_dci_mpls_sr_cvp     # CVP 경유, change control 자동 생성/실행
make deploy_dci_mpls_sr_eapi    # eAPI 직접 push

# 3) 테스트 엔드포인트 정적 설정
make deploy_dci_mpls_sr_hosts_cvp

# 4) 검증
make verify_dci_mpls_sr         # ANTA (설정 변경 없음, 리포트는 anta/reports/)
```

`group_vars/**` 를 수정하면 항상 `make build_dci_mpls_sr` 를 다시 돌리고
`intended/configs/*.cfg` 의 diff 를 확인하세요. `intended/` 와 `documentation/` 은 산출물이므로
직접 편집하지 않습니다.

## 동작 확인

```bash
# ---- SR 언더레이 (코어) ----
ssh arista@192.168.0.102
show isis segment-routing prefix-segments      # Node-SID 가 4개 코어 전부 보여야 함
show isis neighbors                            # 코어 내부 인접 (핸드오프는 passive 라 안 나옴)
show mpls lfib route                           # SR 라벨 + LDP 라벨
show bgp vpn-ipv4 summary                      # BL 4대(멀티홉) + iBGP RR/Client

# ---- Border Leaf ----
ssh arista@192.168.0.100
show bgp summary                               # spine 2, core 2(싱글홉), MLAG peer
show bgp vpn-ipv4 summary                      # core 2 (멀티홉, Loopback0 소스)
show bgp evpn summary                          # spine 2 + 상대 DC BL 2 (REMOTE-PEERS)
show ip route 192.168.255.200                  # 상대 DC BL 의 Loopback0 가 보여야 함
show bgp evpn route-type ip-prefix vrf tenant-a

# ---- 엔드포인트 (VRF 지정 필수) ----
ssh arista@192.168.0.16                        # s1-host1
ping vrf 16 10.16.16.21                        # -> s2-host1 (DC 간 L2 스트레치)
ping vrf 16 10.16.16.22                        # -> s2-host2
ping vrf 17 10.17.17.21
```

엔드포인트의 VLAN 16/17 SVI 는 각각 로컬 VRF `16` / `17` 에 들어 있고 leaf 애니캐스트 GW 로
디폴트 라우트가 잡혀 있습니다. 따라서 **`ping` 은 반드시 `vrf` 를 지정**해야 합니다
(default VRF 에서는 통하지 않습니다).

| 엔드포인트 | VLAN 16 | VLAN 17 | 부착 leaf |
|---|---|---|---|
| s1-host1 | 10.16.16.11 | 10.17.17.11 | s1-leaf1 / s1-leaf2 |
| s1-host2 | 10.16.16.12 | 10.17.17.12 | s1-leaf3 / s1-leaf4 |
| s2-host1 | 10.16.16.21 | 10.17.17.21 | s2-leaf1 / s2-leaf2 |
| s2-host2 | 10.16.16.22 | 10.17.17.22 | s2-leaf3 / s2-leaf4 |
