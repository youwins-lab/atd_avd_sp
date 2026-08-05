# Git / GitHub 사용법 가이드 (네트워크 엔지니어를 위한 CLI 입문)

이 문서는 git/GitHub을 처음 접하는 네트워크 엔지니어를 위한 가이드입니다. 최종 목표는 다음과 같습니다.

1. GitHub 계정을 만들고 터미널에서 인증을 설정한다.
2. 자주 쓰는 git 명령어를 익힌다.
3. 이 실습 저장소(`atd_avd_sp`)를 **자신의 GitHub 계정 저장소**로 옮기고, 이후 `group_vars` 등을 수정할 때마다 commit/push하는 흐름을 익힌다.

`README.md`의 STEP #2(저장소 클론)까지 마친 상태를 전제로 합니다.

<br>

## 1. GitHub 계정 생성

브라우저에서 [github.com](https://github.com)에 접속해 **Sign up**으로 계정을 생성합니다. 이 단계는 터미널이 아니라 웹에서 진행합니다.

<br>

## 2. 터미널에서 Git 사용자 정보 설정

커밋을 남기기 전에 이름/이메일을 한 번 설정해 둡니다. (커밋 기록에 표시되는 정보이며 GitHub 로그인 계정과는 별개입니다.)

``` bash
git config --global user.name "본인 이름 또는 GitHub ID"
git config --global user.email "본인 이메일"
```

설정 확인:

``` bash
git config --global --list
```

<br>

## 3. 인증 설정 — Personal Access Token(PAT)

GitHub은 2021년부터 `git push` 시 비밀번호 로그인을 지원하지 않습니다. HTTPS로 push/pull하려면 비밀번호 대신 **Personal Access Token(PAT)**을 사용해야 합니다.

1. GitHub 웹에서 **Settings → Developer settings → Personal access tokens → Fine-grained tokens (또는 Tokens classic)** 로 이동해 새 토큰을 생성합니다. Repository access는 본인이 push할 저장소로 제한하고, 권한은 최소 `Contents: Read and write`만 부여하면 됩니다.
2. 생성된 토큰 문자열을 안전한 곳에 복사해 둡니다(다시 볼 수 없습니다).
3. 터미널에서 `git push`를 처음 실행하면 Username/Password를 물어보는데, **Password 자리에 토큰을 붙여넣습니다.**

매번 토큰을 입력하지 않으려면 자격 증명을 로컬에 저장해 둘 수 있습니다.

``` bash
git config --global credential.helper store
```

(`store`는 홈 디렉토리에 평문으로 저장합니다. 공유 환경이라면 `cache --timeout=3600`처럼 일정 시간만 메모리에 보관하는 옵션을 사용하세요.)

> 참고: `gh`(GitHub CLI)가 설치되어 있다면 `gh auth login`으로 브라우저/디바이스 인증 흐름을 통해 더 간단히 인증할 수 있습니다. 이 랩 환경에는 기본 설치되어 있지 않으므로, 별도 설치가 필요하면 [cli.github.com](https://cli.github.com)의 안내를 따르세요.

<br>

## 4. 자주 쓰는 git 명령어

| 명령어 | 설명 |
|---|---|
| `git clone <url>` | 원격 저장소를 로컬로 복제 |
| `git status` | 변경된 파일, staged 여부 확인 |
| `git diff` | 아직 stage하지 않은 변경 내용 확인 |
| `git diff --staged` | stage된 변경 내용 확인 |
| `git add <file>` | 특정 파일을 staging area에 추가 |
| `git commit -m "메시지"` | staged된 변경을 커밋 |
| `git push` | 커밋을 원격 저장소로 업로드 |
| `git pull` | 원격 저장소의 변경을 로컬로 가져와 병합 |
| `git log --oneline` | 커밋 이력을 한 줄씩 요약해서 확인 |
| `git remote -v` | 현재 연결된 원격 저장소(origin 등) URL 확인 |
| `git branch` | 로컬 브랜치 목록 확인 |
| `git checkout -b <branch>` | 새 브랜치를 만들고 이동 |

> `git add -A`나 `git add .`처럼 전체를 한 번에 add하기보다 `git add <file>`로 원하는 파일만 골라 커밋하는 습관을 들이는 것이 안전합니다. 이 저장소는 자격 증명을 Ansible Vault로 암호화하고 `.gitignore`로 막아 두었지만(8장 참고), add 전에 `git status`로 한 번 확인하는 습관이 사고를 막아줍니다.

<br>

## 5. 실전 시나리오 — 이 저장소를 내 GitHub 계정으로 옮기기

지금 로컬 저장소는 `README.md` STEP #2에서 `git clone`한 원본 저장소를 가리키고 있습니다(`git remote -v`로 확인 가능). 이 저장소를 내 계정 소유로 만들어 직접 commit/push 연습을 하려면 아래 순서를 따릅니다.

**1) GitHub 웹에서 새 저장소 생성**

github.com에 로그인한 뒤 우측 상단 **+ → New repository**로 이동해 저장소 이름(예: `atd_avd_sp`)을 정하고 생성합니다. 로컬에 이미 파일이 있는 상태이므로 **README/ .gitignore 자동 생성 옵션은 체크하지 않습니다.**

**2) 현재 원격(origin) 확인**

``` bash
git remote -v
```

**3) 기존 origin을 upstream으로 보존하고, 내 저장소를 새 origin으로 등록**

원본 저장소 이력을 계속 참고하고 싶다면 origin을 지우지 않고 이름만 바꿔둡니다.

``` bash
git remote rename origin upstream
git remote add origin https://github.com/<본인계정>/atd_avd_sp.git
```

(원본 이력을 신경 쓰지 않는다면 `git remote set-url origin https://github.com/<본인계정>/atd_avd_sp.git` 한 줄로도 충분합니다.)

**4) 내 저장소로 push**

``` bash
git push -u origin main
```

`-u`는 로컬 `main` 브랜치를 origin의 `main`과 연결(tracking)해, 이후에는 `git push`/`git pull`만 입력해도 되게 해줍니다. 이 시점에 3번에서 설명한 PAT 인증이 요구됩니다.

**5) 확인**

브라우저에서 `https://github.com/<본인계정>/atd_avd_sp`에 접속해 파일이 올라갔는지 확인합니다.

<br>

## 6. 이후 일상적인 commit & push 흐름

이 랩에서 `group_vars`를 수정하거나 `make build_dci_sr_evpn`으로 설정을 다시 생성한 뒤에는 아래 흐름을 반복하게 됩니다.

``` bash
git status                                                   # 무엇이 바뀌었는지 확인
git diff sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/tenants.yml # 실제 변경 내용 확인
git add sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/tenants.yml  # 원하는 파일만 staging
git commit -m "Add VLAN 18 to tenant-a"                       # 커밋
git push                                                      # 내 GitHub 저장소로 업로드
```

> `intended/configs`, `intended/structured_configs`, `documentation`처럼 `make build_*`가 자동 생성하는 파일도 git으로 추적되고 있다면 같이 diff를 확인하고 커밋하는 것이 좋습니다 — 리뷰어가 실제 배포될 설정 변경을 바로 볼 수 있기 때문입니다.

<br>

## 7. 자주 만나는 오류와 대처

- **`Authentication failed` / `Support for password authentication was removed`**: 비밀번호 대신 PAT을 사용해야 합니다. 3장을 참고해 토큰을 발급하고 다시 입력하세요.
- **`remote origin already exists`**: 이미 origin이 등록되어 있다는 뜻입니다. `git remote set-url origin <url>`로 URL만 바꾸거나, 5장처럼 `git remote rename`을 사용하세요.
- **`! [rejected] ... (fetch first)`**: 원격에 로컬에 없는 커밋이 있다는 뜻입니다. `git pull --rebase origin main` 으로 먼저 받아온 뒤 다시 `git push`하세요.
- **병합 충돌(merge conflict)**: `git status`에 표시되는 파일을 열어 `<<<<<<<`/`=======`/`>>>>>>>` 표시 사이의 내용을 직접 정리한 뒤, `git add <file>` → `git commit`으로 마무리합니다.

<br>

## 8. 참고 — 이 저장소의 Ansible Vault 사용 방식

스위치와 CVP 접속에 쓰는 랩 비밀번호는 **평문으로 저장소에 들어가지 않습니다.** 각 site의
`group_vars/<그룹>/main.yml`에는 아래처럼 참조만 들어 있고,

``` yaml
ansible_password: "{{ vault_ansible_password }}"
```

실제 값은 같은 디렉토리의 `vault.yml`에 **Ansible Vault로 AES256 암호화**되어 저장됩니다.
이 `vault.yml`과 vault 키 파일 `.vault_pass.txt`는 둘 다 `.gitignore`에 등록되어 있어
커밋되지 않습니다.

``` bash
# .gitignore
.vault_pass.txt
sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/vault.yml
sites/mpls-sr-sp/group_vars/MPLS_SR_SP/vault.yml
```

`ansible.cfg`의 `vault_password_file`이 `.vault_pass.txt`를 가리키므로, `make` 실행 시
vault 비밀번호를 따로 입력할 필요가 없습니다.

> **`ansible_password:` 줄은 직접 고치지 마세요.** 영구 플레이스홀더이며, 여기에 실제 비밀번호를
> 적어 넣으면 그대로 커밋될 위험이 생깁니다.

### vault 파일 만들기 (README STEP #3와 동일)

``` bash
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml| grep "password:" | awk '{print $2}'`
openssl rand -base64 24 > .vault_pass.txt
chmod 600 .vault_pass.txt

for f in sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/vault.yml \
         sites/mpls-sr-sp/group_vars/MPLS_SR_SP/vault.yml; do
  ansible-vault encrypt_string "$LABPASSPHRASE" --name 'vault_ansible_password' > "$f"
done
```

`encrypt_string`은 **값 하나만** 암호화해 `vault_ansible_password: !vault | ...` 블록으로 출력합니다.
파일 전체를 암호화하고 싶다면 아래 명령들을 씁니다.

``` bash
ansible-vault encrypt <파일>     # 파일 전체 암호화
ansible-vault view <파일>        # 복호화해서 보기
ansible-vault edit <파일>        # 복호화 → 편집 → 재암호화
ansible-vault rekey <파일>       # vault 비밀번호 변경
```

vault 비밀번호를 파일로 두지 않았다면 실행 시 직접 입력할 수도 있습니다.

``` bash
ansible-playbook ... --ask-vault-pass
ansible-playbook ... --vault-password-file ~/.vault_pass.txt
```

### 커밋 전 확인 습관

ATD 랩 비밀번호는 세션마다 새로 발급되는 일회성 값이지만, 자격 증명이 git 히스토리에 남으면
이후 커밋에서 지워도 되돌릴 수 없습니다. push 전에 아래를 한 번씩 확인하세요.

``` bash
git status                                   # vault.yml / .vault_pass.txt 가 목록에 없어야 정상
git diff --cached                            # staging된 내용에 비밀번호가 없는지
git check-ignore -v .vault_pass.txt          # gitignore가 실제로 걸려 있는지 확인
```
