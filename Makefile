GEORGE_ACCOUNT		:= 6HZOQLMJCMKNVNMEJVTI3BD3FZIO2EJGTINJKT4NOYMR577YI4VZHP3NHM

# during test we'll use a different account to interact with George
FROM_ACCOUNT		:= 72RCCF5VB24TZUNBHBYAOW7VW5LJA6IUHXOOJWCTYMFHBYD2AZQRVWDH5U
TO_ACCOUNT          := $(GEORGE_ACCOUNT)

#ALGO_PVTNET_DATA 	:= ~/pvtnet-algod
ALGO_TESTNET_DATA   := /home/hydrogen/testnet-algod
ALGO_MAINNET_DATA   := /home/hydrogen/mainnet-algod

# pick your net
ALGO_DATA			:= $(ALGO_PVTNET_DATA)

all: build deploy transcend-npc
re: clean all

clean:
	rm -rf build
	rm -f ctx gtx stx.rej stx tx1 tx2

#node
start:
	goal node start -d $(ALGO_DATA)

status:
	goal node status -d $(ALGO_DATA)

stop:
	goal node stop -d $(ALGO_DATA)

pvtnet:
	goal network create -r $(ALGO_PVTNET_DATA) -n private -t pvtnet.json


#ci
build:
	mkdir -p build
	python contract.py

deploy:
	goal app create --creator $(GEORGE_ACCOUNT) \
		--approval-prog ./build/george_interact.teal \
		--local-byteslices 0 \
		--local-ints 0 \
		--global-byteslices 1 \
		--global-ints 1 -d $(ALGO_DATA)


# contract interaction
heal-cmd:
	goal app call --app-id $(APP_ID) \
		--app-arg 'str:heal'  \
		-f $(FROM_ACCOUNT) \
		-d $(ALGO_DATA) \
		-o tx1
	
injure-cmd:
	goal app call --app-id $(APP_ID) \
		--app-arg 'str:injure'  \
		-f $(FROM_ACCOUNT) \
		-d $(ALGO_DATA) \
		-o tx1

amount:
	goal clerk send -a 100 \
		-t $(TO_ACCOUNT) \
		-f $(FROM_ACCOUNT) \
		-d $(ALGO_DATA) \
		-o tx2

group-send:
	cat tx1 tx2 > ctx
	goal clerk group -i ctx -o gtx -d $(ALGO_DATA)
	goal clerk sign -i gtx -o stx -d $(ALGO_DATA)
	goal clerk rawsend -f stx -d $(ALGO_DATA)


heal: heal-cmd amount group-send
injure: injure-cmd amount group-send


read:
	goal app read --app-id $(APP_ID) \
		--global -d $(ALGO_DATA) \
		--guess-format

kill-npc:
	for i in {1..6} ; do make injure ; done # the last will fail
	
transcend-npc:
	for i in {1..6} ; do make heal ; done # the last will fail


# delete app
delete:
	goal app delete --app-id $(APP_ID) -f $(GEORGE_ACCOUNT) -d $(ALGO_DATA)


# ui
run:
	export FLASK_APP=app
	flask run
