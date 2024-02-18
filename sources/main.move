/*
Disclaimer: Use of Unaudited Code for Educational Purposes Only
This code is provided strictly for educational purposes and has not undergone any formal security audit. 
It may contain errors, vulnerabilities, or other issues that could pose risks to the integrity of your system or data.

By using this code, you acknowledge and agree that:
    - No Warranty: The code is provided "as is" without any warranty of any kind, either express or implied. The entire risk as to the quality and performance of the code is with you.
    - Educational Use Only: This code is intended solely for educational and learning purposes. It is not intended for use in any mission-critical or production systems.
    - No Liability: In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the use or performance of this code.
    - Security Risks: The code may not have been tested for security vulnerabilities. It is your responsibility to conduct a thorough security review before using this code in any sensitive or production environment.
    - No Support: The authors of this code may not provide any support, assistance, or updates. You are using the code at your own risk and discretion.

Before using this code, it is recommended to consult with a qualified professional and perform a comprehensive security assessment. By proceeding to use this code, you agree to assume all associated risks and responsibilities.
*/

//The smart_lender contract module construct
#[lint_allow(self_transfer), allow(lint(coin_field))]
module micro_finance_lender::smart_lender {

    // Import dependencies and module components to be used
    use sui::coin::{Coin, Self};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID, ID};    
    use sui::vec_map::{Self, VecMap};
    use sui::transfer;
    use std::option::Option;
    use sui::tx_context::{TxContext, Self};
    use sui::sui::SUI;
    use micro_finance_lender::usdt::USDT;

    // The Newloan struct meant for creating instances for loans 
    // information
    struct NewLoan has store, copy, drop {
        collateralId: ID,
        collateralValue: u64,
        loanedAmount: u64,
        fee: u64,
        clientAddress: address,
        rePaid: bool,
        loanTimeSpan: u64
    } 

    // The LoanToClient struct meant to create the loan object to be sent 
    // to the client
    struct LoanToClient has key, store {
        id: UID,
        loanKey: ID,
        loanInfo: NewLoan         
    }

    // The NewFee struct meant for creating instances of Fees for Loans 
    struct NewFee has store, copy, drop {
        loanTimeSpan: u64,
        fee: u64
    }

    // The ManagementAccount struct, a shared object carrying fee information
    // and managment account address
    struct ManagementAccount has key, store {
        id: UID,
        feeClasses: VecMap<ID, NewFee>,
        accountAddress: address
    }

    // The ManagementLoanRecord struct, a shared object carrying Client loans, loan collaterals,
    // loan funds, returned loans and paid fees information.
    struct ManagementLoanRecord has key, store  {
        id: UID,
        clientLoans: VecMap<address, VecMap<ID, NewLoan>>,
        loanCollaterals: VecMap<ID, Balance<SUI>>,
        loanFunds: Balance<USDT>,
        returnedLoans: Balance<USDT>,
        paidFees: Balance<USDT>
    }

    //extra fee added when a loan exceeds payment time
    const Exceed_Payment_Time_Penalty: u64 = 3;

    /// Error codes
    const EUNAUTHORIZED_CALLER: u64 = 0;
    const EINSUFFICIENT_BALANCE: u64 = 1;
    const EINVALID_VALUE: u64 = 2;
    const EINVALID_REPAY_TRANSACTION: u64 = 3;
    const EINVALID_OPERATION_ON_INCOMPLETE_TRANSACTION: u64 = 4;
    const EINVALID_RECORD: u64 = 5;
    const EINSUFFICIENT_LOAN_FUNDS: u64 = 6;
    
    // Initialize the smart_lender contract
    fun init(ctx: &mut TxContext) {
        //Create a new instance of a ManagementLoanRecord
        let mgmloans: ManagementLoanRecord = ManagementLoanRecord {
            id: object::new(ctx),
            clientLoans: vec_map::empty(),
            loanCollaterals: vec_map::empty(),
            loanFunds: balance::zero<USDT>(),
            returnedLoans: balance::zero<USDT>(),
            paidFees: balance::zero<USDT>()
        };
    
        //Create a new instance of a ManagementAccount
        let mgmacc: ManagementAccount = ManagementAccount {
            id: object::new(ctx),
            feeClasses: vec_map::empty(),
            accountAddress: tx_context::sender(ctx)
        };
        
        //Transfer both created instances as shared objects
        transfer::share_object(mgmloans);
        transfer::share_object(mgmacc);
    }

    // Create's and sends an empty USDT coin to the tx_sender i.e zero balance, having TxContext as it's arg 
    public entry fun get_empty_loan_coin(ctx: &mut TxContext) {
        // create and transfer coin
        transfer::public_transfer(coin::zero<USDT>(ctx), tx_context::sender(ctx));
    }

    // Called with the publishers account to create a new fee class to be used by clients taking loans. taking the `ManagementAccount`, a `loantimespan`,
    // a `fee` and `TxContext` as args. fee should be a value from 1-99 as its calculated in percentages.
    public entry fun add_fee_class(mgm: &mut ManagementAccount, loantimespan: u64, fee: u64, ctx: &mut TxContext): NewFee {
        // Make assertions on the tx_sender, fee and loantimespan then create an instance of a new fee and add it to
        // the management feeClasses.
        assert!(tx_context::sender(ctx) == mgm.accountAddress, EUNAUTHORIZED_CALLER);
        assert!(fee > 0 && loantimespan > 0, EINVALID_VALUE);
        let _feeclass = NewFee {
            loanTimeSpan: loantimespan,
            fee: fee
        };
        vec_map::insert(&mut mgm.feeClasses, object::id_from_address(tx_context::fresh_object_address(ctx)), _feeclass);
        _feeclass
    }
    
    // Called with the publishers account to add to the ManagementLoanRecord `loanFunds` to avail tokens for clients taking loans. Having `fundsbucket:&mut Coin<USDT>` i.e the coin to deposit from, 
    //`ManagementAccount`, `ManagementLoanRecord`, `amount` i.e the amount to deposit and TxContext as args. 
    public entry fun add_loan_funds(fundsbucket:&mut Coin<USDT>, mgm: &mut ManagementAccount, mgmloans: &mut ManagementLoanRecord, amount: u64,
        ctx: &mut TxContext){
        // make assertions on the tx_sender, take amount from fundsbucket and add to loanFunds.    
        assert!(tx_context::sender(ctx) == mgm.accountAddress, EUNAUTHORIZED_CALLER);
        let _addfunds = balance::split(coin::balance_mut(fundsbucket), amount);
        balance::join(&mut mgmloans.loanFunds, _addfunds); 
    }

    // Called with a client's account to get loans from the contract, taking `collateraltoken: &mut Coin<SUI>` i.e the token to withdraw a collateral from,
    // `receiveloantoken: &mut Coin<USDT>` i.e the token to deposite a loan into 
    // `ManagementLoanRecord`, `ManagementAccount`, `loanAmount` i.e the amount to loan, classKey i.e the fee class key and TxContext as args.
    public entry fun take_loan(collateraltoken: &mut Coin<SUI>, receiveloantoken: &mut Coin<USDT>, mgmloans: &mut ManagementLoanRecord,
        mgm: &ManagementAccount, loanAmount: u64, classKey: ID, ctx: &mut TxContext): NewLoan {
        // make assertions on the `classKey`, `mgmloans.loanFunds` and `loanAmount`, derive a collateral, collateralId,
        // fee and create a NewLoan instance.    
        assert!(vec_map::contains(&mgm.feeClasses, &classKey), EINVALID_RECORD);  
        assert!(balance::value(&mgmloans.loanFunds) > loanAmount, EINSUFFICIENT_LOAN_FUNDS);  
        assert!(loanAmount > 1_000_000, EINVALID_VALUE);

        let _feeclass = vec_map::get(&mgm.feeClasses, &classKey);
        let _balance = coin::balance_mut(collateraltoken);
        let _collateral = loanAmount*120/100;// derive a collateral from a loan where the loanamount == 80% of the returned collateral.
        let _collateralbalance = balance::split(_balance, _collateral);
        let _collateralvalue = balance::value(&_collateralbalance);
        let _collateralid = object::id_from_address(tx_context::fresh_object_address(ctx));
        vec_map::insert(&mut mgmloans.loanCollaterals, _collateralid, _collateralbalance);
        let _fee = loanAmount*_feeclass.fee/100; 
        let _newLoan = NewLoan {
            collateralId: _collateralid,
            collateralValue: _collateralvalue,
            loanedAmount: loanAmount,
            fee: _fee,
            clientAddress: tx_context::sender(ctx),
            rePaid: false,
            loanTimeSpan: _feeclass.loanTimeSpan + tx_context::epoch_timestamp_ms(ctx)
        };
        
        // create a new loan vec_map for the client if there is non recorded, generate a loanId, map loanid to newloan 
        // on `mgmloans.clientLoans`. take `loanAmount` from `mgmloans.loanFunds` and add to `receiveloantoken`
        // then transfer a new instance of LoanToClient to tx_sender.
        if (!vec_map::contains(&mgmloans.clientLoans, &tx_context::sender(ctx))){
            vec_map::insert(&mut mgmloans.clientLoans, tx_context::sender(ctx), vec_map::empty());
        };

        let _loanid = object::id_from_address(tx_context::fresh_object_address(ctx));
        vec_map::insert(vec_map::get_mut(&mut mgmloans.clientLoans, &tx_context::sender(ctx)), _loanid, _newLoan);
        let _loaned = balance::split(&mut mgmloans.loanFunds, loanAmount);
        balance::join(coin::balance_mut(receiveloantoken), _loaned);
        transfer::public_transfer(LoanToClient { id: object::new(ctx), loanKey: _loanid, loanInfo: _newLoan }, tx_context::sender(ctx));
        _newLoan
    }


    // Called by a client to pay for collected loans, taking `payment: &mut Coin<USDT>` i.e the token to repay loans from, 
    // `receivelcollateraltoken: &mut Coin<SUI>` i.e the token to deposite collaterals into, `ManagementLoanRecord`,
    // `LoanToClient` and `TxContext`  
    public entry fun pay_loan(payment: &mut Coin<USDT>, receivelcollateraltoken: &mut Coin<SUI>, mgmloans: &mut ManagementLoanRecord, 
    loanobject: &mut LoanToClient, ctx: &mut TxContext) {
        // make assertions on tx_sender and `loanobject.loanKey` against `mgmloans.clientLoans`,
        // make assertions on loans `rePaid` status, derive a repaid amount and fee and assert against payment balance.
        assert!(vec_map::contains(&mgmloans.clientLoans, &tx_context::sender(ctx)), EINVALID_RECORD); 
        assert!(vec_map::contains(vec_map::get(&mgmloans.clientLoans, &tx_context::sender(ctx)), &loanobject.loanKey), EINVALID_RECORD);

        let _paybackloan = vec_map::get_mut(vec_map::get_mut(&mut mgmloans.clientLoans, &tx_context::sender(ctx)), &loanobject.loanKey); 
        assert!(!_paybackloan.rePaid, EINVALID_REPAY_TRANSACTION);

        let _balancevalue = coin::value(payment);
        let _paymentbalance = coin::balance_mut(payment);
        let _repay: u64 = _paybackloan.loanedAmount;
        let _fee: u64 = if (_paybackloan.loanTimeSpan >= tx_context::epoch_timestamp_ms(ctx)) {_paybackloan.fee} else {(_paybackloan.fee + (_paybackloan.loanedAmount*Exceed_Payment_Time_Penalty/100))}; 
        
        assert!(_balancevalue >= _repay + _fee, EINSUFFICIENT_BALANCE);

        //get a fee and payment balance and add to `mgmloans.paidFees` and `mgmloans.returnedLoans`,
        //get the collateral balance and merge with `receivelcollateraltoken` then mark `rePaid` status as true.
        let _taketomgm = balance::split(_paymentbalance, _repay);
        let _takefee = balance::split(_paymentbalance, _fee);
        balance::join(&mut mgmloans.returnedLoans, _taketomgm);
        balance::join(&mut mgmloans.paidFees, _takefee);
        let _collateralvalue = balance::value(vec_map::get(&mgmloans.loanCollaterals, &_paybackloan.collateralId));
        
        let _collateral = balance::split(vec_map::get_mut(&mut mgmloans.loanCollaterals, &_paybackloan.collateralId), _collateralvalue);
        balance::join(coin::balance_mut(receivelcollateraltoken), _collateral);
        _paybackloan.rePaid = true;
        loanobject.loanInfo.rePaid = true;
    }

    // Called With the publishers account to remove a loan from record. Having `ManagementAccount`, `ManagementLoanRecord`, `clientAddress` 
    // `loanKey` and TxContext as args.
    public entry fun remove_loan_from_record(mgm: &ManagementAccount, mgmloans: &mut ManagementLoanRecord, clientAddress: address, loanKey: ID, ctx:&TxContext): (ID, NewLoan) {
        // make assertions on tx_sender, then `loanKey` and clientAddress against `mgmloans.clientLoans`,
        assert!(tx_context::sender(ctx) == mgm.accountAddress, EUNAUTHORIZED_CALLER);
        assert!(vec_map::contains(&mgmloans.clientLoans, &clientAddress), EINVALID_RECORD); 
        assert!(vec_map::contains(vec_map::get(&mgmloans.clientLoans, &clientAddress), &loanKey), EINVALID_RECORD);

        let _updateloan = vec_map::get(vec_map::get(&mgmloans.clientLoans, &clientAddress), &loanKey);
        // make assertions on loans `rePaid` status and finally remove the loan from record.
        assert!(_updateloan.rePaid, EINVALID_OPERATION_ON_INCOMPLETE_TRANSACTION);

        vec_map::remove(vec_map::get_mut(&mut mgmloans.clientLoans, &clientAddress), &loanKey)
    }

    // Called With the publishers account to remove a fee from record. Having `ManagementAccount`, `feeKey` and TxContext as args.
    public entry fun remove_fee(mgm: &mut ManagementAccount, feeKey: ID, ctx:&TxContext): (ID, NewFee) {
        // make assertions on tx_sender and feeKey, then finally remove the fee from record.
        assert!(tx_context::sender(ctx) == mgm.accountAddress, EUNAUTHORIZED_CALLER);
        assert!(vec_map::contains(&mgm.feeClasses,  &feeKey), EINVALID_RECORD); 

        vec_map::remove(&mut mgm.feeClasses,  &feeKey)
    }

    // Called by a client to delete a loan object..
    #[allow(unused_assignment, unused_variable)]
    public entry fun delete_loan(loan: LoanToClient, ctx: &mut TxContext) {
        let LoanToClient { id, loanKey, loanInfo } = loan;
        // make assertions on the repaid status and delete the LoanToClientloan object
        assert!(loanInfo.rePaid, EINVALID_OPERATION_ON_INCOMPLETE_TRANSACTION);
        object::delete(id)
    }

    // Called to return all fee classes.
    public entry  fun get_fees(mgm: &ManagementAccount): VecMap<ID, NewFee> {
        mgm.feeClasses
    }

    // Called to return all loans associated with calling address.
    public entry fun get_client_loans(mgmloans: &ManagementLoanRecord, ctx:&TxContext ): Option<VecMap<ID, NewLoan>> {
        vec_map::try_get(&mgmloans.clientLoans, &tx_context::sender(ctx))
    }

    // Called by the publishers account to return all loan record.
    public entry fun get_loan_record(mgm: &ManagementAccount, mgmloans: &ManagementLoanRecord, ctx:&TxContext): VecMap<address, VecMap<ID, NewLoan>> {
        assert!(tx_context::sender(ctx) == mgm.accountAddress, EUNAUTHORIZED_CALLER);

        mgmloans.clientLoans
    }

    // Called by the publishers account to withdraw returned loans. taking `tocoin: &mut Coin<USDT>` i.e the coin to withdraw into, `ManagementAccount`, `ManagementLoanRecord`, 
    // `amount` the amount to withdraw and TxContext as args 
    public entry fun withdraw_returned_loans(tocoin: &mut Coin<USDT>, mgm: &ManagementAccount, mgmloans: &mut ManagementLoanRecord, amount: u64, ctx: &mut TxContext){
        // make assertions on tx_sender, `mgmloans.returnedLoans` and `amount`. finally withdraw token into `tocoin`.
        assert!(tx_context::sender(ctx) == mgm.accountAddress, EUNAUTHORIZED_CALLER);
        assert!(balance::value(&mgmloans.returnedLoans) > amount, EINSUFFICIENT_BALANCE); 

        let _witdraw = balance::split(&mut mgmloans.returnedLoans, amount);
        balance::join(coin::balance_mut(tocoin), _witdraw);
    }

    // Called by the publishers account to withdraw returned fees. taking `tocoin: &mut Coin<USDT>` i.e the coin to withdraw into, `ManagementAccount`, `ManagementLoanRecord`, 
    // `amount` the amount to withdraw and TxContext as args
    public entry fun withdraw_paid_fees(tocoin: &mut Coin<USDT>, mgm: &ManagementAccount, mgmloans: &mut ManagementLoanRecord, amount: u64, ctx: &mut TxContext){
        // make assertions on tx_sender, `mgmloans.paidFees` and `amount`. finally withdraw token into `tocoin`.
        assert!(tx_context::sender(ctx) == mgm.accountAddress, EUNAUTHORIZED_CALLER);
        assert!(balance::value(&mgmloans.paidFees) > amount, EINSUFFICIENT_BALANCE); 

        let _witdraw = balance::split(&mut mgmloans.paidFees, amount);
        balance::join(coin::balance_mut(tocoin), _witdraw);
    }

    // Called to merge two sui coin into one, taking two Coin<SUI> as args
    public entry fun merge_balances_sui(keep: &mut Coin<SUI>, teardown: Coin<SUI>){
        coin::join(keep , teardown);
    }

    // Called to merge two usdt coin into one, taking two Coin<USDT> as args
    public entry fun merge_balances_usd(keep: &mut Coin<USDT>, teardown: Coin<USDT>){
        coin::join(keep , teardown);
    }

    // Called to transfer sui coin. taking `coin: &mut Coin<SUI>` i.e the coin to transfer from, 
    // `recipient`, `amount`, and `TxContext` as args
    public entry fun transfer_sui(coin: &mut Coin<SUI>, recipient: address, amount: u64, ctx: &mut TxContext){
        let val = coin::value(coin);
        let balance = coin::balance_mut(coin);
        assert!(val > amount, EINSUFFICIENT_BALANCE);
        let _taken: Coin<SUI>  = coin::take(balance, amount, ctx);
        transfer::public_transfer( _taken, recipient);
    }

    // Called to transfer usdt coin. taking `coin: &mut Coin<USDT>` i.e the coin to transfer from, 
    // `recipient`, `amount`, and `TxContext` as args
    public entry fun transfer_usd(coin: &mut Coin<USDT>, recipient: address, amount: u64, ctx: &mut TxContext){
        let val = coin::value(coin);
        let balance = coin::balance_mut(coin);
        assert!(val > amount, EINSUFFICIENT_BALANCE);
        let _taken: Coin<USDT>  = coin::take(balance, amount, ctx);
        transfer::public_transfer( _taken, recipient);
    }

}
