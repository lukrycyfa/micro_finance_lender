# MICRO_FINANCE_LENDER
- This project is a Base example Lender Contract that could be implemented in a blockchain ecosystem where value is of essence and urgency needs to be attended to. Having implementations for gaining profits while satisfying clients' urgent needs with risks of losing borrowed tokens at zero. Basically lending and paying back tokens from this move contract demands a lender to provide a Sui token with a balance enough to cover a collateral which is 20% plus the loaned amount to guarantee a paid back over a period of time at fees in percentages. Assuming the Sui token tends gain value in the market and the example usdt coin is a stable coin. Other utilities and implementations include... transfers, keeping records of lenders, balances and more.

## Disclaimer: Use of Unaudited Code for Educational Purposes Only
This code is provided strictly for educational purposes and has not undergone any formal security audit. 
It may contain errors, vulnerabilities, or other issues that could pose risks to the integrity of your system or data.

By using this code, you acknowledge and agree that:
- No Warranty: The code is provided "as is" without any warranty of any kind, either express or implied. The entire risk as to the quality and performance of the code is with you.
- Educational Use Only: This code is intended solely for educational and learning purposes. It is not intended for use in any mission-critical or production systems.
- No Liability: In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the use or performance of this code.
- Security Risks: The code may not have been tested for security vulnerabilities. It is your responsibility to conduct a thorough security review before using this code in any sensitive or production environment.
- No Support: The authors of this code may not provide any support, assistance, or updates. You are using the code at your own risk and discretion.

Before using this code, it is recommended to consult with a qualified professional and perform a comprehensive security assessment. By proceeding to use this code, you agree to assume all associated risks and responsibilities.

## Setup

### Techstacks and Dependencies Required to Use or Test the Micro_finance_lender Contract.

- The setup procedure here covers installations on Ubuntu and Github Codespaces(Recommended) for simplycity. You could refer to the tutorial Setup from the [Sui DeepBook Tutorial](https://dacade.org/communities/sui/challenges/19885730-fb83-477a-b95b-4ab265b61438/learning-modules/c9e21ff5-e7b3-4583-b21c-00c7176c10cc) or [sui docs](https://docs.sui.io/guides/developer/getting-started/sui-install), for installation on other platforms. 

#### Installation on Ubuntu/Github Codespaces:

- To get started on Codespace follow this link to the repository [micro_finance_lender](https://github.com/lukrycyfa/micro_finance_lender) click on the "Code" button, navigating to the codespaces tab then select "Create codespace on main". to generate a new Codespace, pre-configured with everything you need to start testing the project.

- Open a terminal

- Make update's and install dependencies with the command below:
```bash
sudo apt update
sudo apt install curl git-all cmake gcc libssl-dev pkg-config libclang-dev libpq-dev build-essential -y
```

- Get the project from GitHub with the command below:
```bash
git clone https://github.com/lukrycyfa/micro_finance_lender.git
cd micro_finance_lender
```

- Install rust and cargo with the command below:
```bash
curl https://sh.rustup.rs -sSf | sh
```

- Add the path below to env with this command:
```bash
source "$HOME/.cargo/env"
```

- Verify installation with the command below:
```bash
rustc --version
```

- Install Sui. Build from source (Recommended):
    - first make the `download-sui-binaries.sh` file executable and install sui with the command below:
```bash
chmod u+x download-sui-binaries.sh
./download-sui-binaries.sh "v1.18.0" "devnet" "ubuntu-x86_64"
```

- Restart the terminal and verify the installation:
```bash
sui --version
```

- Optionally you could download sui binaries and do a manual installation with the command below:
```bash
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui
```
- Verify installation
```bash
sui --version
```

### Start a local network

- You could start a local test validator with the pre-built installed binary(recommended) by issuing the command below:
```bash
RUST_LOG="off,sui_node=info" sui-test-validator
```

- Optionally, you could start the validator from sources if you installed the sui binaries manually.
```bash
git clone --branch devnet https://github.com/MystenLabs/sui.git
cd sui
RUST_LOG="off,sui_node=info" cargo run --bin sui-test-validator
```

### Build, Publish and Test the Contract.

#### Create Addresses

- To publish and  get a full test coverage of the contract we will be creating two address one for the publisher
the other a test client account.

- Use the command below to generate a new address:

```bash
sui client new-address ed25519
```
- After running this command for the first time, you should see the following output:
Config file ["/home/codespace/.sui/sui_config/client.yaml"] doesn't exist, do you want to connect to a Sui Full node server [y/N]?

Type "y" and press Enter to proceed.

After that, you should see the following output:

Sui Full node server URL (Defaults to Sui Devnet if not specified):

Type the Fullnode RPC URL from the previous section and press Enter to proceed.

After that, you should see the following output:

Environment alias for [http://127.0.0.1:9000] :

Type "localnet" or any other name you want to use for the environment and press Enter to proceed.

Finally, you should see another prompt as follows:

Select key scheme to generate keypair (0 for ed25519, 1 for secp256k1, 2: for secp256r1):
Type "0"
where:
- `ed25519` is the key scheme (other available options are: `ed25519`, `secp256k1`, `secp256r1`)

And the output should be similar to this:
```bash
╭─────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Created new keypair and saved it to keystore.                                                   │
├────────────────┬────────────────────────────────────────────────────────────────────────────────┤
│ address        │ 0x05db1e318f1e4bc19eb3f2fa407b3ebe1e7c3cd8147665aacf2595201f731519             │
│ keyScheme      │ ed25519                                                                        │
│ recoveryPhrase │ lava perfect chef million beef mean drama guide achieve garden umbrella second │
╰────────────────┴────────────────────────────────────────────────────────────────────────────────╯
```
- You could run the command again to generate a second address you would need for the test. 
```bash
sui client new-address ed25519
```

#### Get localnet SUI tokens

- Use the command below to get sui token you would be needing for testing:
```bash
curl --location --request POST 'http://127.0.0.1:9123/gas' --header 'Content-Type: application/json' --data-raw '{
"FixedAmountRequest": {"recipient": "<ADDRESS>"}}'
```
`<ADDRESS>`` - and repalce this value with any of the address you have genarated, do make sure to fund both address.

- Use the command bellow to the get the current acive address
```bash
sui client active-address
```

- You can switch to the address you will be using to publish by running this command:
```bash
sui client switch --address <ADDRESS>
```


#### Build and publish a smart contract

- Issue the command below to build the contarct:
```bash
sui move build
```
- After the succesfull build you could go ahead and publish the contract:
```bash
sui client publish --gas-budget 100000000 --json
```
#### Testing The Contract. 

- After publishing the contract a json object would be returned to the console, there are a couple of values we will be needing to test our contract.
- You could get access to these values on the json object with this path `.objectChanges[]` or just look for the `objectChanges` array on the json object and extract these values:

- `PACKAGE_ID` - this would be the `packageId` of the published package. The json path to it is `.objectChanges[].type` = `published` we would need this for all function calls.

- `TREASURY_CAP_ID` - the `objectId` to the TreasuryCap object. would be on the json path where `.objectChanges[].objectType` = `0x2::coin::TreasuryCap<PACKAGE_ID::usdt::USDT>` we would need this each time we need to mint usdt tokens. 

- `MGM_ACC_ID` - the `objectId` to the managementAccount object. would be on the json path where `.objectChanges[].objectType` = `PACKAGE_ID::smart_lender::ManagementAccount` we would need this for some function calls.

- `MGM_LOANREC_ID` - the `objectId` to the managementLoanRecord object. would be on the json path where `.objectChanges[].objectType` = `PACKAGE_ID::smart_lender::ManagementLoanRecord` we would need this for some function calls.

- On publish a couple of usdt token would have been minted to the publishers account you could access the objectId below:

- `ACC1_USDT_COIN_ID` - the `objectId` to the minted USDT coin object would be on the json path where `.objectChanges[].objectType` = `0x2::coin::Coin<PACKAGE_ID::usdt::USDT>` we would need this to fund loans.

- Make a call from the publishers account to fund loans.

```bash
sui client call --function add_loan_funds --module smart_lender --package PACKAGE_ID --args ACC1_USDT_COIN_ID MGM_ACC_ID MGM_LOANREC_ID 150000000000 --gas-budget 10000000 --json
```  
- where `150000000000 == amount` to be deposited to the `loanFunds`

- On call to this function changes would have occured on the `ManagementLoanRecord`, you could access the object with command below.
```bash
sui client object MGM_LOANREC_ID
```
- the `loanFunds` field should be `==` to the amount deposited.

- Make a call from the publishers account to add a fee class.
```bash
sui client call --function add_fee_class --module smart_lender --package PACKAGE_ID --args MGM_ACC_ID 650000000 9 --gas-budget 10000000 --json
```
- where `650000000 == loanTimeSpan` and `9 == fee` in percentage

- On call to this function changes would have occured on the `ManagementAccount`, you could access the object with command below.
```bash
sui client object MGM_ACC_ID
```  
- You could see a new maping on the `feeClasses` field, copy out the `key` to fee class you just created you would be needing it for taking loans.
- `CLASS_KEY` = `key`  

- To take a loan switch to the other test account with the previous command used to switch accounts.
- first call the function below to get an empty usdt loan coin, because we have not minted any tokens to this account or have any usdt coin related to this account.
```bash
sui client call --function get_empty_loan_coin --module smart_lender --package PACKAGE_ID --gas-budget 10000000 --json
```  
- On call to this function a coin with a zero balance would be transfered to the calling account you could access it's `objectId` from the json object returned to the terminal, on the json path where `.objectChanges[].objectType` = `0x2::coin::Coin<PACKAGE_ID::usdt::USDT>` we would need this `objectId` to collect loans.
- `LOAN_COIN_ID` = `objectId`

- Before calling the loan function we are going to be needing tokens for collateral's i.e sui tokens. Previously we requested tokens for both account's if you did not you could get sui tokens with procedure from this section `Get localnet SUI tokens`.

- Issue this command below and get an sui token `objectId`. 
```bash
sui client objects
```
- You would have a list of objects, access the coin objects and get any with enough sui tokens for a collateral, to access an object issue this command:
```bash
sui client object objectId
```
- `COLLATERAL_COIN_ID` = `objectId`

- Take a loan

```bash
sui client call --function take_loan --module smart_lender --package PACKAGE_ID  --args COLLATERAL_COIN_ID  LOAN_COIN_ID MGM_LOANREC_ID MGM_ACC_ID 20000000000 CLASS_KEY`  --gas-budget 10000000 --json
```
- Where `loanAmount == 20000000000` and would equal 80% of the collateral.

- On call to this function a json object would be returned to the terminal and some changes would have occured on the `ManagementLoanRecord`,`LOAN_COIN_ID object` e.t.c, you could access the objects with previous commands and see the changes, but what we really need is the object transfered to the calling account i.e on the object changes where `.objectChanges[].objectType` = `PACKAGE_ID::smart_lender::LoanToClient`, get the `objectId` abd access the object. You could see the new loan information on the object. We would need this `objectId` when we want to repay the loan.
- `LOAN_TO_CLIENT_ID` = `objectId`

- Repay a loan
- To repay a loan we would be needing enough usdt tokens to cover both loan and fee and our collected loan would not be enough, so we would need to switch to the publishers account and mint usdt tokens to the current active account. First switch to the publishers account with the previous command to switch accounts and call this function.
```bash
sui client call --function mint --module usdt --package PACKAGE_ID --args TREASURY_CAP_ID 80000000000 TEST_ACC2_ADDRESS  --gas-budget 10000000 --json
```
- where `amount == 80000000000` i.e amount to be minted to recipient and `recipient == TEST_ACC2_ADDRESS`

- On call to this function the minted coin would be transfered to the recipient you could access its `objectId` from the json object returned to the terminal, on this json path where `.objectChanges[].objectType` = `0x2::coin::Coin<PACKAGE_ID::usdt::USDT>` we would need this `objectId` to pay-back loans. You could use the previous `COLLATERAL_COIN_ID` to collect your collateral.

- `TOKENFORPAY_ID` = `objectId`

- Now switch back to the test account owning the loan and call the repay function:

```bash
sui client call --function pay_loan --module smart_lender --package PACKAGE_ID  --args TOKENFORPAY_ID COLLATERAL_COIN_ID MGM_LOANREC_ID  LOAN_TO_CLIENT_ID  --gas-budget 10000000 --json
```

- On call to this function a json object would be returned to the terminal and some changes would have occured on the `ManagementLoanRecord`,`TOKENFORPAY_ID object`, `COLLATERAL_COIN_ID object` `LOAN_TO_CLIENT_ID object` e.t.c, you could access the objects with previous commands and see the changes. All balances should be as expected, except for the fee balance in the `ManagementLoanRecord` object that would increase by 3% if you waisted some time to repay the loan.

## Other Test Function calls

- `remove_loan_from_record`
```bash
sui client call --function remove_loan_from_record --module smart_lender --package PACKAGE_ID  --args  MGM_ACC_ID MGM_LOANREC_ID  CLIENT_ADDRESS LOAN_KEY  --gas-budget 10000000 --json
```
- Where `LOAN_KEY` is the key to the loan in record. Could be accessed from entries in `ManagementLoanRecord`|`clientLoans`.

- `remove_fee`
```bash
sui client call --function remove_fee --module smart_lender --package PACKAGE_ID  --args  MGM_ACC_ID FEE_KEY --gas-budget 10000000 --json
```
- Where `FEE_KEY` is the key to the feeClass in record. Could be accessed from entries in `ManagementAccount`|`feeClass`.

- `delete_loan`
```bash
sui client call --function delete_loan --module smart_lender --package PACKAGE_ID  --args  LOAN_TO_CLIENT_ID  --gas-budget 10000000 --json
```

- `withdraw_returned_loans` 
```bash
sui client call --function withdraw_returned_loans --module smart_lender --package   --args TO_COIN_ID MGM_ACC_ID MGM_LOANREC_ID amount  --gas-budget 10000000 --json
```

- `withdraw_paid_fees` 
```bash
sui client call --function withdraw_paid_fees --module smart_lender --package   --args TO_COIN_ID MGM_ACC_ID MGM_LOANREC_ID amount  --gas-budget 10000000 --json
```

- `merge_balances_sui` 
```bash
sui client call --function merge_balances_sui --module smart_lender --package   --args TO_KEEP_COIN_ID TO_TEAR_COIN_ID --gas-budget 10000000 --json
```

- `merge_balances_usd` 
```bash
sui client call --function merge_balances_usd --module smart_lender --package   --args TO_KEEP_COIN_ID TO_TEAR_COIN_ID --gas-budget 10000000 --json
```

- `transfer_sui` 
```bash
sui client call --function transfer_sui --module smart_lender --package   --args FROM_COIN_ID RECIPIENT_ADDRESS amount --gas-budget 10000000 --json
```

- `transfer_usd` 
```bash
sui client call --function transfer_usd --module smart_lender --package   --args FROM_COIN_ID RECIPIENT_ADDRESS amount --gas-budget 10000000 --json
```