FROM_ACCOUNT	:= 72RCCF5VB24TZUNBHBYAOW7VW5LJA6IUHXOOJWCTYMFHBYD2AZQRVWDH5U
TO_ACCOUNT		:= 6HZOQLMJCMKNVNMEJVTI3BD3FZIO2EJGTINJKT4NOYMR577YI4VZHP3NHM

all: build-tx

clean:
	rm -rf build

build-tx:
	mkdir -p build
	python contract.py

deploy-tx:
	goal app create --creator $(ALGO_PVTNET_ADDR) \
		--approval-prog ./build/george_interact.teal \
		--clear-prog ./build/clear_state.teal \
		--global-byteslices 1 \
		--local-byteslices 1 \
		--local-ints 0 \
		--global-ints 1 -d $(ALGO_PVTNET_DATA)

run:
	export FLASK_APP=app
	flask run

heal-cmd:
	goal app call --app-id $(APP_ID) \
		--app-arg 'str:heal'  \
		-f $(FROM_ACCOUNT) \
		-d $(ALGO_PVTNET_DATA) \
		-o tx1
	
damage-cmd:
	goal app call --app-id $(APP_ID) \
		--app-arg 'str:damage'  \
		-f $(FROM_ACCOUNT) \
		-d $(ALGO_PVTNET_DATA) \
		-o tx1

heal: heal-cmd tx
damage: damage-cmd tx

tx:
	goal clerk send -a 5000000 \
		-t $(TO_ACCOUNT) \
		-f $(FROM_ACCOUNT) \
		-d $(ALGO_PVTNET_DATA) \
		-o tx2
	\
	cat tx1 tx2 > ctx
	goal clerk group -i ctx -o gtx -d $(ALGO_PVTNET_DATA)
	goal clerk sign -i gtx -o stx -d $(ALGO_PVTNET_DATA)
	goal clerk rawsend -f stx -d $(ALGO_PVTNET_DATA)

read:
	goal app read --app-id $(APP_ID) \
		--global -d $(ALGO_PVTNET_DATA) \
		--guess-format

kill-npc:
	for i in {1..6} ; do make damage ; done # the last will fail
	
transcend-npc:
	for i in {1..6} ; do make heal ; done # the last will fail
