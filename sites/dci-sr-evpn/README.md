# DCI MPLS-SR EVPN WAN Core (`sites/dci-sr-evpn`)

MPLS Segment Routing WAN 코어 위에서 DC1 / DC2 두 EVPN VXLAN 도메인을 Multidomain EVPN
Gateway로 연결하는 site 입니다. 실습 절차와 개념 설명은
**[`lab guide/dci-mpls-sr-evpn-labs.md`](../../lab%20guide/dci-mpls-sr-evpn-labs.md)** 를 보세요.
이 문서는 설정 레퍼런스입니다.

## 장비 매핑 (관리 IP 는 변경하지 않음)

| 역할 | 장비 | 관리 IP | Loopback0 | VTEP (Lo1) | Node SID | BGP AS | AVD type |
|---|---|---|---|---|---|---|---|
| RR | eos5 | 192.168.0.14 | 192.168.255.14 | — | 14 | 1 | `rr` |
| P1 | eos2 | 192.168.0.11 | 192.168.255.11 | — | 11 | 1 | `p` |
| BL1-DC1 (GW11) | eos1 | 192.168.0.10 | 192.168.255.10 | 10.255.1.10 | 10 | 1 | `l3leaf` |
| BL1-DC2 (GW21) | eos4 | 192.168.0.13 | 192.168.255.13 | 10.255.1.13 | 13 | 1 | `l3leaf` |
| spine1-DC1 | eos6 | 192.168.0.15 | 192.168.255.15 | — | — | 65110 | `spine` |
| leaf1-DC1 | eos8 | 192.168.0.17 | 192.168.255.17 | 10.255.1.17 | — | 65012 | `l3leaf` |
| spine1-DC2 | eos3 | 192.168.0.12 | 192.168.255.12 | — | — | 65220 | `spine` |
| leaf1-DC2 | eos7 | 192.168.0.16 | 192.168.255.16 | 10.255.1.16 | — | 65212 | `l3leaf` |
| host1-DC1 | eos15 | 192.168.0.24 | — | — | — | — | 정적 |
| host2-DC1 | eos18 | 192.168.0.27 | — | — | — | — | 정적 |
| host1-DC2 | eos10 | 192.168.0.19 | — | — | — | — | 정적 |
| host2-DC2 | eos19 | 192.168.0.28 | — | — | — | — | 정적 |

**미사용**: `eos9`, `eos11`, `eos12`, `eos13`, `eos14`, `eos16`, `eos17`, `eos20`
— 인벤토리 `UNUSED` 그룹에만 있고 어떤 플레이북의 대상도 아니라 설정이 내려가지 않습니다.

주소 규칙: `Loopback0 = 192.168.255.<관리 IP 마지막 옥텟>`, `VTEP = 10.255.1.<같은 숫자>`,
`Node SID = 같은 숫자`. AVD 에서는 노드 `id` 를 그 숫자로 잡고 풀만 지정하면 자동으로 나옵니다.

## 파일 구성

```
sites/dci-sr-evpn/
├── inventory.yml                     # WAN 코어 / DC1 / DC2 / 호스트 / UNUSED 그룹
├── group_vars/
│   ├── DCI_SR_EVPN/                  # 전 장비 공통 (= fabric_name 상위 그룹)
│   │   ├── main.yml                  #   fabric_name, 접속정보, MGMT
│   │   ├── vault.yml                 #   랩 비밀번호 (ansible-vault, gitignore)
│   │   ├── wan_topology.yml          #   core_interfaces - WAN 코어 5개 링크
│   │   ├── tenants.yml               #   Tenant A (VRF tenant-a, VLAN 16/17)
│   │   └── ports.yml                 #   호스트 접속 포트 (servers)
│   ├── WAN_CORE.yml                  # ISIS-SR 설정 + rr/p 노드 정의
│   ├── DC1_FABRIC.yml                # DC1 spine/leaf/GW11 노드 정의
│   ├── DC2_FABRIC.yml                # DC2 spine/leaf/GW21 노드 정의
│   └── WAN_RR.yml, WAN_P.yml, DC{1,2}_{SPINES,LEAFS,GW}.yml   # type: 지정
├── host_configs/*.cfg                # Tenant A 호스트 델타 설정 (eos10/15/18/19)
├── intended/                         # 빌드 산출물 - 직접 수정하지 말 것
└── documentation/                    # 빌드 산출물
```

## 명령

```bash
# 최초 1회 - vault
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml | grep "password:" | awk '{print $2}'`
ansible-vault encrypt_string "$LABPASSPHRASE" --name 'vault_ansible_password' \
  > sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/vault.yml

make build_dci_sr_evpn            # eos1~eos8 설정 생성
make deploy_dci_sr_evpn_cvp       # CVP 경유 배포 (또는 _eapi)
make deploy_dci_sr_evpn_hosts     # 호스트 델타 merge
make verify_dci_sr_evpn           # ANTA
```

## 설계 메모 (AVD 로 표현하기 까다로운 부분)

### 1. GW 는 두 도메인에 동시에 속합니다

`BL1-DC1` / `BL1-DC2` 는 AVD node type `l3leaf` 이면서 BGP AS 는 1 입니다.

- **Local 도메인** — DC spine 과 eBGP(언더레이+EVPN), VXLAN 캡슐화, VTEP = Loopback1
- **Remote 도메인** — WAN 코어 RR 과 iBGP AS 1, MPLS 캡슐화, next-hop = Loopback0

`evpn_gateway.evpn_l2` + `evpn_l3.inter_domain` 이 VLAN 별 `rd evpn domain remote` /
`route-target ... domain remote` 와 `next-hop-self received-evpn-routes route-type ip-prefix
inter-domain` 을 만들어 L2+L3 결합 게이트웨이 동작을 완성합니다.

### 2. AVD 가 만들어 주지 않아서 `structured_config` 로 넣은 것

AVD 의 `overlay_mpls` / `underlay_mpls` 조건은 **node type 이 `p`/`pe`/`rr` (mpls_lsr) 이고
언더레이가 isis 계열** 일 때만 참입니다. GW 는 `l3leaf` + eBGP 언더레이라 해당되지 않으므로,
아래를 노드 `structured_config` 에 직접 씁니다:

- `router_isis` (instance CORE, NET, SR MPLS, TI-LFA) + `mpls: {ip: true}`
- Loopback0 의 `isis_enable` / `isis_passive` / `node_segment.ipv4_index`
- WAN 코어 방향 인터페이스의 `isis_enable` / `isis_metric` / `mpls.ip`
- RR 로 가는 `MPLS-OVERLAY-PEERS` 피어 그룹 + neighbor
- `address_family_evpn` 의 `domain_identifier` / `domain_identifier_remote` 와
  피어 그룹의 `encapsulation: mpls`, `domain_remote: true`,
  `next_hop_self_source_interface: Loopback0`

> RR(eos5) 쪽은 GW 2대를 RR Client 로 **자동 인식**하므로 손댈 필요가 없습니다.
> (`type: rr` + GW 노드의 `mpls_route_reflectors: [eos5]`)

### 3. core_interfaces 프로파일이 2개인 이유

- `SR_CORE` (`include_in_underlay_protocol: true`) — P1↔RR. 양쪽 다 isis-sr 노드라 AVD 가
  ISIS/MPLS 를 자동 생성합니다.
- `SR_EDGE` (`include_in_underlay_protocol: false`) — GW↔코어. GW 는 eBGP 언더레이 노드라
  `true` 로 두면 AVD 가 이 링크에도 언더레이 BGP 이웃을 만들려 하면서 `as` 를 요구합니다.
  ISIS/MPLS 는 양쪽 노드 `structured_config` 에서 직접 넣습니다
  (코어 쪽은 `WAN_CORE.yml` 의 eos2/eos5 노드).

### 4. 원본 랩 대비 축소된 부분

원본 랩 가이드는 P1~P4 4대와 DC 당 leaf 페어(MLAG)를 씁니다. 현재 Pod 배선에는 그만한
여유가 없어 다음과 같이 줄였습니다:

| 원본 | 이 site | 이유 |
|---|---|---|
| P1, P2, P3, P4 | P1 (eos2) 1대 | 코어 mesh 에서 고객 포트가 없는 장비가 eos2/eos5 둘뿐 |
| DC 당 leaf 페어 + MLAG | DC 당 leaf 1대 | leaf 페어를 만들 여유 장비가 없음 |
| DC 당 spine 2대 | DC 당 spine 1대 | 위와 동일 |

기능(SR 언더레이 / iBGP RR 오버레이 / 멀티도메인 EVPN GW / Tenant A 스트레치)은 모두
동일하게 동작합니다.
