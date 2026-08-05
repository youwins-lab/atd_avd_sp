# MPLS Segment Routing 서비스 프로바이더 랩 (`sites/mpls-sr-sp`)

ISIS Segment Routing MPLS 코어 위에 **L3VPN / L2VPN(E-LAN) / E-LINE(VPWS)** 서비스를 올리는
20노드 SP 랩입니다. `sites/dc1` / `sites/dc2` / `sites/dci-mpls-sr` 와 완전히 별개의 site 이며,
장비 이름도 `eos1`~`eos20` 으로 다릅니다.

> **이 랩은 `eos1`~`eos20` 로 구성된 ATD Pod 전용입니다.**
> 같은 Pod 에 `s1-*` / `s2-*` 장비가 없으므로 기존 dc1/dc2 랩과는 서로 배타적입니다.

## 토폴로지

```
       eos14        eos15        eos18        eos16
      (Cust2)      (Cust1)      (Cust4)      (Cust3)
         │  └────┐    │            │            │
         │       └──┬─┴────┬───────┘            │
         │        [ eos8 ]                      │
         │         ╱     ╲                      │
      [ eos6 ]────────[ eos5 ]────[ eos4 ]──────┘
       ╱   │  ╲      ╱   │   ╲     ╱   │ ╲
      │  [ eos1 ]───────[ eos2 ]──────[ eos3 ]── eos20 (Centralized)
   eos13    │  ╲                         │ ╲
  (Cust1)   │    ╲       [ eos7 ]───────┘   └── eos9 (Cust2, eos4 와 듀얼호밍)
          eos11    └───────╱  │  ╲
         (Cust1)     eos17    │   eos19
                    (Cust3)  eos10  (Cust4)
                            (Cust2)
```

| 역할 | 장비 | AVD node type |
|---|---|---|
| iBGP Route Reflector | eos2, eos5 | `rr` (mpls_overlay_role server) |
| PE / LER | eos1, eos3, eos4, eos6, eos7, eos8 | `pe` (client) |
| 고객 CE | eos9 ~ eos20 | AVD 대상 아님 (`ce_configs/*.cfg`) |

eos2 / eos5 는 고객 회선이 붙지 않는 코어 중앙 2대라 RR 로 배치했습니다.

## 주소 규칙 (랩 요구사항)

- **Loopback0 = `X.X.X.X/32`** — X 는 노드 ID (eos1 → `1.1.1.1`, eos20 → `20.20.20.20`)
- **P2P IPv4 = `10.X.Y.Z/24`** — X = 낮은 번호 노드, Y = 높은 번호 노드, Z = 자기 노드 ID
  예) eos1 ↔ eos2 → eos1 은 `10.1.2.1/24`, eos2 는 `10.1.2.2/24`
- **Default IGP metric = 10**
- **ISIS-SR Node-SID index = 노드 ID** (eos1 → `node-segment ipv4 index 1`)
- ISIS NET system-id 는 Loopback0 에서 파생 (`1.1.1.1` → `0010.0100.1001`), area `49.0001`, level-2

이 주소 체계는 장비에 이미 배정되어 있고, AVD 산출물도 **정확히 같은 값**을 만들도록
`core_topology.yml` 에 명시했습니다.

## SP 코어 링크 (15개)

실제 장비 `show lldp neighbors` 로 확인한 값입니다.

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

## 서비스

### Customer 1 — L3VPN (VRF `CUST1`, RT `101:101`)

| PE | 포트 | CE | 서브넷 | CE AS |
|---|---|---|---|---|
| eos1 | Et3 | eos11 | 10.1.11.0/24 | 65011 |
| eos6 | Et3 | eos13 | 10.6.13.0/24 | 65013 |
| eos8 | Et2 | eos15 | 10.8.15.0/24 | 65015 |

eos12 는 PE 직결 없이 고객 내부 링(eos11–eos12–eos13)으로만 붙는 CE 입니다(AS 65012).
PE–CE 는 eBGP 이고, 각 CE 는 자기 Loopback0 를 고객 LAN 대표 경로로 광고합니다.

### Customer 2 — L2VPN / E-LAN (EVPN over MPLS, VLAN 100)

SVI 없는 순수 L2 서비스입니다. 세 사이트가 같은 브로드캐스트 도메인(`10.0.0.0/24`)에 들어갑니다.

| CE | IP | 접속 PE |
|---|---|---|
| eos9 | 10.0.0.9 | eos4:Et1 + eos3:Et1 (듀얼호밍) |
| eos10 | 10.0.0.10 | eos7:Et2 |
| eos14 | 10.0.0.14 | eos8:Et4 + eos6:Et6 (듀얼호밍) |

듀얼호밍 2대는 CE 쪽에서 **LACP Port-Channel**, PE 쪽에서 **EVPN Ethernet Segment
(all-active, short_esi auto)** 로 구성됩니다. 두 PE 가 같은 ESI / LACP system-id 를 갖기 때문에
CE 입장에서는 하나의 LAG 로 보이고, L2 루프 없이 두 경로를 동시에 씁니다.

VLAN 100 은 `tags: ['cust2']` 로 표시되어 있고, PE 노드의 `filter.tags` 로 실제 고객 회선이 있는
PE(eos3/4/6/7/8)에만 내려갑니다. eos1 에는 내려가지 않습니다.

### Customer 3 — E-LINE (EVPN VPWS pseudowire)

```
eos16 --- eos4:Et6  ==[ MPLS pseudowire, VPWS id 316/317 ]==  eos1:Et6 --- eos17
```

포트 모드 pseudowire 라 eos16 / eos17 은 직결된 것처럼 같은 서브넷 `10.16.17.0/24` 를 씁니다
(eos16 = .16, eos17 = .17). PE 쪽 포트는 IP 없이 `patch panel` 로 pseudowire 에 연결됩니다.

### Customer 4 — L3VPN (VRF `CUST4`, RT `104:104`)

| PE | 포트 | CE | 서브넷 | CE AS |
|---|---|---|---|---|
| eos8 | Et5 | eos18 | 10.8.18.0/24 | 65018 |
| eos7 | Et4 | eos19 | 10.7.19.0/24 | 65019 |

### Centralized L3VPN (VRF `CENTRAL`, RT `199:199`)

eos20 (eos3:Et6, `10.3.20.0/24`, AS 65020)에 붙은 **공용 서비스 허브**입니다.
Route Target import/export 로 익스트라넷을 구성합니다:

| VRF | export | import |
|---|---|---|
| `CUST1` | 101:101 | 101:101, **199:199** |
| `CUST4` | 104:104 | 104:104, **199:199** |
| `CENTRAL` | 199:199 | 199:199, **101:101**, **104:104** |

→ Customer 1 과 Customer 4 는 각각 공용 서비스(eos20)에 도달하지만, **서로의 RT 는 import 하지
않으므로 Customer 1 ↔ Customer 4 는 격리**됩니다.

## 파일 구성

```
sites/mpls-sr-sp/
├── inventory.yml                     # SP_FABRIC(AVD) + CE(정적) 그룹
├── group_vars/
│   ├── MPLS_SR_SP/                   # 전 장비 공통 (= fabric_name 상위 그룹)
│   │   ├── main.yml                  #   fabric_name, 접속정보, MGMT, cv tags
│   │   ├── vault.yml                 #   랩 비밀번호 (ansible-vault, gitignore)
│   │   ├── core_topology.yml         #   core_interfaces - 코어 15개 링크
│   │   ├── tenants.yml               #   L3VPN / L2VPN / E-LINE 서비스 정의
│   │   └── ports.yml                 #   Customer 2 의 PE 쪽 L2 포트 (ESI 포함)
│   ├── SP_FABRIC.yml                 # ISIS-SR / iBGP / 노드 정의 (rr + pe)
│   ├── CORE_RR.yml / CORE_PE.yml     # 노드 타입 지정 (type: rr / type: pe)
├── ce_configs/*.cfg                  # 고객 CE 델타 설정 (eos9~eos20)
├── intended/                         # 빌드 산출물 - 직접 수정하지 말 것
└── documentation/                    # 빌드 산출물
```

CE 설정은 **델타**입니다. 인터페이스 IP / Loopback0 는 랩에 이미 배정되어 있으므로
`ce_configs/*.cfg` 에는 BGP 와 LAG 만 담고 `arista.eos.eos_config` 로 merge 합니다
(전체 교체가 아니라서 기존 설정을 지우지 않습니다).

## 사용법

```bash
# 0) 최초 1회 - 랩 비밀번호를 vault 로 암호화
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml | grep "password:" | awk '{print $2}'`
ansible-vault encrypt_string "$LABPASSPHRASE" --name 'vault_ansible_password' \
  > sites/mpls-sr-sp/group_vars/MPLS_SR_SP/vault.yml

# 1) 빌드 (SP 코어 eos1~eos8)
make build_mpls_sr_sp

# 2) 코어 배포 (택 1)
make deploy_mpls_sr_sp_cvp      # CVP 경유, change control 자동 생성/실행
make deploy_mpls_sr_sp_eapi     # eAPI 직접 push

# 3) 고객 CE 델타 배포
make deploy_mpls_sr_sp_ce

# 4) 검증
make verify_mpls_sr_sp          # ANTA (설정 변경 없음)
```

`group_vars/**` 를 수정하면 항상 `make build_mpls_sr_sp` 를 다시 돌리고
`intended/configs/*.cfg` 의 diff 를 확인하세요.

## 동작 확인

```bash
# ---- SR 언더레이 ----
ssh arista@192.168.0.10                        # eos1
show isis neighbors                            # 코어 인접 4개
show isis segment-routing prefix-segments      # Node-SID 8개 (index 1~8)
show mpls lfib route                           # SR 라벨 경로
show isis ti-lfa path                          # TI-LFA 백업 경로

# ---- 오버레이 ----
show bgp summary                               # RR 2대(2.2.2.2 / 5.5.5.5)
show bgp vpn-ipv4 summary                      # L3VPN
show bgp evpn summary                          # L2VPN / E-LINE

# ---- 서비스별 ----
show bgp vpn-ipv4 vrf CUST1                    # eos1 / eos6 / eos8
show bgp evpn route-type mac-ip                # Customer 2 (eos3/4/6/7/8)
show bgp evpn route-type ethernet-segment      # 듀얼호밍 ESI
show patch panel                               # Customer 3 E-LINE (eos1 / eos4)
show mpls l2vpn pseudowire

# ---- 엔드투엔드 ----
ssh arista@192.168.0.20 && ping 15.15.15.15    # eos11 -> eos15  (Customer 1 L3VPN)
ssh arista@192.168.0.20 && ping 20.20.20.20    # eos11 -> eos20  (Centralized L3VPN)
ssh arista@192.168.0.20 && ping 19.19.19.19    # eos11 -> eos19  (실패해야 정상 - 고객 격리)
ssh arista@192.168.0.23 && ping 10.0.0.10      # eos14 -> eos10  (Customer 2 L2VPN)
ssh arista@192.168.0.25 && ping 10.16.17.17    # eos16 -> eos17  (Customer 3 E-LINE)
```
