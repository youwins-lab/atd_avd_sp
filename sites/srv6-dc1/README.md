# SRv6 uSID 데모 (DC1 장비 재구성)

원본은 https://github.com/brokenpackets/clab_Topos/tree/main/srv6_uSID 의 containerlab + cEOS
토폴로지(9개 노드: spine1/2, leaf1/2/3, host1~4)입니다. 이 ATD 랩에는 그 원본 9노드 토폴로지를 위한
여분 장비가 없어서, 대신 **DC1 EVPN-VXLAN 패브릭이 실제로 사용 중인 장비**(`s1-spine1`, `s1-spine2`,
`s1-leaf1`, `s1-leaf2`, `s1-leaf3`, `s1-host1`, `s1-host2`)를 재구성해 이 데모를 올립니다.

이 site는 dc1/dc2와 마찬가지로 완전히 독립된 inventory/group_vars를 갖습니다 (다만 eos_designs/
eos_cli_config_gen을 쓰지 않는 non-AVD 장비이므로 dci_configs/host_configs와 같은 정적 설정 패턴을 씁니다):

- 설정 파일: `sites/srv6-dc1/srv6_configs/*.cfg`
- Inventory: `sites/srv6-dc1/inventory.yml` (`dc1_srv6` 그룹)
- 접속 정보: `sites/srv6-dc1/group_vars/dc1_srv6.yml` — 다른 site와 마찬가지로 `ansible_password`를
  랩 비밀번호로 먼저 치환해야 합니다 (README.md 루트의 환경설정 절차 참고).
- 배포: `make deploy_dc1_srv6_cvp` (→ `playbooks/deploy_dc1_srv6_cvp.yml`)

## 물리 배선에 맞춘 매핑/변경 사항

실습 장비 배선은 고정되어 있어 원본 컨테이너 링크 맵을 그대로 쓸 수 없습니다. 아래처럼 대응시켰습니다:

| 원본 노드 | 실제 장비 | 비고 |
|---|---|---|
| spine1 | s1-spine1 | 그대로 |
| spine2 | s1-spine2 | 그대로 |
| leaf1 | s1-leaf1 | 그대로, host1 부착 |
| leaf2 | s1-leaf2 | 실제로 부착된 host가 없어 SRv6 업링크만 살아있고 유휴 상태 |
| leaf3 | s1-leaf3 | 원본의 leaf3 host3 포트 역할을 이어받아 host2를 부착 |
| host1 | s1-host1 | 그대로 (leaf1에 물리적으로 연결됨) |
| host2 | **원본 host3의 주소 체계 사용** | 물리적으로 s1-leaf3에 연결되는 장비가 s1-host2뿐이라, 원본 host3 역할(주소 `fc00:1:333`, `2001:db8:1::23`, usid 819)을 그대로 물려받았습니다. 원본의 테스트 시나리오(host1 → fc00:1:333 ping)와 100% 동일하게 재현됩니다. |
| host3, host4 | (없음) | 실제 장비가 없어 제외. 이에 따라 `Host24` micro-segment 도메인(원래 host2/host4용)은 전체 삭제 — leaf2가 그 도메인의 유일한 잠재 참여자였는데 host가 없어 의미가 없어짐 |

인터페이스 번호도 실제 배선에 맞춰 재번호했습니다 (원본 `ethernet1/2/3` → 실제 장비의 `Ethernet2/3/4` 등,
`sites/srv6-dc1/srv6_configs/*.cfg`의 각 인터페이스 `description`에 원본 대비 실제 대응 관계를 적어뒀습니다).

## 중요 — 배포 전 반드시 확인

`make deploy_dc1_srv6_cvp`는 **DC1의 EVPN-VXLAN 패브릭을 통째로 중단시킵니다.**

- `s1-spine1`/`s1-spine2`가 SRv6 전용으로 바뀌면 DC1 전체(leaf1~4)의 언더레이 BGP가 끊깁니다.
- `s1-leaf3`가 바뀌면 `LeafPair2`(leaf3+leaf4) MLAG가 깨지고 `s1-host2`의 dual-homed 연결도 영향을 받습니다.
- `s1-leaf1`/`s1-leaf2`가 바뀌면 `LeafPair1` 전체가 사라지고 `s1-host1`도 영향을 받습니다.
- 각 정적 설정 맨 위에 `no router bgp ...`, `no interface Vxlan1`, `no mlag configuration`,
  `no vlan ...` 등 이전 EVPN-VXLAN/MLAG 관련 설정을 명시적으로 제거하는 명령을 넣어뒀지만, **CVP에 이미
  올라가 있는 기존 AVD designed configlet이 이 새 configlet과 별도로 남아있는지**는 배포 후 CVP UI에서
  반드시 확인하세요. 정상적으로 대체되지 않고 두 configlet이 같이 남아있다면 EVPN-VXLAN 설정 일부가
  SRv6 설정과 충돌한 채로 남을 수 있습니다.
- 되돌리려면: `make build_dc1` → `make deploy_dc1_cvp` (원래 AVD EVPN-VXLAN 설정 재배포), 그리고
  `s1-host1`/`s1-host2`는 `make deploy_dc1_host_cvp`로 원래 정적 설정 재배포.

## 배포 후 동작 검증 (테스트 시나리오)

`s1-host1`/`s1-host2`는 실제 Linux host가 아니라 EOS 스위치이므로, 아래 명령은 모두 EOS CLI 문법입니다.
직접 콘솔/SSH로 접속해 실행해도 되고, ansible ad-hoc(`arista.eos.eos_command`)으로 원격 실행해도 됩니다.

### 헬퍼 함수 (셸에 한 번만 붙여넣기)

`arista.eos.eos_command`의 기본 ansible 출력은 JSON 한 덩어리라 값 하나 보려고 스크롤하기 불편합니다.
아래 함수를 셸에 한 번 붙여넣으면, 이후 모든 확인 명령이 **호스트별로 필요한 줄만** 걸러서 보여줍니다
(jq 필요 — 이 IDE에는 기본 설치되어 있습니다):

```bash
eos_check() {
  local pattern="$1" cmd="$2" filter="${3:-.}"
  ansible -i sites/srv6-dc1/inventory.yml "$pattern" -o -m arista.eos.eos_command -a "commands='$cmd'" |
  while IFS= read -r line; do
    host="${line%% |*}"
    json="${line#*=> }"
    echo "=== $host ==="
    jq -r '.stdout[0]' <<<"$json" | grep -E "$filter"
  done
}
```
사용법: `eos_check "<대상 패턴>" "<show/ping 명령>" "<보고 싶은 줄만 남길 grep 패턴>"` (패턴은 콤마로 여러
대를 한 번에 지정 가능, 필터를 생략하면 전체 출력).

### 0. eAPI 접근 확인

```bash
eos_check dc1_srv6 "show hostname" "Hostname"
```
7대(spine1/2, leaf1/2/3, host1/2) 모두 자기 hostname으로 응답해야 합니다.

### 1. EVPN-VXLAN이 내려가고 SRv6로 전환됐는지 확인

`s1-host1`/`s1-host2`는 애초에 `router bgp`가 없던 장비라 이 명령이 에러(`BGP inactive`)로 나므로,
spine/leaf 5대만 대상으로 합니다:
```bash
eos_check "s1-spine1,s1-spine2,s1-leaf1,s1-leaf2,s1-leaf3" "show ip bgp summary" "BGP is"
```
5대 모두 `BGP is disabled for VRF default`가 나와야 정상입니다 (EVPN-VXLAN이 쓰던 BGP가 이 정적 설정으로
완전히 제거됐다는 뜻).

### 2. SRv6 uSID 라우팅 확인 (운영자용 show 명령)

각 노드는 공통 block `fc00:1::/32` 안에서 자기 usid(uSID 주소의 3번째 hextet)로 스스로를 식별합니다:

| 노드 | usid (hex) | uSID 주소 |
|---|---|---|
| s1-spine1 | 0x11 | `fc00:1:11::` |
| s1-spine2 | 0x12 | `fc00:1:12::` |
| s1-leaf1  | 0x101 | `fc00:1:101::` |
| s1-leaf3  | 0x103 | `fc00:1:103::` |
| s1-host1  | 0x111 | `fc00:1:111::` |
| s1-host2  | 0x333 | `fc00:1:333::` |

경로/인터페이스 스팟체크:
```bash
# host2(fc00:1:333::)로 가는 /48 경로가 host1 쪽 경로 상의 노드에 다 있는지 ("via ..." 줄만 표시)
eos_check "s1-leaf1,s1-spine1,s1-spine2" "show ipv6 route fc00:1:333::" "via "

# host1(fc00:1:111::)로 가는 /48 경로가 host2 쪽 경로 상의 노드에 다 있는지
eos_check "s1-leaf3,s1-spine1,s1-spine2" "show ipv6 route fc00:1:111::" "via "

# 장비별 실제 설정된 IPv6 주소(uSID, local address, P2P)만 — link-local 줄은 제외
eos_check dc1_srv6 "show ipv6 interface brief" "config"

# SRV6_P2P_*, SRV6_SERVER_* 링크 상태만
eos_check dc1_srv6 "show interfaces description" "SRV6_P2P|SRV6_SERVER"
```
각 경로 명령의 정상 출력에는 `via <next-hop>, Ethernet<N>`이 찍힙니다 — 대상 호스트 아래에 `via` 줄이
하나도 없다면(라우팅 테이블에 항목 자체가 없다면) 아래 4번 체크리스트로 넘어가세요.

### 3. host1 ↔ host2 ping (핵심 검증)

`s1-host1`에서:
```
ping ipv6 fc00:1:333:: source Loopback0
```
`s1-host2`에서 (반대 방향):
```
ping ipv6 fc00:1:111:: source Loopback0
```
정상이면 양쪽 모두 `5 packets transmitted, 5 received, 0% packet loss`가 나옵니다.

ansible ad-hoc으로 원격 실행 (요약 줄만 표시):
```bash
eos_check s1-host1 "ping ipv6 fc00:1:333:: source Loopback0" "packets transmitted"
eos_check s1-host2 "ping ipv6 fc00:1:111:: source Loopback0" "packets transmitted"
```

### 4. 실패 시 체크리스트

- `ping: connect: Network is unreachable` → **출발지 장비**(host1/host2)에 상대 usid 주소로 가는
  `ipv6 route`가 없는 것입니다. `srv6_configs/s1-host{1,2}.cfg`에 상대편 `/48` 경로
  (`ipv6 route fc00:1:xxx::/48 <자기 leaf 방향 next-hop>`)가 있는지 확인하세요.
- 에러 없이 `100% packet loss`만 나오면 → **중간 홉**(spine1/spine2/leaf1/leaf3) 중 하나에 상대편 `/48`
  경로가 빠진 것입니다. 위 2번의 `eos_check ... "via "` 명령으로 다음 홉이 실제로 잡히는지 노드별로
  확인하세요 (uSID 주소는 각 노드의 자기 `/48` 경로만 자동으로 알고, 다른 노드 뒤에 붙은 host의 `/48`은
  정적 설정에 직접 넣어줘야 합니다 — 누락되기 쉬운 지점입니다).
- `show ip bgp summary`가 여전히 활성 BGP를 보여주면 → CVP change control이 아직 실행되지 않았거나,
  기존 AVD designed configlet이 이 새 configlet과 같이 남아있는 것입니다 (위 "중요 — 배포 전 반드시 확인"
  참고).
