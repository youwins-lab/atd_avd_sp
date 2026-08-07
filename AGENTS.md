# AGENTS.md

This file provides guidance to OpenAI Codex CLI (and other AI coding agents that read `AGENTS.md`) when working with code in this repository. It mirrors `CLAUDE.md`, which Claude Code reads for the same purpose — see `lab guide/claude-code-guide.md` and `lab guide/codex-cli-guide.md` for how to install and use each agent against this repo.

## What this repo is

Arista AVD (Ansible Validated Designs) 6.3.0 labs built around **MPLS Segment Routing**, running
inside Arista's ATD (Arista Test Drive) programmability IDE against a 20-node cEOS pod named
`eos1`–`eos20` (management IPs `192.168.0.10`–`192.168.0.29`, i.e. `eos<N>` = `192.168.0.<9+N>`).

Two independent sites share those same physical devices, so **only one can be deployed at a time**:

- **`sites/dci-sr-evpn`** (primary) — an MPLS-SR WAN core with two EVPN-VXLAN datacenter domains
  stitched across it by **Multidomain EVPN Gateways**. Tenant A (VRF `tenant-a`, VLAN 16/17) is
  stretched end to end so hosts in DC1 and DC2 can ping each other. Learning walkthrough:
  `lab guide/dci-mpls-sr-evpn-labs.md`. Reference: `sites/dci-sr-evpn/README.md`.
- **`sites/mpls-sr-sp`** — an MPLS-SR service provider core (eos1–eos8) serving L3VPN, EVPN E-LAN,
  EVPN VPWS (E-Line) and a centralized shared-services L3VPN to customer CEs (eos9–eos20).
  Learning walkthrough: `lab guide/mpls-sr-sp-labs.md`. Reference: `sites/mpls-sr-sp/README.md`.

The Architecture section below describes `sites/dci-sr-evpn`; see that site's README for
`sites/mpls-sr-sp`. README.md and all lab docs are maintained in Korean.

## Environment setup (one-time per lab session)

ATD wipes installed collections/packages on restart. `./setup_env.sh` reinstalls everything;
otherwise:

```bash
ansible-galaxy collection install arista.avd:==6.3.0 arista.cvp:==3.12.0
export ARISTA_AVD_VERSION=$(ansible-galaxy collection list arista.avd --format yaml | tail -1 | cut -d: -f2 | tr '-' '.')
pip3 install "pyavd[ansible-collection]==$ARISTA_AVD_VERSION"
```

Credentials must be injected before anything authenticates. `group_vars/DCI_SR_EVPN/main.yml` sets
`ansible_password: "{{ vault_ansible_password }}"` — this line is a permanent placeholder and is
never edited. The real password is ansible-vault-encrypted into a sibling `vault.yml` (gitignored),
decrypted automatically via the `vault_password_file` in `ansible.cfg` pointing at a local,
gitignored `.vault_pass.txt`:

```bash
export LABPASSPHRASE=`cat /home/coder/.config/code-server/config.yaml | grep "password:" | awk '{print $2}'`
openssl rand -base64 24 > .vault_pass.txt && chmod 600 .vault_pass.txt
for f in sites/dci-sr-evpn/group_vars/DCI_SR_EVPN/vault.yml \
         sites/mpls-sr-sp/group_vars/MPLS_SR_SP/vault.yml; do
  ansible-vault encrypt_string "$LABPASSPHRASE" --name 'vault_ansible_password' > "$f"
done
```

Note `group_vars/<group>.yml` and a same-named `group_vars/<group>/` directory are **not** merged by
Ansible — only one is loaded. That is why the top-level group's vars live as `main.yml`, `vault.yml`,
`wan_topology.yml`, `tenants.yml`, `ports.yml` side by side inside `group_vars/DCI_SR_EVPN/`.

## Commands (Makefile targets)

All run from the repo root and take `-i sites/dci-sr-evpn/inventory.yml` implicitly.

- `make build_dci_sr_evpn` — `arista.avd.eos_designs` then `arista.avd.eos_cli_config_gen` against
  the `DCI_SR_FABRIC` group. Regenerates `sites/dci-sr-evpn/intended/configs/*.cfg` (eos1–eos8),
  `intended/structured_configs/*.yml`, and `documentation/**`. Run after any `group_vars/**` change.
- `make deploy_dci_sr_evpn_cvp` — push AVD configs to CVP as configlets with
  `cv_run_change_control: true` (change control auto-created and executed).
- `make deploy_dci_sr_evpn_eapi` — bypass CVP, push directly via eAPI.
- `make deploy_dci_sr_evpn_hosts` — merge the Tenant A host **delta** configs from `host_configs/`
  onto eos10/eos15/eos18/eos19 with `arista.eos.eos_config` (merge, not replace).
- `make verify_dci_sr_evpn` — `arista.avd.anta_runner` only, no config push.

Bring-up order: build → deploy (cvp or eapi) → hosts → verify.

`sites/mpls-sr-sp` has the mirror-image set: `build_mpls_sr_sp`, `deploy_mpls_sr_sp_cvp`,
`deploy_mpls_sr_sp_eapi`, `deploy_mpls_sr_sp_ce` (customer CE delta merge), `verify_mpls_sr_sp`.
Switching labs means re-running the other site's build + deploy to overwrite the devices.

There is no test suite; correctness is checked by re-running the build and diffing
`intended/configs/*.cfg`, plus the ANTA run and the end-to-end pings in the lab guide.

## Architecture

**Node ID rule (drives everything):** node `id` = last octet of the management IP, and management
IPs are never changed. From that one number AVD derives `Loopback0 = 192.168.255.<id>`,
`VTEP Loopback1 = 10.255.1.<id>`, and ISIS-SR `node-segment ipv4 index <id>`. So `id` must stay in
sync with `mgmt_ip`.

**Three domains in one AVD fabric** (`fabric_name: DCI_SR_FABRIC`) — they reference each other's
facts (RR/client discovery), so they must build in one play:

| Domain | Group | Devices | Underlay | Overlay |
|---|---|---|---|---|
| MPLS-SR WAN core | `WAN_CORE` | eos5 (`rr`), eos2 (`p`) | ISIS-SR, process `CORE`, area 49.0001, metric 10 | iBGP AS 1, EVPN over MPLS |
| DC1 EVPN-VXLAN | `DC1_FABRIC` | eos6 spine (AS 65110), eos8 leaf (AS 65012), eos1 GW11 (AS 1) | eBGP | eBGP EVPN, VXLAN |
| DC2 EVPN-VXLAN | `DC2_FABRIC` | eos3 spine (AS 65220), eos7 leaf (AS 65212), eos4 GW21 (AS 1) | eBGP | eBGP EVPN, VXLAN |

`underlay_routing_protocol` differs per domain because it is set in each domain's group_vars file
(`WAN_CORE.yml` = `isis-sr`, `DC{1,2}_FABRIC.yml` = `EBGP`) and Ansible evaluates group_vars per host.

**The two Border Leafs are the whole point.** `eos1` (BL1-DC1 / GW11) and `eos4` (BL1-DC2 / GW21)
are AVD node type `l3leaf` with `bgp_as: 1`, and belong to **two EVPN domains at once**:

- *Local domain* — eBGP to their DC spine, VXLAN encapsulation, next-hop = VTEP Loopback1
- *Remote domain* — iBGP AS 1 to the RR (eos5), MPLS encapsulation, next-hop = Loopback0

`evpn_gateway.evpn_l2` + `evpn_l3.inter_domain` generates the per-VLAN
`rd evpn domain remote` / `route-target ... domain remote` and
`next-hop-self received-evpn-routes route-type ip-prefix inter-domain`, which is what makes a
Type-2 (MAC-IP) route re-advertise as both Type-2 and Type-5 across domains.

**What AVD will not generate, and why.** `shared_utils.underlay_mpls` / `overlay_mpls` are true only
when the node type key has `mpls_lsr: true` (i.e. `p`/`pe`/`rr`) **and** the underlay is an ISIS
variant. The gateways are `l3leaf` with an eBGP underlay, so AVD emits no ISIS, no `mpls ip`, and no
MPLS overlay peering for them. All of that is hand-written in the gateway node's
`structured_config` in `DC{1,2}_FABRIC.yml`:

- `router_isis` (instance `CORE`, NET derived from Loopback0, `segment_routing_mpls`, TI-LFA) and
  `mpls: {ip: true}`
- Loopback0 `isis_enable` / `isis_passive` / `node_segment.ipv4_index`
- core-facing interfaces' `isis_enable` / `isis_metric` / `mpls.ip`
- the `MPLS-OVERLAY-PEERS` peer group and neighbor toward the RR
- `address_family_evpn.domain_identifier` / `domain_identifier_remote`, and on the peer group
  `encapsulation: mpls`, `domain_remote: true`, `next_hop_self_source_interface: Loopback0`

The NET system-id is derived from Loopback0 by zero-padding each octet to 3 digits and regrouping
4-4-4 (`192.168.255.10` → `1921.6825.5010`). If a gateway's Loopback0 changes, its `net` must be
recomputed by hand.

The **RR side needs nothing hand-written** — `type: rr` plus the gateways' `mpls_route_reflectors:
[eos5]` makes AVD discover them as clients and emit the peer group with `route-reflector-client` and
`encapsulation mpls`.

**`core_interfaces` uses two profiles on purpose** (`group_vars/DCI_SR_EVPN/wan_topology.yml`):

- `SR_CORE` (`include_in_underlay_protocol: true`) — the P1↔RR link only. Both ends are isis-sr
  nodes, so AVD adds ISIS and `mpls ip` itself.
- `SR_EDGE` (`include_in_underlay_protocol: false`) — the four GW↔core links. Setting `true` there
  makes AVD try to build an underlay **BGP** neighbor on the gateway (because its underlay is eBGP)
  and fail with `core_interfaces.p2p_links.[].as`. ISIS/MPLS on these links is therefore written by
  hand on **both** ends — gateway side in `DC{1,2}_FABRIC.yml`, core side in the eos2/eos5 nodes of
  `WAN_CORE.yml`.

WAN core P2P addresses are pinned to the pod's pre-staged `10.<low>.<high>.<self>/24` values via
explicit `ip:` on each `p2p_link`. DC fabric uplinks are left to AVD's `uplink_ipv4_pool`.

**Tenant A** (`group_vars/DCI_SR_EVPN/tenants.yml`) is defined once at the top-level group so DC1 and
DC2 see identical definitions: VRF `tenant-a` (L3 VNI 1000), VLAN 16 → `172.16.16.0/24` (L2 VNI
10016) and VLAN 17 → `172.16.17.0/24` (L2 VNI 10017), anycast gateways `.254` in both DCs. The WAN
core (`rr`/`p`) sets `filter.tenants: []` so it relays EVPN without holding local VRFs or SVIs.

**Hosts are not AVD-managed.** eos15/eos18 (DC1) and eos10/eos19 (DC2) get hand-written **delta**
configs from `host_configs/*.cfg`, merged with `arista.eos.eos_config`. Each host puts its VLAN
16/17 SVIs in a *host-local* VRF also named `tenant-a` — so test pings must use
`ping vrf tenant-a <ip>`, never the default VRF. Host addresses are `.51`/`.52` (DC1) and
`.53`/`.54` (DC2) in both subnets. The leaf-side ports are generated by AVD from the `servers:` list
in `group_vars/DCI_SR_EVPN/ports.yml` — edit that, not the leaf config.

**Eight devices are intentionally unused**: eos9, eos11, eos12, eos13, eos14, eos16, eos17, eos20.
The pod's cabling has no room for them in either the core or the DC fabrics. They sit in the
inventory's `UNUSED` group, which is not a target of any playbook, so no config is pushed to them.
Do not add them to `DCI_SR_FABRIC` without first checking LLDP for a usable link.

**Scaled down from the original lab guide**: the source lab uses P1–P4 and an MLAG leaf pair per DC.
Only eos2 and eos5 have no customer-facing ports in this pod's cabling, and there are no spare
switches for leaf pairs, so this site runs one P router and one spine + one leaf per DC. All the
functionality (SR underlay, iBGP RR overlay, multidomain EVPN gateway, Tenant A stretch) is intact.

## Conventions

- Ansible connection is `httpapi` over eAPI (port 443) for real devices; CVP-only playbooks use
  `connection: local` and call CVP's API instead.
- `ansible.cfg` points `collections_paths` at `../ansible-cvp:../ansible-avd:...` — the AVD/CVP
  collections are expected to live as siblings of this repo under `labfiles/`.
- Never edit files under `intended/` or `documentation/` — they are build output. Edit the
  `group_vars` inputs and re-run `make build_dci_sr_evpn`.
- Management IPs are fixed by the pod and must never be changed; the node `id` values depend on them.
