include .env

export $(shell sed 's/=.*//' .env)

remove:
	rm -rf .gitmodules && rm -rf .git/modules && rm -rf lib && touch .gitmodules 

install:
	forge install foundry-rs/forge-std --no-commit && forge install uniswap/v4-periphery --no-commit

build:
	forge build

clean:
	forge clean

update:
	forge update

test:
	forge test

test-deploy-registry:
	forge script script/DeployV4HooksStoreRegistry.s.sol:DeployV4HooksStoreRegistry --rpc-url $(RPC_URL) --sender $(SENDER)

deploy-registry:
	forge script script/DeployV4HooksStoreRegistry.s.sol:DeployV4HooksStoreRegistry --rpc-url $(RPC_URL) --sender $(SENDER) --etherscan-api-key $(API_KEY) --verify --broadcast