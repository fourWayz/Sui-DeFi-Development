#[lint_allow(self_transfer)] // Allowing self transfer lint
#[allow(unused_use)] // Allowing unused imports

module dacade_deepbook::book {
    // Import necessary modules
    use sui::tx_context::{Self, TxContext}; // Importing TxContext module
    use sui::object::{Self, ID, UID}; // Importing object module with specific items
    use sui::coin::{Self, Coin}; // Importing Coin module
    use sui::table::{Table, Self}; // Importing Table module
    use sui::transfer; // Importing transfer module
    use sui::sui::SUI;
    use sui::clock::{Self, Clock}; // Importing Clock module
    use std::string::{Self, String}; // Importing String module
    use std::vector; // Importing vector module
    use std::option::{Option, none, some}; // Importing Option module with specific items
    use sui::balance::{Self, Balance};

    // Error codes
    const INSUFFICIENT_BALANCE: u64 = 1; // Error code for insufficient balance
    const INVALID_INDEX: u64 = 2; // Error code for invalid index
    const ENOT_OWNER: u64 = 3; // New error code for not being the owner

    // Transaction struct
    struct Transaction has store, copy, drop { // Defining the Transaction struct
        transaction_type: String, // Type of transaction
        amount: u64, // Amount involved in the transaction
        to: Option<address>, // Receiver address if applicable
        from: Option<address>, // Sender address if applicable
        timestamp: u64, // Timestamp of the transaction
        description: String, // Description of the transaction
    }

    // Asset struct
    struct TokenizedGamingAsset has key, store { // Defining the TokenizedGamingAsset struct
        id: UID, // Asset ID
        create_date: u64, // Creation date of the asset
        updated_date: u64, // Last updated date of the asset
        total_supply: Balance<SUI>, // Total supply of the asset
        owner: address, // Owner of the asset
        transactions: vector<Transaction>, // List of transactions associated with the asset
    }

    // Helper function to handle balance updates and record transactions
    fun handle_balance_update(
        asset: &mut TokenizedGamingAsset,
        amount: u64,
        transaction_type: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let transaction_description = string::utf8(b""); // Add a description if needed
        if transaction_type == b"mint" {
            asset.total_supply = balance::join(asset.total_supply, coin::take(&mut coin::new(ctx, amount), ctx));
        } else if transaction_type == b"burn" {
            asset.total_supply = coin::split(&mut asset.total_supply, amount, ctx);
        };
        let transaction = Transaction {
            transaction_type: string::utf8(transaction_type),
            amount: amount,
            to: if transaction_type == b"mint" { some(asset.owner) } else { none() },
            from: if transaction_type == b"burn" { some(asset.owner) } else { none() },
            timestamp: clock::timestamp_ms(clock),
            description: transaction_description,
        };
        vector::push_back(&mut asset.transactions, transaction);
        asset.updated_date = clock::timestamp_ms(clock);
    }

    // Create a new tokenized gaming asset
    public fun create_asset(ctx: &mut TxContext, clock: &Clock) { // Function to create a new tokenized gaming asset
        let id = object::new(ctx); // Generate a new object ID
        let total_supply = balance::zero(); // Initialize total supply to zero
        let owner = tx_context::sender(ctx); // Set the owner as the sender
        let create_date = clock::timestamp_ms(clock); // Get the current timestamp as creation date
        let updated_date = create_date; // Set the updated date to creation date initially
        let transactions = vector::empty<Transaction>(); // Initialize transactions vector
        transfer::share_object(TokenizedGamingAsset {
            id,
            create_date,
            updated_date,
            total_supply,
            owner,
            transactions,
        });
    }

    // Mint new tokens for the asset
    public fun mint_tokens(
        asset: &mut TokenizedGamingAsset,
        amount: u64,
        ctx: &mut TxContext,
        clock: &Clock
    ) {
        handle_balance_update(asset, amount, b"mint", clock, ctx);
    }

    // Burn tokens from the asset
    public fun burn_tokens(
        asset: &mut TokenizedGamingAsset,
        amount: u64,
        ctx: &mut TxContext,
        clock: &Clock
    ) {
        assert!(coin::value(&asset.total_supply) >= amount, INSUFFICIENT_BALANCE);
        handle_balance_update(asset, amount, b"burn", clock, ctx);
    }

    // Transfer tokens between accounts
    public fun transfer_tokens(
        asset: &mut TokenizedGamingAsset,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext,
        clock: &Clock
    ) {
        assert!(tx_context::sender(ctx) == asset.owner, ENOT_OWNER); // Additional check
        assert!(coin::value(&asset.total_supply) >= amount, INSUFFICIENT_BALANCE);
        transfer::public_transfer(coin::take(&mut asset.total_supply, amount, ctx), recipient);
        let transaction = Transaction {
            transaction_type: string::utf8(b"transfer"),
            amount: amount,
            to: some(recipient),
            from: some(asset.owner),
            timestamp: clock::timestamp_ms(clock),
            description: string::utf8(b"Token transfer"),
        };
        vector::push_back(&mut asset.transactions, transaction);
        asset.updated_date = clock::timestamp_ms(clock);
    }

    // Get the total supply of the asset
    public fun get_total_supply(asset: &TokenizedGamingAsset): u64 {
        coin::value(&asset.total_supply) // Return the total supply
    }

    // Get the owner of the asset
    public fun get_owner(asset: &TokenizedGamingAsset): address {
        asset.owner // Return the owner
    }

    // Get the creation date of the asset
    public fun get_create_date(asset: &TokenizedGamingAsset): u64 {
        asset.create_date // Return the creation date
    }

    // Get the last updated date of the asset
    public fun get_updated_date(asset: &TokenizedGamingAsset): u64 {
        asset.updated_date // Return the last updated date
    }

    // Get the number of transactions associated with the asset
    public fun get_transactions_count(asset: &TokenizedGamingAsset): u64 {
        vector::length(&asset.transactions) // Return the number of transactions
    }

    // View a specific transaction of the asset
    public fun view_transaction(
        asset: &TokenizedGamingAsset,
        index: u64
    ): (String, u64, Option<address>, Option<address>, u64, String) {
        assert!(index < vector::length(&asset.transactions), INVALID_INDEX);
        let transaction = vector::borrow(&asset.transactions, index);
        (
            transaction.transaction_type,
            transaction.amount,
            transaction.to,
            transaction.from,
            transaction.timestamp,
            transaction.description,
        )
    }

    // Update the owner of the asset
    public fun update_owner(
        asset: &mut TokenizedGamingAsset,
        new_owner: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == asset.owner, ENOT_OWNER); // Additional check
        asset.owner = new_owner;
        asset.updated_date = clock::timestamp_ms(clock);
    }

    // Get the balance of the asset
public fun get_asset_balance(asset: &TokenizedGamingAsset): u64 {
        coin::value(&asset.total_supply) // Return the total supply as asset balance
    }

    // View all transactions of the asset
    public fun view_all_transactions(
        asset: &TokenizedGamingAsset,
    ): &vector<Transaction> {
        &asset.transactions // Return a reference to the transactions vector
    }
}
