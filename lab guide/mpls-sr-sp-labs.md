# MPLS-SR 서비스 프로바이더 랩 가이드

AVD로 **ISIS Segment Routing MPLS 코어**를 만들고, 그 위에 서비스 프로바이더가 실제로 파는
**L3VPN / L2VPN(E-LAN) / E-LINE(VPWS) / 공용 서비스(익스트라넷)** 4종을 한꺼번에 올리는 실습입니다.
최종 목표는 고객별로 **통해야 할 곳은 통하고, 격리돼야 할 곳은 막히는 것**을 눈으로 확인하는 것입니다.

- 대상 site: `sites/mpls-sr-sp`
- 전제: 저장소 루트 `README.md`의 환경 설정(collection / pyavd 설치)이 끝나 있어야 합니다.
- **주의**: 이 랩은 `sites/dci-sr-evpn`과 **같은 물리 장비(eos1~eos20)** 를 씁니다.
  한 번에 하나만 배포할 수 있고, 다른 랩을 배포하면 이 랩 설정은 덮어써집니다.

> **이 문서의 모든 명령과 출력 예시는 2026-08-07에 실제 랩(AVD 6.3.0 / cEOS 4.36.0.1F)에서
> 직접 실행해 확인한 것입니다.** 출력의 카운터·타이머·MAC 주소는 당연히 달라지지만, 구조와
> 라벨 값(900001~900008 등)은 같아야 합니다. 3장 TASK 8의 검증 매트릭스 12개 항목은
> 기대치와 실측이 전부 일치했습니다.

---

## 0. 이 랩에서 배우는 것

| 개념 | 왜 중요한가 |
|---|---|
| ISIS Segment Routing (SR-MPLS) | LDP 없이 IGP만으로 라벨 경로를 만든다. Node-SID = 목적지 대표 라벨 |
| MPLS 데이터 플레인 | 서비스 라벨(VPN) + 전송 라벨(SR) 2단 스택으로 고객 트래픽을 나른다 |
| TI-LFA | SR 경로 계산 기반의 50ms급 백업 경로. LFA와 달리 우회 불가 구간이 없다 |
| iBGP RR 계층 | RR 2대 + RR Client 6대. PE 풀메시(15세션)를 8세션으로 줄인다 |
| L3VPN (vpn-ipv4) | VRF + RD/RT로 고객별 라우팅 테이블을 분리. PE–CE는 eBGP |
| L2VPN / E-LAN (EVPN over MPLS) | VXLAN 없이 MPLS로 나르는 멀티포인트 L2 서비스 |
| EVPN Ethernet Segment (ESI) | CE 한 대를 PE 두 대에 all-active 듀얼호밍. STP 없이 루프 방지 |
| E-LINE (EVPN VPWS) | 포인트 투 포인트 pseudowire. 두 CE가 직결된 것처럼 보인다 |
| Route Target 조작 | 익스트라넷(공용 서비스 허브)과 고객 간 격리를 RT import/export만으로 구현 |

---

## 1. 토폴로지

### 1-1. 논리 구성

```
                     ┌───────────────── SP 코어 : ISIS-SR + MPLS, iBGP AS 65000 ─────────────────┐
                     │                                                                            │
 CUST1  eos11 ──── [ eos1 ]                                                    [ eos8 ] ──── eos15  CUST1
 CUST3  eos17 ──── [ PE   ]                                                    [ PE   ] ──── eos18  CUST4
                     │  ╲                                                       ╱  │  ╲──── eos14  CUST2 (LAG)
                     │    ╲          [ eos2 : RR ]═══[ eos5 : RR ]            ╱    │
 CUST1  eos13 ──── [ eos6 ]  ────────────┼───────────────┼─────────────  [ eos4 ] ──── eos16  CUST3
 CUST2  eos14 ──── [ PE   ]              │               │                [ PE   ] ──── eos9   CUST2 (LAG)
                     │                   │               │                   │
 CUST2  eos10 ──── [ eos7 ]──────────────┴───────────────┴────────────────[ eos3 ] ──── eos20  CENTRAL
 CUST4  eos19 ──── [ PE   ]                                                [ PE   ] ──── eos9   CUST2 (LAG)
                     │                                                                            │
                     └────────────────────────────────────────────────────────────────────────────┘

  ═══ RR ↔ RR 풀메시 (RR-OVERLAY-PEERS)
  ─── PE → RR 2대 (MPLS-OVERLAY-PEERS, route-reflector-client)
```

- **코어 8대(eos1~eos8)** 만 AVD가 관리합니다. 전부 하나의 SR 도메인(ISIS `CORE`, area 49.0001, level-2)
  이고 하나의 BGP AS(65000)입니다.
- **eos2 / eos5** 는 고객 회선이 없는 중앙 2대라 **RR**(node type `rr`)로, 나머지 6대는
  **PE**(node type `pe`, RR Client)로 배치했습니다.
- **eos9~eos20** 은 고객 CE입니다. AVD 대상이 아니고 `ce_configs/*.cfg` 델타를 merge합니다.

### 1-2. 장비 매핑 (관리 IP는 바꾸지 않습니다)

관리 IP 규칙: `eos<N> = 192.168.0.<9+N>`

| 역할 | 장비 | 관리 IP | Loopback0 | Node SID | AVD node type |
|---|---|---|---|---|---|
| RR | eos2 | 192.168.0.11 | 2.2.2.2 | 2 | `rr` |
| RR | eos5 | 192.168.0.14 | 5.5.5.5 | 5 | `rr` |
| PE | eos1 | 192.168.0.10 | 1.1.1.1 | 1 | `pe` |
| PE | eos3 | 192.168.0.12 | 3.3.3.3 | 3 | `pe` |
| PE | eos4 | 192.168.0.13 | 4.4.4.4 | 4 | `pe` |
| PE | eos6 | 192.168.0.15 | 6.6.6.6 | 6 | `pe` |
| PE | eos7 | 192.168.0.16 | 7.7.7.7 | 7 | `pe` |
| PE | eos8 | 192.168.0.17 | 8.8.8.8 | 8 | `pe` |
| CE | eos9 ~ eos20 | 192.168.0.18 ~ .29 | `N.N.N.N` | — | (AVD 대상 아님) |

> **핵심 규칙** — 노드 `id` = 관리 IP 마지막 옥텟 − 9. 여기서 `Loopback0 = <id>.<id>.<id>.<id>/32`,
> `node-segment ipv4 index <id>`, ISIS NET system-id(Loopback0에서 파생, `1.1.1.1` → `0010.0100.1001`)
> 가 전부 나옵니다. P2P 링크는 `10.<낮은ID>.<높은ID>.<자기ID>/24`.

### 1-3. SP 코어 링크 15개 (실제 LLDP 확인값, 전부 ISIS-SR + `mpls ip`)

| A | 포트 | B | 포트 | 서브넷 |
|---|---|---|---|---|
| eos1 | Et1 | eos2 | Et5 | 10.1.2.0/24 |
| eos1 | Et2 | eos7 | Et3 | 10.1.7.0/24 |
| eos1 | Et4 | eos6 | Et4 | 10.1.6.0/24 |
| eos1 | Et5 | eos5 | Et4 | 10.1.5.0/24 |
| eos2 | Et1 | eos3 | Et3 | 10.2.3.0/24 |
| eos2 | Et2 | eos4 | Et4 | 10.2.4.0/24 |
| eos2 | Et3 | eos5 | Et3 | 10.2.5.0/24 |
| eos2 | Et4 | eos6 | Et5 | 10.2.6.0/24 |
| eos3 | Et2 | eos7 | Et1 | 10.3.7.0/24 |
| eos3 | Et4 | eos5 | Et2 | 10.3.5.0/24 |
| eos3 | Et5 | eos4 | Et5 | 10.3.4.0/24 |
| eos4 | Et2 | eos8 | Et1 | 10.4.8.0/24 |
| eos4 | Et3 | eos5 | Et1 | 10.4.5.0/24 |
| eos5 | Et5 | eos6 | Et1 | 10.5.6.0/24 |
| eos6 | Et2 | eos8 | Et3 | 10.6.8.0/24 |

### 1-4. 고객 회선 (PE ↔ CE)

| 서비스 | PE:포트 | CE:포트 | 서브넷 / VLAN | CE AS |
|---|---|---|---|---|
| CUST1 L3VPN | eos1:Et3 | eos11:Et1 | 10.1.11.0/24 | 65011 |
| CUST1 L3VPN | eos6:Et3 | eos13:Et1 | 10.6.13.0/24 | 65013 |
| CUST1 L3VPN | eos8:Et2 | eos15:Et1 | 10.8.15.0/24 | 65015 |
| CUST2 L2VPN | eos8:Et4 + eos6:Et6 | eos14:Et1,Et2 (LAG) | VLAN 100 / 10.0.0.14 | — |
| CUST2 L2VPN | eos4:Et1 + eos3:Et1 | eos9:Et1,Et2 (LAG) | VLAN 100 / 10.0.0.9 | — |
| CUST2 L2VPN | eos7:Et2 | eos10:Et1 (단일) | VLAN 100 / 10.0.0.10 | — |
| CUST3 E-LINE | eos1:Et6 | eos17:Et1 | 10.16.17.0/24 | — |
| CUST3 E-LINE | eos4:Et6 | eos16:Et1 | 10.16.17.0/24 | — |
| CUST4 L3VPN | eos8:Et5 | eos18:Et1 | 10.8.18.0/24 | 65018 |
| CUST4 L3VPN | eos7:Et4 | eos19:Et1 | 10.7.19.0/24 | 65019 |
| CENTRAL L3VPN | eos3:Et6 | eos20:Et1 | 10.3.20.0/24 | 65020 |

**eos12** 는 PE 직결이 없습니다. 고객 내부 링(eos11–eos12–eos13)으로만 붙는 CE(AS 65012)로,
"고객망 안쪽 라우터의 경로도 L3VPN을 타고 원격 사이트까지 가는가"를 확인하는 용도입니다.

### 1-5. 서비스 요약

| 서비스 | 종류 | VRF / VLAN | RD (PE별) | RT | 참여 CE |
|---|---|---|---|---|---|
| Customer 1 | L3VPN | VRF `CUST1` (vrf_id 101) | `<Lo0>:101` | export 101:101 / import 101:101 + **199:199** | eos11, eos12, eos13, eos15 |
| Customer 2 | L2VPN (E-LAN) | VLAN 100 | `<Lo0>:10100` | 10100:10100 | eos9, eos10, eos14 |
| Customer 3 | E-LINE (VPWS) | vpws `SP`, id 316↔317 | `<Lo0>:500` | 500:500 | eos16, eos17 |
| Customer 4 | L3VPN | VRF `CUST4` (vrf_id 104) | `<Lo0>:104` | export 104:104 / import 104:104 + **199:199** | eos18, eos19 |
| Centralized | L3VPN | VRF `CENTRAL` (vrf_id 199) | `<Lo0>:199` | export 199:199 / import 199:199 + **101:101** + **104:104** | eos20 |

→ CUST1과 CUST4는 각각 공용 서비스(eos20)를 보지만 **서로의 RT는 import하지 않으므로 격리**됩니다.
이것이 이 랩의 마지막 확인 포인트입니다.

VLAN 100은 `tags: ['cust2']`로 표시되어 있고, PE 노드의 `filter.tags`로 실제 Customer 2 회선이 있는
PE(eos3/4/6/7/8)에만 내려갑니다. **eos1에는 VLAN 100이 없습니다** — 의도된 동작입니다.

---

## 2. 실습 진행

### STEP 0 — vault 준비 (최초 1회)

```bash
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml | grep "password:" | awk '{print $2}'`
ansible-vault encrypt_string "$LABPASSPHRASE" --name 'vault_ansible_password' \
  > sites/mpls-sr-sp/group_vars/MPLS_SR_SP/vault.yml
```

`.vault_pass.txt`가 없다면 먼저 만들어야 합니다(저장소 루트 `README.md` 참고).

### STEP 1 — 빌드

```bash
make build_mpls_sr_sp
```

`sites/mpls-sr-sp/intended/configs/*.cfg` 8개(eos1~eos8)와 `documentation/`이 생성됩니다.
**배포 전에 생성된 설정을 반드시 눈으로 확인하세요.** 이 랩의 핵심은 "AVD 입력이 어떤 EOS 설정으로
바뀌는가"를 이해하는 것입니다.

```bash
# SR 언더레이
sed -n '/^router isis/,/^!$/p' sites/mpls-sr-sp/intended/configs/eos1.cfg

# RR 쪽 오버레이 (route-reflector-client + RR 풀메시 두 피어그룹)
sed -n '/^router bgp/,/^!$/p' sites/mpls-sr-sp/intended/configs/eos2.cfg

# PE 쪽: VRF 3개 + VLAN 100 EVPN + VPWS
sed -n '/^router bgp/,/^!$/p' sites/mpls-sr-sp/intended/configs/eos8.cfg
sed -n '/^patch panel/,/^!$/p' sites/mpls-sr-sp/intended/configs/eos1.cfg
```

### STEP 2 — 코어 배포 (eos1~eos8)

```bash
make deploy_mpls_sr_sp_cvp      # CVP 경유, change control 자동 생성/실행
# 또는
make deploy_mpls_sr_sp_eapi     # eAPI 직접 push
```

### STEP 3 — 고객 CE 배포 (eos9~eos20)

```bash
make deploy_mpls_sr_sp_ce
```

CE 설정은 **델타**입니다. 인터페이스 IP와 Loopback0는 랩에 이미 배정돼 있으므로 여기서는
BGP와 LACP LAG만 얹습니다(`arista.eos.eos_config` merge — 기존 설정을 지우지 않습니다).

> **이 단계를 건너뛰면** L3VPN 3종(CUST1/CUST4/CENTRAL)은 CE에 BGP가 없어서 경로가 하나도 안 올라오고,
> Customer 2 듀얼호밍(eos9/eos14)은 CE 쪽 Port-Channel이 없어 PE의 ESI 포트가
> `waiting for LACP response` 상태로 남습니다. E-LINE(Customer 3)만 CE 설정 없이도 동작합니다.

### STEP 4 — 검증

```bash
make verify_mpls_sr_sp          # ANTA (설정 변경 없음)
```

리포트는 `sites/mpls-sr-sp/anta/reports/`에 md / csv / json으로 떨어집니다.

**실측 결과 (2026-08-07, 전체 배포 완료 상태)** — 총 224건 중 성공 152 / 스킵 56 / 실패 16:

| 카테고리 | 성공 | 스킵 | 실패 |
|---|---|---|---|
| bgp | 8 | 0 | 0 |
| configuration | 16 | 0 | 0 |
| connectivity | 16 | 0 | 0 |
| interfaces | 48 | 0 | 0 |
| routing | 8 | 0 | 0 |
| stp | 8 | 0 | 0 |
| hardware | 0 | **56** | 0 |
| logging | 0 | 0 | **8** |
| system | 48 | 0 | **8** |

실패 16건은 전부 **cEOS / ATD 파드 환경 때문이며 설정 오류가 아닙니다**:

- `VerifyLoggingErrors` × 8 — 부팅 시 `%HARDWARE-0-SYSTEM_IDENTIFICATION_FAILED`
  (컨테이너라 물리 시스템 식별 실패). 지워도 재부팅하면 다시 생깁니다.
- `VerifyMemoryUtilization` × 8 — 공용 파드 호스트 메모리 사용률 77~79% (임계값 75%).

스킵 56건은 Hardware 계열(온도/전원/냉각/트랜시버/인벤토리)로, `test is not supported on cEOSLab`입니다.

> ANTA 실패가 하나라도 있으면 `make verify_mpls_sr_sp`는 **exit code 2**로 끝나고
> `make: *** [Makefile:31: verify_mpls_sr_sp] Error 2`가 출력됩니다. 위 16건만 남았다면 정상입니다.
> **bgp / connectivity / configuration / routing / interfaces / stp가 전부 성공**인지를 보세요.

실패 항목을 자세히 보려면:

```bash
python3 -c "
import json
for r in json.load(open('sites/mpls-sr-sp/anta/reports/anta_report.json')):
    if r['result']=='failure': print(r['name'], r['test'], r['messages'])
"
```

---

## 3. TASK별 확인 포인트

접속: `ssh arista@192.168.0.<9+N>` (비밀번호 = 랩 패스프레이즈)

### TASK 1 — SR 언더레이가 올라왔는가

```bash
ssh arista@192.168.0.10          # eos1 (PE)

show isis neighbors
#  -> eos2 / eos5 / eos6 / eos7 4개 인접이 L2 / UP
```
```
Instance  VRF      System Id  Type Interface   SNPA  State Hold time  Circuit Id
CORE      default  eos2       L2   Ethernet1   P2P   UP    21         46
CORE      default  eos5       L2   Ethernet5   P2P   UP    27         4E
CORE      default  eos6       L2   Ethernet4   P2P   UP    23         4C
CORE      default  eos7       L2   Ethernet2   P2P   UP    24         48
```

```bash
show isis segment-routing prefix-segments
#  -> Node SID 8개. Label = 900000 + Node ID  (eos3 = 900003)
```
```
   Prefix        SID   Label   Type   ...  System ID  Level  Protection
*  1.1.1.1/32      1  900001   Node        eos1       L2     unprotected
   2.2.2.2/32      2  900002   Node        eos2       L2     link
   3.3.3.3/32      3  900003   Node        eos3       L2     ECMP
   ...
   8.8.8.8/32      8  900008   Node        eos8       L2     link
```

**왜 이렇게 되는가** — `underlay_routing_protocol: isis-sr` + `underlay_isis_instance_name: CORE`가
`router isis CORE` + `segment-routing mpls`를 만들고, 각 노드 Loopback0의
`node-segment ipv4 index <id>`가 그 노드를 대표하는 prefix-SID를 광고합니다.
**LDP가 한 줄도 없는데 라벨 경로가 생기는 것**이 SR의 핵심입니다.
`Protection` 열이 `link` / `ECMP`인 것은 TI-LFA 백업이 계산됐다는 뜻입니다.

```bash
show ip route | include /32
#  -> 다른 7개 노드의 Loopback0가 "I L2"(ISIS level-2)로 보여야 함
show isis segment-routing adjacency-segments      # 링크별 Adj-SID
show mpls segment-routing bindings                # 라벨 바인딩 (로컬 + 원격)
```

### TASK 2 — MPLS 데이터 플레인과 TI-LFA

```bash
show mpls lfib route
#  -> 900001~900008 전송 라벨 엔트리 + 서비스 라벨 엔트리
show isis segment-routing tunnel
```
```
  Index  Endpoint      Next Hop/Tunnel Index   Interface    Labels
  1      5.5.5.5/32    TI-LFA (2)              -            [ 3 ]
  3      4.4.4.4/32    10.1.2.2                Ethernet1    [ 900004 ]
                       10.1.5.5                Ethernet5    [ 900004 ]
  4      3.3.3.3/32    10.1.2.2                Ethernet1    [ 900003 ]
                       10.1.5.5                Ethernet5    [ 900003 ]
                       10.1.7.7                Ethernet2    [ 900003 ]
```

- 직결 이웃(`5.5.5.5`)은 라벨 `3`(implicit-null, PHP)이고 백업만 TI-LFA로 계산돼 있습니다.
- 원격 노드는 Node SID 라벨을 붙여 **여러 경로로 ECMP** 됩니다(`isis_maximum_paths: 4`).

```bash
show isis ti-lfa path
#  -> 목적지별로 "exclude <인터페이스>" 조건의 백업 경로
```

**왜 이렇게 되는가** — `isis_ti_lfa: {enabled: true, protection: link}`가
`fast-reroute ti-lfa mode link-protection`을 만듭니다. 링크 하나가 끊겨도 IGP 재수렴을 기다리지 않고
미리 계산된 백업 라벨 스택으로 즉시 우회합니다.

### TASK 3 — 오버레이(iBGP RR)가 붙었는가

RR 계층 구조를 양쪽에서 확인합니다.

```bash
ssh arista@192.168.0.11          # eos2 (RR)
show bgp summary
#  -> PE 6대(1.1.1.1, 3.3.3.3, 4.4.4.4, 6.6.6.6, 7.7.7.7, 8.8.8.8) = MPLS-OVERLAY-PEERS
#  -> RR 1대(5.5.5.5)                                              = RR-OVERLAY-PEERS
#  -> 각각 IPv4 MplsVpn / L2VPN EVPN 두 AFI가 Negotiated
```

```bash
ssh arista@192.168.0.10          # eos1 (PE)
show bgp evpn summary
show bgp vpn-ipv4 summary
```
```
  Description        Neighbor  V AS      MsgRcvd MsgSent ... State  PfxRcd PfxAcc PfxAdv
  eos2_Loopback0     2.2.2.2   4 65000       229     220     Estab  6      6      1
  eos5_Loopback0     5.5.5.5   4 65000       229     221     Estab  6      6      1
```

(PfxRcd 값은 배포 진행 상황에 따라 달라집니다. **RR 2대 모두 `Estab`** 인지가 핵심입니다.)

**PE는 RR 2대만 봅니다.** PE 6대 풀메시라면 15세션이 필요하지만, RR 계층에서는 PE당 2세션 + RR간 1세션
= 13세션이고 PE가 늘어도 PE당 2세션으로 고정됩니다.

설정에서 눈여겨볼 부분:

| 줄 | 의미 |
|---|---|
| `neighbor MPLS-OVERLAY-PEERS route-reflector-client` (RR에만) | 이 피어들의 경로를 다른 클라이언트에 반사 |
| `bgp cluster-id 2.2.2.2` (RR에만) | 반사 루프 방지. RR 2대가 서로 다른 cluster-id를 씁니다 |
| `neighbor default encapsulation mpls` | EVPN을 VXLAN이 아니라 **MPLS**로 캡슐화 (`fabric_evpn_encapsulation: mpls`) |
| `next-hop-self source-interface Loopback0` (PE에만) | next-hop을 SR 엔드포인트 Loopback0로 → 상대가 Node SID 라벨로 resolve |
| `update-source Loopback0` | 물리 링크가 아니라 Loopback0 간 세션이므로 TASK 1이 먼저 성공해야 함 |

### TASK 4 — Customer 1 L3VPN

```bash
ssh arista@192.168.0.10          # eos1 (PE, CUST1)

show bgp vpn-ipv4
#  -> RD별로 각 PE가 광고한 고객 경로. RD = <PE Loopback0>:<vrf_id>
```
```
 * >      RD: 1.1.1.1:101 IPv4 prefix 10.1.11.0/24      -         (자기 경로)
 * >Ec    RD: 6.6.6.6:101 IPv4 prefix 10.6.13.0/24      6.6.6.6   Or-ID: 6.6.6.6 C-LST: 2.2.2.2 5.5.5.5
 * >Ec    RD: 8.8.8.8:101 IPv4 prefix 10.8.15.0/24      8.8.8.8   Or-ID: 8.8.8.8 C-LST: 2.2.2.2 5.5.5.5
 * >Ec    RD: 3.3.3.3:199 IPv4 prefix 10.3.20.0/24      3.3.3.3   Or-ID: 3.3.3.3 C-LST: 2.2.2.2
```

> `Or-ID`(Originator ID)와 `C-LST`(Cluster List)가 보이면 **RR을 거쳐 온 경로**라는 뜻입니다.
> 같은 경로가 RR 2대로부터 두 벌 오기 때문에 `E`/`e`(ECMP) 표시가 붙습니다.

> **주의**: `show bgp vpn-ipv4 vrf CUST1`은 없는 명령입니다.
> VRF 단위로 보려면 `show bgp ipv4 unicast vrf CUST1`을 쓰세요.

```bash
show ip route vrf CUST1
```
```
 C        10.1.11.0/24
           directly connected, Ethernet3
 B I      10.3.20.0/24 [200/0]
           via 3.3.3.3/32, IS-IS SR tunnel index 4, label 100000
              via 10.1.2.2, Ethernet1, label 900003
              via 10.1.5.5, Ethernet5, label 900003
              via 10.1.7.7, Ethernet2, label 900003
 B E      11.11.11.11/32 [20/0]
           via 10.1.11.11, Ethernet3
 B E      12.12.12.12/32 [20/0]
           via 10.1.11.11, Ethernet3
 B I      13.13.13.13/32 [200/0]
           via 6.6.6.6/32, IS-IS SR tunnel index 5, label 100000
              via TI-LFA tunnel index 5, label imp-null(3)
                 via 10.1.6.6, Ethernet4, label imp-null(3)
                 backup via 10.1.2.2, Ethernet1, label 900006
 B I      15.15.15.15/32 [200/0]
           via 8.8.8.8/32, IS-IS SR tunnel index 7, label 100000
              via TI-LFA tunnel index 7, label 900008
                 via 10.1.6.6, Ethernet4, label imp-null(3)
                 backup via 10.1.5.5, Ethernet5, label imp-null(3)
 B I      20.20.20.20/32 [200/0]
           via 3.3.3.3/32, IS-IS SR tunnel index 4, label 100000
              ... (3-way ECMP)
```

**이 출력이 L3VPN의 전부입니다.** 읽는 법:

| 표시 | 의미 |
|---|---|
| `B E ... via 10.1.11.11, Ethernet3` | eBGP로 **직결 CE**에게 받은 경로. 라벨 없음 |
| `B I ... IS-IS SR tunnel, label 100000` | iBGP(RR 경유) 원격 PE 경로. `100000`은 **VPN 서비스 라벨**(어느 VRF로 넣을지) |
| `via 10.1.2.2, Ethernet1, label 900003` | 바깥쪽 **SR 전송 라벨**(어느 PE로 갈지). 여기선 3-way ECMP |
| `label imp-null(3)` | 직결 이웃이라 PHP(penultimate hop popping) — 전송 라벨을 안 붙임 |
| `backup via ..., label 900006` | **TI-LFA 백업 경로**가 라우팅 테이블에 미리 설치돼 있음 |

라벨이 **두 장 스택**된다는 점이 핵심입니다. 코어 P 라우터는 바깥 전송 라벨만 보고 스위칭하며
고객 VRF의 존재조차 모릅니다.

`12.12.12.12/32`가 보이는 것도 중요합니다 — eos12는 PE 직결이 없는 **고객망 안쪽 라우터**인데,
eos11이 고객 내부 링에서 배운 경로를 PE로 재광고해서 L3VPN 전체에 퍼진 것입니다.

```bash
show bgp ipv4 unicast vrf CUST1        # VRF 관점
show bgp neighbors vrf CUST1           # PE-CE eBGP 세션 상태
```

CE 쪽:

```bash
ssh arista@192.168.0.20          # eos11 (CE, AS 65011)
show ip bgp summary
#  -> 10.1.11.1(PE eos1, AS 65000) + 10.11.12.12(eos12) + 10.11.13.13(eos13)
show ip route
#  -> 15.15.15.15/32 (원격 사이트), 20.20.20.20/32 (공용 서비스)가 PE 방향으로
```

### TASK 5 — Centralized L3VPN(익스트라넷)과 고객 격리

RT import/export만으로 hub-and-spoke 익스트라넷을 만드는 패턴입니다.

```bash
ssh arista@192.168.0.12          # eos3 (PE, CENTRAL)
show running-config section vrf CENTRAL
```
```
   vrf CENTRAL
      rd 3.3.3.3:199
      route-target import vpn-ipv4 101:101      <- Customer 1 경로를 받음
      route-target import vpn-ipv4 104:104      <- Customer 4 경로를 받음
      route-target import vpn-ipv4 199:199
      route-target export vpn-ipv4 199:199      <- 공용 서비스 경로를 내보냄
```

```bash
show ip route vrf CENTRAL
```
```
 B I      10.1.11.0/24     ┐
 B I      10.6.13.0/24     │ Customer 1
 B I      10.8.15.0/24     │
 B I      11.11.11.11/32   │
 B I      12.12.12.12/32   │
 B I      13.13.13.13/32   │
 B I      15.15.15.15/32   ┘
 B I      10.7.19.0/24     ┐
 B I      10.8.18.0/24     │ Customer 4
 B I      18.18.18.18/32   │
 B I      19.19.19.19/32   ┘
 C        10.3.20.0/24       (직결 CE)
 B E      20.20.20.20/32     (eos20이 광고)
```

공용 서비스 VRF 하나에서 **두 고객이 모두 보입니다**. 이제 반대 방향을 확인합니다:

```bash
ssh arista@192.168.0.10 ; show ip route vrf CUST1
#  -> 20.20.20.20/32 (CENTRAL)은 보이지만
#  -> 19.19.19.19/32 / 10.7.19.0/24 (CUST4)는 한 건도 없어야 함  <- 실측: 0건
```

| VRF | export | import | 결과 |
|---|---|---|---|
| `CUST1` | 101:101 | 101:101, 199:199 | 공용 서비스 O, CUST4 X |
| `CUST4` | 104:104 | 104:104, 199:199 | 공용 서비스 O, CUST1 X |
| `CENTRAL` | 199:199 | 199:199, 101:101, 104:104 | 양쪽 고객 모두 O |

**RT는 방향이 있습니다.** CENTRAL이 101:101을 import해도 CUST1이 104:104를 import하지 않는 한
CUST1↔CUST4는 절대 통하지 않습니다. 이 비대칭이 SP 익스트라넷 설계의 핵심입니다.

### TASK 6 — Customer 2 L2VPN (EVPN E-LAN over MPLS)

```bash
ssh arista@192.168.0.17          # eos8 (PE, CUST2)

show bgp evpn instance vlan 100
```
```
EVPN instance: VLAN 100
  Route distinguisher: 8.8.8.8:10100
  Route target import: Route-Target-AS:10100:10100
  Route target export: Route-Target-AS:10100:10100
  Service interface: VLAN-based
  VXLAN: disabled          <- VXLAN이 아니라
  MPLS: enabled            <- MPLS로 나릅니다
  MAC route MPLS label: 1047390
  IMET route MPLS label: 1040999
```

```bash
show bgp evpn route-type imet
#  -> VLAN 100을 가진 PE 5대(3/4/6/7/8)의 IMET 루트. BUM 트래픽 복제 대상 목록입니다.
show bgp evpn route-type mac-ip
#  -> 고객 MAC 학습 결과 (CE가 트래픽을 보내야 생깁니다)
show mac address-table vlan 100
```

듀얼호밍(Ethernet Segment):

```bash
show running-config interfaces Port-Channel4    # eos8, eos14 방향
```
```
   evpn ethernet-segment
      identifier 0000:0000:0375:406d:88c1
      redundancy all-active
      route-target import 03:75:40:6d:88:c1
   lacp system-id 0375.406d.88c1
```

```bash
show bgp evpn route-type ethernet-segment       # Type-4 (ES 라우트) - DF 선출용
```
```
 * >Ec    RD: 6.6.6.6:1 ethernet-segment 0000:0000:0375:406d:88c1 6.6.6.6   <- eos14 ESI, eos6 쪽
 * >      RD: 8.8.8.8:1 ethernet-segment 0000:0000:0375:406d:88c1 8.8.8.8   <- eos14 ESI, eos8 쪽(자기)
 * >Ec    RD: 3.3.3.3:1 ethernet-segment 0000:0000:278f:707a:a872 3.3.3.3   <- eos9  ESI, eos3 쪽
 * >Ec    RD: 4.4.4.4:1 ethernet-segment 0000:0000:278f:707a:a872 4.4.4.4   <- eos9  ESI, eos4 쪽
```

**같은 ESI 값이 PE 두 대에서 각각 광고되는 것**이 듀얼호밍의 증거입니다. 이 Type-4 루트로 두 PE가
서로를 인지하고 DF를 선출합니다. ESI가 두 쌍(eos14용, eos9용) 보이는 것도 확인하세요.

```bash
show bgp evpn route-type auto-discovery         # Type-1 (per-ES / per-EVI)
show bgp evpn route-type mac-ip                 # Type-2
show mac address-table vlan 100
```
```
 100    001c.73b8.c601    DYNAMIC     Mt1        1       0:00:23 ago   <- eos9  (원격, MPLS 터널)
 100    001c.73c3.c601    DYNAMIC     Po4        3       0:00:23 ago   <- eos14 (로컬 ESI 포트)
 100    ae54.0cc8.0b82    DYNAMIC     Mt1        1       0:00:23 ago   <- eos10 (원격, MPLS 터널)
```

포트가 `Mt1`(MPLS 터널 인터페이스)이면 EVPN으로 배운 원격 MAC, `Po4`면 로컬 포트 학습입니다.
eos14의 MAC은 eos8에서 로컬(`Po4`)로도 보이고 `show bgp evpn route-type mac-ip`에는
`RD: 6.6.6.6:10100`으로 eos6이 광고한 것도 함께 보입니다 — all-active라 **두 PE가 같은 MAC을
동시에 광고**하며, 이것이 정상입니다.

```bash
show port-channel 4 detailed                    # LACP가 실제로 물렸는지
show interfaces Port-Channel4 status
```

**왜 이렇게 되는가** — `ports.yml`의 `ethernet_segment: {short_esi: auto, redundancy: all-active}`가
ESI와 **동일한 LACP system-id**를 두 PE(eos8/eos6)에 똑같이 만듭니다. CE(eos14) 입장에서는 하나의
스위치와 LAG를 맺은 것처럼 보이고, PE 두 대는 Type-1/Type-4 루트로 서로를 인지해
**DF(Designated Forwarder)를 선출**하고 BUM 중복 전달과 루프를 막습니다. STP가 전혀 없습니다.

> `show port-channel 4 detailed`가 `waiting for LACP response`라면 CE 델타(STEP 3)가 안 내려간 것입니다.

같은 확인을 eos6(192.168.0.15), eos4(192.168.0.13), eos3(192.168.0.12)에서도 해 보세요.
eos9의 ESI는 eos4/eos3 쌍에 만들어집니다.

```bash
ssh arista@192.168.0.10 ; show vlan 100
#  -> "% VLAN 100 not found" 가 정상입니다. eos1은 filter.tags가 ['cust1']이라 VLAN 100이 없습니다.
```

### TASK 7 — Customer 3 E-LINE (EVPN VPWS pseudowire)

```
eos16 --- eos4:Et6  ==[ MPLS pseudowire, id 316 <-> 317 ]==  eos1:Et6 --- eos17
```

```bash
ssh arista@192.168.0.10          # eos1
show patch panel
```
```
Patch       Connector                             Status Last Change
----------- ------------------------------------- ------ -----------
CUST3-ELINE 1: Ethernet6                          Up     1:46:48 ago
            2: BGP VPWS SP Pseudowire CUST3-ELINE
```

```bash
show bgp evpn instance vpws SP
```
```
EVPN instance: VPWS SP
  Route distinguisher: 1.1.1.1:500
  Route target import/export: Route-Target-AS:500:500
  MPLS: enabled
  Label allocation mode: per-pseudowire
  L2 MTU: 9214
```

```bash
show bgp evpn route-type auto-discovery
#  -> RD: 4.4.4.4:500 auto-discovery 316 ...   (상대편 eos4가 광고한 VPWS 엔드포인트)
show running-config section patch panel
show running-config interfaces Ethernet6        # IP 없음. switchport도 없음. 순수 패치 포트.
```

**왜 이렇게 되는가** — 포트 모드 pseudowire라 Ethernet6에 들어온 프레임을 통째로 라벨에 싸서 상대 PE로
보냅니다. `local 317 remote 316`처럼 양쪽 id가 교차 매칭되어야 pseudowire가 Up이 됩니다.
`pseudowire_rt_base: 500`이 없으면 AVD가 `vpws` 블록 자체를 만들지 않아 patch panel이 참조할 대상이
사라집니다.

E-LINE은 **CE 델타가 없어도 동작합니다**(양 끝 IP가 이미 배정되어 있음):

```bash
ssh arista@192.168.0.25 ; ping 10.16.17.17     # eos16 -> eos17
```

### TASK 8 — 엔드투엔드 검증 매트릭스

STEP 3(CE 배포)까지 끝난 뒤 실행합니다. **✗ 표시는 실패해야 정상입니다.**

아래 "실측"은 **2026-08-07에 이 랩에서 실제로 돌린 결과**입니다(전부 기대치와 일치).

| # | 출발 | 명령 | 기대 | 실측 | 확인하는 것 |
|---|---|---|---|---|---|
| 1 | eos11 (`.0.20`) | `ping 15.15.15.15` | ✓ | 0% loss | CUST1 L3VPN 사이트 간 |
| 2 | eos11 | `ping 13.13.13.13` | ✓ | 0% loss | (고객 내부 링으로도 가므로 참고용) |
| 3 | eos15 (`.0.24`) | `ping 12.12.12.12` | ✓ | 0% loss | 고객망 안쪽 라우터까지 L3VPN 경유 |
| 4 | eos11 | `ping 20.20.20.20` | ✓ | 0% loss | CUST1 → 공용 서비스 (익스트라넷) |
| 5 | eos19 (`.0.28`) | `ping 20.20.20.20` | ✓ | 0% loss | CUST4 → 공용 서비스 |
| 6 | eos20 (`.0.29`) | `ping 11.11.11.11` / `ping 18.18.18.18` | ✓ | 둘 다 0% loss | 공용 서비스 → 양쪽 고객 |
| 7 | **eos11** | **`ping 19.19.19.19`** | **✗** | `Network is unreachable` | **CUST1 ↔ CUST4 격리** |
| 8 | **eos18 (`.0.27`)** | **`ping 15.15.15.15`** | **✗** | `Network is unreachable` | **CUST4 ↔ CUST1 격리** |
| 9 | eos14 (`.0.23`) | `ping 10.0.0.10` | ✓ | 0% loss | CUST2 E-LAN (듀얼호밍 → 단일) |
| 10 | eos14 | `ping 10.0.0.9` | ✓ | 0% loss | CUST2 E-LAN (듀얼호밍 ↔ 듀얼호밍) |
| 11 | eos16 (`.0.25`) | `ping 10.16.17.17` | ✓ | 0% loss | CUST3 E-LINE pseudowire |
| 12 | **eos16** | **`ping 10.0.0.9`** | **✗** | `Network is unreachable` | **E-LINE은 지정된 두 포트만 연결** |

7·8·12번이 **성공하면 그게 버그**입니다. RT 설정이나 VLAN 필터를 다시 보세요.

> 격리 케이스는 `timed out`이 아니라 **`ping: connect: Network is unreachable`** 로 즉시 끝납니다.
> CE의 라우팅 테이블에 목적지 자체가 없다는 뜻이고, 이게 "PE가 애초에 경로를 안 줬다"는 증거입니다.
> 만약 timeout으로 늘어진다면 경로는 있는데 어딘가에서 끊긴 것이므로 **격리가 아니라 장애**입니다.

한 번에 돌리려면 (성공해야 하는 항목들):

```bash
ansible eos11,eos19 -i sites/mpls-sr-sp/inventory.yml -m arista.eos.eos_command \
  -a "commands='ping 20.20.20.20 repeat 2'"
```

격리 테스트는 실패가 정상이므로 Ansible로 돌리면 태스크가 failed로 잡힙니다.
`ssh`로 직접 확인하거나 `ignore_errors`를 쓰세요.

---

## 4. 문제 해결 순서

**아래에서 위로** 올라가며 확인하세요. 하위 계층이 안 되면 상위는 절대 안 됩니다.

| 순서 | 계층 | 명령 | 안 될 때 볼 곳 |
|---|---|---|---|
| 1 | 물리 / IP | `show ip interface brief`, `show lldp neighbors` | `core_topology.yml`의 포트/IP |
| 2 | ISIS 인접 | `show isis neighbors` | MTU 불일치, `isis_circuit_type`, 한쪽만 `include_in_underlay_protocol` |
| 3 | Loopback 도달성 | `show ip route \| include /32` | ISIS area / is-type 불일치 |
| 4 | SR 라벨 | `show isis segment-routing prefix-segments`, `show mpls lfib route` | `node-segment ipv4 index` 중복, `mpls ip` 누락 |
| 5 | iBGP 세션 | `show bgp summary` | 3번 먼저. peer-group 비밀번호(type-7) 불일치 |
| 6 | AFI 협상 | `show bgp vpn-ipv4 summary`, `show bgp evpn summary` | `overlay_address_families` |
| 7 | VPN 경로 수신 | `show bgp vpn-ipv4`, `show bgp evpn` | RT import/export, RD 중복 |
| 8 | VRF 라우팅 | `show ip route vrf CUST1` | 서비스 라벨 resolve 실패 → 4번으로 |
| 9 | PE–CE eBGP | `show bgp neighbors vrf CUST1` | CE 델타 미배포(STEP 3), remote-as 오타 |
| 10 | L2 서비스 | `show bgp evpn route-type imet`, `show port-channel N detailed` | `filter.tags`, CE LACP |
| 11 | 엔드투엔드 | `ping` | 위를 다 통과했다면 CE의 `network` 광고 확인 |

자주 걸리는 지점:

- **5번에서 막힘** — 오버레이 세션은 Loopback0 소스입니다. 3번(ISIS로 Loopback0 도달)이 먼저 되어야 합니다.
  peer-group별 type-7 비밀번호는 **피어그룹 이름으로 키가 걸려** 있어서 `MPLS-OVERLAY-PEERS`와
  `RR-OVERLAY-PEERS`가 각각 다른 암호문이어야 합니다(같은 평문이라도).
- **9번에서 막힘** — 십중팔구 `make deploy_mpls_sr_sp_ce`를 안 돌린 것입니다.
  `ssh arista@192.168.0.20 ; show ip bgp summary`가 "could not run command"면 CE에 BGP 자체가 없습니다.
- **10번에서 ESI가 안 붙음** — `show port-channel 4 detailed`가 `waiting for LACP response`.
  CE 쪽 `channel-group 1 mode active`가 없는 상태입니다.
- **eos1에 VLAN 100이 없다** — 버그가 아니라 `filter.tags: ['cust1']` 때문입니다.

---

## 5. 더 해보기

1. **TI-LFA 수렴 측정** — eos1에서 eos4로 가는 경로를 확인한 뒤(`show isis segment-routing tunnel`)
   주 경로 인터페이스를 `shutdown`하고, `ping 10.7.19.19 repeat 1000 interval 0.01`을 돌리며
   손실 패킷 수를 세어 보세요. TI-LFA가 있으면 한 자릿수여야 합니다.
2. **all-active 듀얼호밍 검증** — eos14에서 `ping 10.0.0.10 repeat 1000` 중에 eos8:Et4를 shutdown.
   ESI가 제대로 동작하면 eos6 경로로 넘어가며 거의 끊기지 않습니다.
   `show bgp evpn route-type auto-discovery`로 per-ES 루트가 철회되는 것도 보세요.
3. **RR 이중화** — eos2를 `shutdown`(또는 BGP만 내려도 됨)하고 서비스가 유지되는지 확인.
   경로의 `C-LST`가 5.5.5.5 하나로 바뀌는 것을 관찰하세요.
4. **고객 격리 깨뜨려 보기** — `tenants.yml`의 `CUST1`에 `additional_route_targets`로
   `import 104:104`를 넣고 `make build_mpls_sr_sp` → diff 확인 → 배포 → 7번 테스트가 이제 통하는지.
   **확인 후 반드시 되돌리세요.**
5. **IGP 메트릭으로 경로 유도** — `core_topology.yml`의 특정 링크 프로파일에 `isis_metric`을 크게 주고
   `show isis segment-routing tunnel`의 next-hop이 바뀌는지 보세요.
6. **E-LINE을 VLAN 모드로** — 지금은 포트 모드입니다. `point_to_point_services`의 endpoint에
   `port_vlan_id` / `vlan` 을 주면 하나의 물리 포트에 여러 pseudowire를 태울 수 있습니다.
7. **Customer 2에 L3 게이트웨이 붙이기** — 지금 VLAN 100은 SVI 없는 순수 L2입니다.
   `l2vlans`를 VRF 안의 `svis`로 바꾸면 EVPN IRB(L2+L3)가 됩니다. 생성되는 설정 차이를 비교해 보세요.

---

## 부록 A — AVD 입력이 EOS 설정으로 바뀌는 지점

| 하고 싶은 것 | AVD 입력 파일 / 키 |
|---|---|
| SR 도메인 이름 / area / metric | `group_vars/SP_FABRIC.yml` → `underlay_isis_instance_name`, `isis_area_id`, `isis_default_metric` |
| TI-LFA | `group_vars/SP_FABRIC.yml` → `isis_ti_lfa` |
| EVPN을 MPLS로 나르기 | `group_vars/SP_FABRIC.yml` → `fabric_evpn_encapsulation: mpls` |
| 코어 링크 / P2P IP | `group_vars/MPLS_SR_SP/core_topology.yml` → `core_interfaces.p2p_links` |
| Loopback0 / Node SID | 각 노드의 `id` + `loopback_ipv4_address` |
| RR ↔ Client 관계 | `type: rr` (`CORE_RR.yml`) + 노드 defaults의 `mpls_route_reflectors: [eos2, eos5]` |
| 오버레이 AFI | `overlay_address_families: [vpn-ipv4, evpn]` |
| 피어그룹 이름 / 비밀번호 | `group_vars/SP_FABRIC.yml` → `bgp_peer_groups` |
| L3VPN VRF / PE-CE eBGP | `group_vars/MPLS_SR_SP/tenants.yml` → `vrfs[].l3_interfaces`, `vrfs[].bgp_peers` |
| 익스트라넷 RT | `vrfs[].additional_route_targets` |
| L2VPN VLAN | `tenants.yml` → `l2vlans` + 노드의 `filter.tags` |
| L2 고객 포트 / ESI | `group_vars/MPLS_SR_SP/ports.yml` → `routers[].adapters[].ethernet_segment` |
| E-LINE pseudowire | `tenants.yml` → `point_to_point_services` + `pseudowire_rt_base` |
| CE 설정 | `ce_configs/*.cfg` (AVD 아님. `arista.eos.eos_config` merge) |

`group_vars/**`를 고쳤으면 **항상** `make build_mpls_sr_sp`를 다시 돌리고 `intended/configs/*.cfg`의
diff를 확인하세요. `intended/`와 `documentation/`은 산출물이므로 직접 편집하지 않습니다.

## 부록 B — 자주 쓰는 명령 치트시트

| 목적 | 명령 |
|---|---|
| ISIS 인접 / DB | `show isis neighbors`, `show isis database detail` |
| Node SID | `show isis segment-routing prefix-segments` |
| Adj SID | `show isis segment-routing adjacency-segments` |
| SR 터널 / ECMP | `show isis segment-routing tunnel` |
| TI-LFA 백업 | `show isis ti-lfa path` |
| 라벨 포워딩 | `show mpls lfib route`, `show mpls segment-routing bindings` |
| 오버레이 세션 | `show bgp summary`, `show bgp vpn-ipv4 summary`, `show bgp evpn summary` |
| L3VPN 경로 (전역) | `show bgp vpn-ipv4` |
| L3VPN 경로 (VRF) | `show bgp ipv4 unicast vrf CUST1` ← `show bgp vpn-ipv4 vrf ...` 는 없는 명령 |
| VRF 라우팅 테이블 | `show ip route vrf CUST1` |
| PE-CE 세션 | `show bgp neighbors vrf CUST1` |
| EVPN 인스턴스 | `show bgp evpn instance`, `show bgp evpn instance vlan 100`, `show bgp evpn instance vpws SP` |
| EVPN 루트 타입별 | `show bgp evpn route-type imet \| mac-ip \| ethernet-segment \| auto-discovery \| ip-prefix` |
| 듀얼호밍 | `show port-channel N detailed`, `show lacp neighbor` |
| E-LINE | `show patch panel` |
| L2 학습 | `show mac address-table vlan 100`, `show vlan 100` |
