all: contract

clean:
	rm -rf build

contract:
	mkdir -p build
	python contract.py

deploy:
	goal app create --creator $(ALGO_PVTNET_ADDR) \
	--approval-prog ./build/george_interact.teal \
	--clear-prog ./build/clear_state.teal \
	--global-byteslices 1 \
	--local-byteslices 1 \
	--local-ints 0 \
	--global-ints 1 -d $(ALGO_PVTNET_DATA)
