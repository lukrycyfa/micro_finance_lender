// /*
// Disclaimer: Use of Unaudited Code for Educational Purposes Only
// This code is provided strictly for educational purposes and has not undergone any formal security audit. 
// It may contain errors, vulnerabilities, or other issues that could pose risks to the integrity of your system or data.

// By using this code, you acknowledge and agree that:
//     - No Warranty: The code is provided "as is" without any warranty of any kind, either express or implied. The entire risk as to the quality and performance of the code is with you.
//     - Educational Use Only: This code is intended solely for educational and learning purposes. It is not intended for use in any mission-critical or production systems.
//     - No Liability: In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the use or performance of this code.
//     - Security Risks: The code may not have been tested for security vulnerabilities. It is your responsibility to conduct a thorough security review before using this code in any sensitive or production environment.
//     - No Support: The authors of this code may not provide any support, assistance, or updates. You are using the code at your own risk and discretion.

// Before using this code, it is recommended to consult with a qualified professional and perform a comprehensive security assessment. By proceeding to use this code, you agree to assume all associated risks and responsibilities.
// */

//The test usdt contract module construct
module micro_finance_lender::usdt {
    // Import dependencies and module components to be used
    use sui::coin::{Coin, TreasuryCap, Self};
    use std::option;
    use sui::transfer;
    use sui::tx_context::{TxContext, Self};

    // The usdt struct to be the one time withness
    struct USDT has drop {}


    const FLOAT_SCALING: u64 = 1_000_000;

    // Initialize the usdt contract
    #[allow(unused_function)]
    fun init(witness: USDT, ctx: &mut TxContext) {
        // create the currency, mint and transfer specified amount and treasury to the publisher publisher.
        let (treasury, metadata) = coin::create_currency(witness, 6, b"USDT", b"Tether", 
                                    b"Bridged Tether token", option::none(), ctx);
        coin::mint_and_transfer(&mut treasury, 250_000 * FLOAT_SCALING, tx_context::sender(ctx), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury, tx_context::sender(ctx));    
    }

    // mint and transfer tokens to recipient
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<USDT>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);
    }

    // burn tokens 
    public entry fun burn(treasury_cap: &mut TreasuryCap<USDT>, coin: Coin<USDT>) {
        coin::burn(treasury_cap, coin);
    }  

}
