# AVD와 CVP를 이용한 MPLS Segment Routing 서비스 프로바이더 랩

**GitHub 저장소**: https://github.com/youwins-lab/atd_avd_sp

이 저장소는 실제 구축 사례가 아닌 **교육용 실습 자료**로, Arista의 AVD(Ansible Validated Designs)
자동화 프레임워크로 **MPLS Segment Routing 코어**를 만들고 그 위에 L3VPN / L2VPN / E-LINE 서비스와
DC 간 EVPN 확장을 올려보는 구성입니다. 설정 변경 관리와 감사를 위해 CloudVision(CVP)을 함께 사용합니다.

AVD가 설정을 생성하는 장비(`eos_designs` → `eos_cli_config_gen`)와, `eos_config` 롤로 정적/델타
설정을 얹는 장비가 함께 들어 있습니다.

***참고:*** 이 실습 자료는 **AVD 6.3.0** 기준이며, `eos1`~`eos20`으로 구성된 ATD Pod에서 동작합니다.
관리 IP는 `eos<N> = 192.168.0.<9+N>` 이며 **절대 변경하지 않습니다.**

<br>

## 두 개의 랩

이 저장소에는 서로 독립적인 두 개의 site가 들어 있습니다. 같은 물리 장비를 쓰기 때문에
**한 번에 하나만** 배포할 수 있습니다.

### 1. DCI MPLS-SR EVPN WAN Core (`sites/dci-sr-evpn`) — 권장 시작점

MPLS Segment Routing WAN 코어를 만들고, 그 위로 DC1 / DC2 두 EVPN VXLAN 도메인을
**Multidomain EVPN Gateway**로 이어 붙입니다. Tenant A(VLAN 16/17)가 DC를 넘어 스트레치됩니다.

```
   ┌────────── DC1 EVPN VXLAN ──────────┐       ┌────────── DC2 EVPN VXLAN ──────────┐
   │  host1/2-DC1 ── leaf1-DC1 ── spine │       │ spine ── leaf1-DC2 ── host1/2-DC2  │
   │   (eos15/18)     (eos8)    (eos6)  │       │ (eos3)    (eos7)     (eos10/19)    │
   │                              │     │       │   │                                │
   │              BL1-DC1/GW11 (eos1) ══╪═══════╪═══ BL1-DC2/GW21 (eos4)             │
   └──────────────────────┼─────────────┘       └───┼────────────────────────────────┘
                          │    MPLS-SR WAN Core (AS 1)   │
                          ├──────── P1 (eos2) ───────────┤
                          └──────── RR (eos5) ───────────┘
```

- **실습 가이드**: [`lab guide/dci-mpls-sr-evpn-labs.md`](lab%20guide/dci-mpls-sr-evpn-labs.md)
- **설정 레퍼런스**: [`sites/dci-sr-evpn/README.md`](sites/dci-sr-evpn/README.md)
- 배우는 것: ISIS-SR(Node-SID), MPLS 데이터 플레인, iBGP RR/Client 오버레이,
  L2+L3 결합 EVPN Multidomain Gateway, VXLAN ↔ MPLS 도메인 스티칭

### 2. MPLS-SR 서비스 프로바이더 코어 (`sites/mpls-sr-sp`)

`eos1`~`eos8`을 SP 코어(ISIS-SR + iBGP RR/PE)로 만들고, `eos9`~`eos20`을 고객 CE로 붙여
**L3VPN / L2VPN(E-LAN) / E-LINE(VPWS) / Centralized L3VPN** 네 가지 서비스를 올립니다.

- **실습 가이드**: [`lab guide/mpls-sr-sp-labs.md`](lab%20guide/mpls-sr-sp-labs.md)
- **설정 레퍼런스**: [`sites/mpls-sr-sp/README.md`](sites/mpls-sr-sp/README.md)
- 배우는 것: MPLS L3VPN(vpn-ipv4), EVPN E-LAN over MPLS, EVPN VPWS pseudowire,
  Route Target 익스트라넷(공용 서비스 VRF), EVPN Ethernet Segment 듀얼호밍

<br>

## 디렉토리 구조

```bash
|---lab guide
    |---dci-mpls-sr-evpn-labs.md   [DCI MPLS-SR EVPN 랩 실습 가이드]
    |---mpls-sr-sp-labs.md         [MPLS-SR 서비스 프로바이더 랩 실습 가이드]
    |---claude-code-guide.md       [AI 코딩 에이전트 - Claude Code]
    |---codex-cli-guide.md         [AI 코딩 에이전트 - Codex CLI]
    |---git-github-guide.md        [Git/GitHub 입문]
|---playbooks
    |---build_dci_sr_evpn.yml
    |---deploy_dci_sr_evpn_cvp.yml
    |---deploy_dci_sr_evpn_eapi.yml
    |---deploy_dci_sr_evpn_hosts.yml
    |---verify_dci_sr_evpn.yml
    |---build_mpls_sr_sp.yml
    |---deploy_mpls_sr_sp_cvp.yml
    |---deploy_mpls_sr_sp_eapi.yml
    |---deploy_mpls_sr_sp_ce.yml
    |---verify_mpls_sr_sp.yml
|---sites
    |---dci-sr-evpn [DCI MPLS-SR EVPN WAN Core 랩]
    |   |---group_vars
    |   |   |---DCI_SR_EVPN [전 장비 공통]
    |   |   |   |---main.yml           [fabric_name, 접속정보, MGMT]
    |   |   |   |---vault.yml          [랩 비밀번호 - gitignore]
    |   |   |   |---wan_topology.yml   [core_interfaces - WAN 코어 링크]
    |   |   |   |---tenants.yml        [Tenant A: VRF tenant-a, VLAN 16/17]
    |   |   |   |---ports.yml          [호스트 접속 포트]
    |   |   |---WAN_CORE.yml           [ISIS-SR + iBGP RR/P 노드 정의]
    |   |   |---DC1_FABRIC.yml / DC2_FABRIC.yml  [spine/leaf/EVPN GW 노드 정의]
    |   |   |---WAN_RR.yml, WAN_P.yml, DC{1,2}_{SPINES,LEAFS,GW}.yml  [type 지정]
    |   |---host_configs [Tenant A 호스트 델타 설정]
    |   |---intended [빌드 산출물 - 직접 수정 금지]
    |   |---documentation [빌드 산출물]
    |   |---inventory.yml
    |   |---README.md
    |---mpls-sr-sp [MPLS-SR 서비스 프로바이더 랩]
    |   |---group_vars
    |   |   |---MPLS_SR_SP [전 장비 공통]
    |   |   |   |---main.yml
    |   |   |   |---vault.yml          [랩 비밀번호 - gitignore]
    |   |   |   |---core_topology.yml  [core_interfaces - 코어 15개 링크]
    |   |   |   |---tenants.yml        [L3VPN / L2VPN / E-LINE 서비스]
    |   |   |   |---ports.yml          [Customer 2 L2 포트 + EVPN ESI]
    |   |   |---SP_FABRIC.yml          [ISIS-SR + iBGP RR/PE 노드 정의]
    |   |   |---CORE_RR.yml / CORE_PE.yml
    |   |---ce_configs [고객 CE 델타 설정 eos9~eos20]
    |   |---intended / documentation
    |   |---inventory.yml
    |   |---README.md
|---ansible.cfg
|---setup_env.sh
|---Makefile
|---CLAUDE.md / AGENTS.md   [AI 코딩 에이전트용 저장소 안내]
|---README.md
```

<br>

# ATD Programmability IDE에서 AVD 실행하기

ATD 환경에서 Programmability IDE를 실행하고, 비밀번호를 입력한 뒤 새 터미널을 엽니다:

![IDE](images/programmability_ide.png)

## 빠른 설치 스크립트 (`setup_env.sh`)

ATD 환경은 재시작되면 설치했던 Ansible collection, python 패키지, Claude Code CLI가 모두 초기화됩니다.
매번 STEP #1을 다시 치는 대신 저장소 루트의 `setup_env.sh` 하나로 재설치할 수 있습니다.

1. `arista.avd:==6.3.0`, `arista.cvp:==3.12.0` Ansible collection 설치
2. `pyavd`, `anta` 및 의존성(`pyavd-utils`, `python-socks`, `distlib`) 설치
3. Claude Code CLI 설치 (이미 있으면 건너뜀)

저장소 루트(`atd_avd_sp`)에서 실행합니다:

``` bash
./setup_env.sh
```

이 스크립트는 패키지 설치까지만 처리합니다. `LABPASSPHRASE` 설정과 vault 암호화(STEP #3)는
랩마다 비밀번호가 다르므로 별도로 진행해야 합니다 — 스크립트 실행이 끝나면 해당 명령어를 그대로
안내해줍니다.

<br>

## STEP #1 - Ansible Collection AVD/CVP 와 Python 패키지 설치

https://galaxy.ansible.com/ui/repo/published/arista/avd/docs/

``` bash
ansible-galaxy collection install arista.avd:==6.3.0 arista.cvp:==3.12.0
```

AVD 6.x부터는 `pyavd`가 설정을 렌더링하고, ANTA 테스트 실행에 `anta`와 의존성 패키지
(`pyavd-utils`, `python-socks`, `distlib`)가 필요합니다. 이들은 collection과 별도로 설치해야 합니다.

``` bash
export ARISTA_AVD_VERSION=$(ansible-galaxy collection list arista.avd --format yaml | tail -1 | cut -d: -f2 | tr '-' '.')
pip3 install "pyavd[ansible-collection]==$ARISTA_AVD_VERSION"
```

## STEP #2 - 저장소 클론

``` bash
cd labfiles
git clone https://github.com/youwins-lab/atd_avd_sp.git
cd atd_avd_sp
```

> `ansible.cfg`의 `collections_paths`가 `../ansible-cvp:../ansible-avd:...`를 가리키므로,
> AVD/CVP collection은 이 저장소의 **형제 디렉토리**로 `labfiles/` 아래에 있어야 합니다.

## STEP #3 - 랩 비밀번호 환경 변수 설정 및 Ansible Vault 암호화

각 랩에는 고유한 비밀번호가 부여됩니다. 아래 명령으로 `LABPASSPHRASE` 환경 변수를 설정합니다.
이 값은 스위치와 CVP에 접속해 설정을 푸시하는 데 사용됩니다.

``` bash
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml| grep "password:" | awk '{print $2}'`
echo $LABPASSPHRASE
```

각 site의 `group_vars/<그룹>/main.yml`은 `ansible_password: "{{ vault_ansible_password }}"`를
가리키며, 이 변수의 실제 값은 같은 디렉토리의 `vault.yml`에 ansible-vault로 암호화되어 저장됩니다
(`.gitignore`에 등록되어 있어 커밋되지 않습니다).

저장소를 새로 클론했거나 ATD가 재시작된 직후에는 vault 파일이 없으므로, vault 암호화에 사용할 로컬
키 파일을 만들고(`ansible.cfg`의 `vault_password_file`이 이 파일을 가리킵니다) 두 site에 대해
`LABPASSPHRASE`를 암호화해 넣습니다:

``` bash
openssl rand -base64 24 > .vault_pass.txt
chmod 600 .vault_pass.txt

for f in sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/vault.yml \
         sites/mpls-sr-sp/group_vars/MPLS_SR_SP/vault.yml; do
  ansible-vault encrypt_string \
    "$LABPASSPHRASE" --name 'vault_ansible_password' > "$f"
done
```

이후 ansible이 `vault_password_file`로 자동 복호화하므로 `make` 실행 시 vault 비밀번호를 따로
입력할 필요가 없습니다.

> **`ansible_password:` 줄은 직접 수정하지 마세요.** 영구 플레이스홀더이며 실제 비밀번호는
> vault 파일에만 들어갑니다. `.vault_pass.txt`와 각 site의 `vault.yml`은 실제 비밀번호(또는 그 키)를
> 담고 있으므로 절대 커밋하면 안 되며, 이미 `.gitignore`에 등록되어 있습니다.

<br>

# STEP #4 - 빌드와 배포

패브릭의 초기 배포와 이후 모든 변경은 알맞은 site inventory를 대상으로 ansible 플레이북을 실행하는
방식입니다. Makefile이 "올바른 플레이북 + 올바른 inventory" 조합을 축약해 둔 alias 역할을 합니다.
전체 목록은 `make help`로 볼 수 있습니다.

## 랩 1 — DCI MPLS-SR EVPN WAN Core

| 명령어 | 설명 | 플레이북 / Inventory |
|---|---|---|
| `make build_dci_sr_evpn` | `eos_designs` → `eos_cli_config_gen` 으로 eos1~eos8 설정 생성. `intended/configs`, `intended/structured_configs`, `documentation` 이 만들어집니다 | `build_dci_sr_evpn.yml` / `dci-sr-evpn/inventory.yml` |
| `make deploy_dci_sr_evpn_cvp` | 생성된 설정을 CVP에 configlet으로 업로드. `cv_run_change_control: true` 라 change control이 자동 생성·실행됩니다 | `deploy_dci_sr_evpn_cvp.yml` / 〃 |
| `make deploy_dci_sr_evpn_eapi` | CVP를 거치지 않고 장비 eAPI로 직접 배포 | `deploy_dci_sr_evpn_eapi.yml` / 〃 |
| `make deploy_dci_sr_evpn_hosts` | Tenant A 호스트(eos10/15/18/19)의 **델타** 설정을 `eos_config`로 merge (전체 교체 아님) | `deploy_dci_sr_evpn_hosts.yml` / 〃 |
| `make verify_dci_sr_evpn` | 설정 변경 없이 `arista.avd.anta_runner`로 상태만 검증 | `verify_dci_sr_evpn.yml` / 〃 |

**초기 배포 순서**

1. `make build_dci_sr_evpn` — 생성된 `intended/configs/*.cfg`를 먼저 눈으로 확인
2. `make deploy_dci_sr_evpn_cvp` (또는 `deploy_dci_sr_evpn_eapi`)
   - CVP를 쓰는 경우 Tasks / Change Control 화면에서 자동 생성된 작업과 config를 확인
3. `make deploy_dci_sr_evpn_hosts`
4. `make verify_dci_sr_evpn`
5. 스위치 CLI로 동작 확인:

``` bash
ssh arista@192.168.0.14        # RR
show isis neighbors
show isis segment-routing prefix-segments

ssh arista@192.168.0.24        # host1-DC1
ping vrf tenant-a 172.16.16.53 # -> host1-DC2 (MPLS-SR 코어를 넘어감)
```

단계별 확인 명령과 "왜 이런 설정이 나오는가"는
[`lab guide/dci-mpls-sr-evpn-labs.md`](lab%20guide/dci-mpls-sr-evpn-labs.md)에 정리되어 있습니다.
IDE에서 해당 파일을 우클릭 → **Open Preview** 하면 읽기 좋은 형식으로 볼 수 있습니다.

## 랩 2 — MPLS-SR 서비스 프로바이더 코어

| 명령어 | 설명 | 플레이북 / Inventory |
|---|---|---|
| `make build_mpls_sr_sp` | SP 코어 eos1~eos8 설정 생성 | `build_mpls_sr_sp.yml` / `mpls-sr-sp/inventory.yml` |
| `make deploy_mpls_sr_sp_cvp` | CVP 경유 배포 (change control 자동 실행) | `deploy_mpls_sr_sp_cvp.yml` / 〃 |
| `make deploy_mpls_sr_sp_eapi` | eAPI 직접 배포 | `deploy_mpls_sr_sp_eapi.yml` / 〃 |
| `make deploy_mpls_sr_sp_ce` | 고객 CE(eos9~eos20) 델타 설정 merge | `deploy_mpls_sr_sp_ce.yml` / 〃 |
| `make verify_mpls_sr_sp` | ANTA 검증 | `verify_mpls_sr_sp.yml` / 〃 |

**초기 배포 순서**: `build_mpls_sr_sp` → `deploy_mpls_sr_sp_cvp`(또는 `_eapi`) → `deploy_mpls_sr_sp_ce` → `verify_mpls_sr_sp`

단계별 확인 명령, 서비스별 동작 원리, 고객 격리 검증 매트릭스는
[`lab guide/mpls-sr-sp-labs.md`](lab%20guide/mpls-sr-sp-labs.md)에 정리되어 있습니다.

<br>

## 작업 흐름 규칙

- `group_vars/**`를 수정했으면 **항상** 해당 랩의 `build_*`를 다시 돌리고
  `intended/configs/*.cfg`의 diff를 확인한 뒤 배포합니다.
- `intended/`와 `documentation/`은 **빌드 산출물**입니다. 직접 편집하지 말고 입력(`group_vars`)을
  고치세요.
- 관리 IP는 Pod에 고정되어 있고, 각 노드의 `id`가 관리 IP 마지막 옥텟에서 유도됩니다
  (`Loopback0 = 192.168.255.<id>` 등). **관리 IP를 바꾸지 마세요.**
- 두 랩은 같은 물리 장비를 쓰므로 한 번에 하나만 배포합니다. 랩을 바꾸려면 다른 랩의
  `build_*` → `deploy_*`를 다시 실행해 덮어씁니다.

<br>

## 부록 - AI 코딩 에이전트 설치 및 사용 (선택)

이 랩의 설정 작업(그룹 변수 작성, 인벤토리 구성, 플레이북 실행 결과 확인 등)은 Claude Code나
Codex CLI 같은 AI 코딩 에이전트로 진행할 수 있습니다. 설치 방법과 이 저장소에서 쓸 수 있는
실전 프롬프트 예시는 **lab guide** 디렉토리의 아래 문서를 참고하세요.

- Claude Code: [`claude-code-guide.md`](lab%20guide/claude-code-guide.md)
- Codex CLI: [`codex-cli-guide.md`](lab%20guide/codex-cli-guide.md)

저장소 루트의 `CLAUDE.md` / `AGENTS.md`에 이 저장소의 구조와 주의사항이 정리되어 있어,
에이전트가 세션 시작 시 자동으로 읽습니다.

<br>

## 부록 - Git / GitHub 사용법 (네트워크 엔지니어를 위한 CLI 입문, 선택)

git/GitHub을 처음 접하는 경우, GitHub 계정 등록부터 자주 쓰는 git 명령어, 그리고 이 저장소를
본인 GitHub 계정으로 옮기고 commit/push하는 방법까지는 **lab guide** 디렉토리의
[`git-github-guide.md`](lab%20guide/git-github-guide.md)를 참고하세요.
