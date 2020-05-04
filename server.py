'''
run this in terminal before running
export PATH=$HOME/.py-solc/solc-v0.4.25/bin:$PATH

also, it is preferred to run this via python3 server.py instead of the debugger
python3 server.py

To connect to Metamask:
1. Import wallet with Ethereum
    - click on top right icon on metamask chrome extension
    - click "import account"
    - click "select type: private key"
    - copy the private key from one of the Ganache accounts
2. Allow the local site to connect to the server
    - click on top right icon on metamask chrome extension
    - navigate to settings/connections
    - add "127.0.0.1" as a connection
'''

import json

from flask import Flask, render_template

from web3.auto import w3
from solc import compile_source


#########################################
# Set up constants
#########################################
owner_account = 0 # set the owner account to be the first one in ganache network
default_physical_address = "5 Nearmall Drive" # Should not be changed thanks to the smart contract #IMMUTABILITY
ether = 1000000000000000000
default_deposit = 2*ether # overpriced 2 ether lot
default_fee = 1*ether # overpriced 1 ether lot (~270SGD as of commit) 

#########################################
# Contract set up and deployment part
#########################################

contract_source_code = None
contract_source_code_file = 'parkingContract.sol'

with open(contract_source_code_file, 'r') as file:
    contract_source_code = file.read()

contract_compiled = compile_source(contract_source_code)
contract_interface = contract_compiled['<stdin>:ParkingContract']
ParkingContract = w3.eth.contract(abi=contract_interface['abi'], 
                          bytecode=contract_interface['bin'])

# w3.personal.unlockAccount(w3.eth.accounts[0], '') # not needed with Ganache
# Set up contract with the default physical address, deposit and fees
# why here? We don't want the driver to have an easy way to tamper with the address in the web app
tx_hash = ParkingContract.constructor(default_physical_address, 
                                        default_deposit, 
                                        default_fee
                                        ).transact({'from':w3.eth.accounts[owner_account]}, )
tx_receipt = w3.eth.waitForTransactionReceipt(tx_hash)

# Contract Object
# address will be passed to the server later
parkingContract = w3.eth.contract(address=tx_receipt.contractAddress, abi=contract_interface['abi'])


#########################################
# Web app part
#########################################

app = Flask(__name__)

@app.route('/')
@app.route('/index')
def hello():
    return render_template('template.html', contractAddress = parkingContract.address.lower(), contractABI = json.dumps(contract_interface['abi']))

if __name__ == '__main__':
    app.run()
