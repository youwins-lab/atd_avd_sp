# Claude Code 설치 및 활용 가이드

이 문서는 `README.md`의 STEP #5였던 Claude Code 설치 안내를 분리하고, 이 저장소(AVD 6.3.0 기반 L3LS EVPN-VXLAN 랩)에서 Claude Code를 실제로 어떻게 활용할 수 있는지 실전 프롬프트 예시와 함께 정리한 자료입니다. 설치 자체는 `README.md`의 STEP #1~#4(Python 패키지 설치, 저장소 클론, `LABPASSPHRASE` 설정, 저장소 디렉토리 이동)를 먼저 마친 뒤 진행하세요.

<br>

## 1. 설치

`atd_avd_sp` 저장소 루트로 이동한 터미널에서 아래 명령어로 Claude Code를 설치합니다.

``` bash
curl -fsSL https://claude.ai/install.sh | bash
```

<br>

## 2. 실행 및 기본 사용법

설치가 끝나면 저장소 루트 디렉토리(`atd_avd_sp`)에서 아래 명령어로 실행합니다.

``` bash
claude
```

실행되면 대화형 세션이 시작되며, 이 디렉토리 안의 파일들을 읽고 수정하거나, `make` 명령어와 ansible 플레이북을 대신 실행시키는 등의 작업을 자연어로 요청할 수 있습니다. 세션을 종료하려면 `exit`를 입력하거나 `Ctrl+C`를 두 번 누르면 됩니다.

이 저장소 루트에는 `CLAUDE.md` 파일이 있어, Claude Code가 세션을 시작할 때 자동으로 읽고 이 랩의 구조(두 site 구성, AVD 관리 장비 vs 정적 config 장비, `group_vars` 입력과 `intended/` 산출물의 관계, `make` 타겟 목록 등)를 미리 파악합니다. 즉 "`WAN_CORE.yml`이 뭐하는 파일이야?" 같은 질문에도 저장소를 처음부터 탐색하지 않고 바로 답할 수 있습니다.

<br>

## 3. AVD 6.3.0 작업에 Claude Code 활용하기 — 실전 예시

아래는 이 저장소의 실제 워크플로우(`group_vars` 수정 → `make build_dci_sr_evpn` → diff 확인 → 배포 → ANTA 검증)를 Claude Code로 진행하는 구체적인 프롬프트 예시입니다. 각 예시는 그대로 입력해도 되고, 상황에 맞게 바꿔서 사용해도 됩니다.

### 예시 1 — Tenant A에 새 VLAN 추가

`sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/tenants.yml`에는 VLAN 16/17이 VRF `tenant-a`에 묶여 있습니다. 같은 패턴으로 VLAN을 하나 더 늘려보는 작업입니다.

```
sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/tenants.yml 의 tenant-a VRF에
VLAN 18 (name: TenantA-VLAN18, 172.16.18.0/24, 애니캐스트 GW 172.16.18.254)을
기존 VLAN 16/17과 같은 패턴으로 추가해줘. ports.yml 의 servers trunk vlans 도 같이 맞춰주고,
make build_dci_sr_evpn 를 실행한 다음 intended/configs 아래에서 어떤 장비의 config가
바뀌었는지 요약해줘. L2 VNI가 몇 번으로 잡혔는지도 알려줘.
```

기존 정의 패턴을 읽어 동일한 구조로 추가한 뒤 빌드를 실행하고 diff를 요약해 줍니다. 배포 전에는 항상 결과를 직접 검토하세요.

### 예시 2 — ANTA 리포트 실패 원인 분석

`make verify_dci_sr_evpn`은 `arista.avd.anta_runner`로 검증을 실행하고 `sites/dci-sr-evpn/anta/reports/`에 리포트를 남깁니다. 실패한 테스트의 원인 파악을 맡길 수 있습니다.

```
sites/dci-sr-evpn/anta/reports/ 아래 가장 최근 리포트를 읽고 실패한 테스트를 나열해줘.
각 실패가 ISIS-SR 언더레이 문제인지, iBGP 오버레이(RR) 문제인지, EVPN 게이트웨이 문제인지
분류하고, 연관된 group_vars 설정이 있으면 어떤 파일의 어떤 값을 봐야 하는지 알려줘.
```

### 예시 3 — EVPN Gateway 설정 이해하기

이 랩에서 가장 까다로운 부분은 Border Leaf(`eos1`/`eos4`)입니다. AVD의 `l3leaf` 노드 타입이 ISIS-SR/MPLS를 자동 생성하지 않기 때문에, 일부 설정이 `structured_config`로 손으로 들어가 있습니다. 왜 그런지 물어보면서 익히는 것이 좋습니다.

```
sites/dci-sr-evpn/group_vars/DC1_FABRIC.yml 의 eos1 노드에서
structured_config 로 직접 넣은 설정이 무엇이고, 각각이 왜 AVD가 자동 생성해 주지 않는지
설명해줘. 그리고 생성된 intended/configs/eos1.cfg 에서 그 설정들이 실제로 어느 줄에
나타나는지 짚어줘.
```

이렇게 물으면 `underlay_mpls`/`overlay_mpls` 조건과 노드 타입의 관계를 코드 근거와 함께 확인할 수 있습니다.

### 예시 4 — 호스트 등 정적 config 장비 변경

Tenant A 테스트 호스트(`eos10`/`eos15`/`eos18`/`eos19`)와 SP 랩의 고객 CE는 AVD가 아니라 `host_configs/`, `ce_configs/`의 손으로 작성한 `.cfg` **델타** 파일로 관리됩니다.

```
sites/dci-sr-evpn/host_configs/eos15.cfg 에 VLAN 18 관련 SVI와 trunk 허용 VLAN을
추가하려면 어디를 고쳐야 하는지 보여주고, 이 파일이 전체 교체가 아니라 eos_config merge로
배포된다는 점을 감안해서 make deploy_dci_sr_evpn_hosts 실행 전에 확인해야 할 점을 알려줘.
```

<br>

## 4. 배포 전 확인 원칙

Claude Code는 파일 수정과 `make`/ansible 실행까지 대신할 수 있지만, 이 랩에서는 다음 원칙을 지키는 것을 권장합니다.

- CVP로 배포하기 전에는 항상 `intended/configs/*.cfg` diff와 `documentation/` 변경 사항을 직접 눈으로 확인합니다.
- 두 site(`dci-sr-evpn`, `mpls-sr-sp`)는 **같은 물리 장비**를 씁니다. 다른 랩을 배포하면 이전 랩 설정이 덮어써지므로, 어느 랩을 대상으로 작업 중인지 항상 명확히 지시하세요.
- 관리 IP는 Pod에 고정이고 각 노드의 `id`가 거기서 유도됩니다. 관리 IP나 `id`를 바꾸라는 요청은 하지 마세요.
- 실제 자격 증명은 `vault.yml`(ansible-vault, gitignore)에만 들어갑니다. 커밋/푸시를 맡기기 전에 `git diff`와 `git status`로 vault 파일이나 `.vault_pass.txt`가 섞이지 않았는지 확인하세요.
