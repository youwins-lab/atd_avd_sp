###########################################
# Run AVD with various tags               #
# #########################################

.PHONY: help
help: ## Display help message
	@grep -E '^[0-9a-zA-Z_-]+\.*[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

###########################################
# MPLS-SR EVPN DCI lab (sites/dci-mpls-sr)#
# #########################################

.PHONY: build_dci_mpls_sr
build_dci_mpls_sr: ## Build AVD configs for the MPLS-SR EVPN DCI lab (DC1 + DC2 + MPLS-SR core)
	ansible-playbook playbooks/build_dci_mpls_sr.yml -i sites/dci-mpls-sr/inventory.yml

.PHONY: deploy_dci_mpls_sr_cvp
deploy_dci_mpls_sr_cvp: ## Deploy MPLS-SR EVPN DCI lab AVD configs through CVP
	ansible-playbook playbooks/deploy_dci_mpls_sr_cvp.yml -i sites/dci-mpls-sr/inventory.yml

.PHONY: deploy_dci_mpls_sr_eapi
deploy_dci_mpls_sr_eapi: ## Deploy MPLS-SR EVPN DCI lab AVD configs via eAPI
	ansible-playbook playbooks/deploy_dci_mpls_sr_eapi.yml -i sites/dci-mpls-sr/inventory.yml

.PHONY: deploy_dci_mpls_sr_hosts_cvp
deploy_dci_mpls_sr_hosts_cvp: ## Deploy MPLS-SR EVPN DCI lab host static configs through CVP
	ansible-playbook playbooks/deploy_dci_mpls_sr_hosts_cvp.yml -i sites/dci-mpls-sr/inventory.yml

.PHONY: verify_dci_mpls_sr
verify_dci_mpls_sr: ## Run ANTA validation against the MPLS-SR EVPN DCI lab without pushing config
	ansible-playbook playbooks/verify_dci_mpls_sr.yml -i sites/dci-mpls-sr/inventory.yml

###############################################
# MPLS-SR Service Provider lab (sites/mpls-sr-sp)#
###############################################

.PHONY: build_mpls_sr_sp
build_mpls_sr_sp: ## Build AVD configs for the MPLS-SR service provider core (eos1-eos8)
	ansible-playbook playbooks/build_mpls_sr_sp.yml -i sites/mpls-sr-sp/inventory.yml

.PHONY: deploy_mpls_sr_sp_cvp
deploy_mpls_sr_sp_cvp: ## Deploy MPLS-SR SP core configs through CloudVision
	ansible-playbook playbooks/deploy_mpls_sr_sp_cvp.yml -i sites/mpls-sr-sp/inventory.yml

.PHONY: deploy_mpls_sr_sp_eapi
deploy_mpls_sr_sp_eapi: ## Deploy MPLS-SR SP core configs via eAPI
	ansible-playbook playbooks/deploy_mpls_sr_sp_eapi.yml -i sites/mpls-sr-sp/inventory.yml

.PHONY: deploy_mpls_sr_sp_ce
deploy_mpls_sr_sp_ce: ## Merge customer CE delta configs (eos9-eos20) via eAPI
	ansible-playbook playbooks/deploy_mpls_sr_sp_ce.yml -i sites/mpls-sr-sp/inventory.yml

.PHONY: verify_mpls_sr_sp
verify_mpls_sr_sp: ## Run ANTA validation against the MPLS-SR SP lab without pushing config
	ansible-playbook playbooks/verify_mpls_sr_sp.yml -i sites/mpls-sr-sp/inventory.yml

###################################################
# DCI MPLS-SR EVPN WAN Core lab (sites/dci-sr-evpn)#
###################################################

.PHONY: build_dci_sr_evpn
build_dci_sr_evpn: ## Build AVD configs for the DCI MPLS-SR EVPN WAN Core lab
	ansible-playbook playbooks/build_dci_sr_evpn.yml -i sites/dci-sr-evpn/inventory.yml

.PHONY: deploy_dci_sr_evpn_cvp
deploy_dci_sr_evpn_cvp: ## Deploy DCI MPLS-SR EVPN lab configs through CloudVision
	ansible-playbook playbooks/deploy_dci_sr_evpn_cvp.yml -i sites/dci-sr-evpn/inventory.yml

.PHONY: deploy_dci_sr_evpn_eapi
deploy_dci_sr_evpn_eapi: ## Deploy DCI MPLS-SR EVPN lab configs via eAPI
	ansible-playbook playbooks/deploy_dci_sr_evpn_eapi.yml -i sites/dci-sr-evpn/inventory.yml

.PHONY: deploy_dci_sr_evpn_hosts
deploy_dci_sr_evpn_hosts: ## Merge Tenant A host delta configs via eAPI
	ansible-playbook playbooks/deploy_dci_sr_evpn_hosts.yml -i sites/dci-sr-evpn/inventory.yml

.PHONY: verify_dci_sr_evpn
verify_dci_sr_evpn: ## Run ANTA validation against the DCI MPLS-SR EVPN lab
	ansible-playbook playbooks/verify_dci_sr_evpn.yml -i sites/dci-sr-evpn/inventory.yml
