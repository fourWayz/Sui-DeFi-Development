module Token::main {
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

    // Transaction struct
    struct Transaction has store, copy, drop { // Defining the Transaction struct
        transaction_type: String, // Type of transaction
        amount: u64, // Amount involved in the transaction
        to: Option<address>, // Receiver address if applicable
        from: Option<address>, // Sender address if applicable
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

    // Create a new tokenized gaming asset
    public fun create_asset(ctx: &mut TxContext, clock: &Clock) { // Function to create a new tokenized gaming asset
        let id = object::new(ctx); // Generate a new object ID
        let total_supply = balance::zero(); // Initialize total supply to zero
        let owner = tx_context::sender(ctx); // Set the owner as the sender
        let create_date = clock::timestamp_ms(clock); // Get the current timestamp as creation date
        let updated_date = create_date; // Set the updated date to creation date initially
        let transactions = vector::empty<Transaction>(); // Initialize transactions vector
        transfer::share_object(TokenizedGamingAsset { // Share the tokenized gaming asset object
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
        amount: Coin<SUI>,
        ctx: &mut TxContext,
        clock: &Clock
    ) {
        asset.total_supply = balance::join(asset.total_supply, amount); // Increase total supply
        let transaction = Transaction { // Create a mint transaction
            transaction_type: string::utf8(b"mint"),
            amount: coin::value(&amount),
            to: some(asset.owner), // Tokens are minted to the asset owner
            from: none(),
        };
        vector::push_back(&mut asset.transactions, transaction); // Record the mint transaction
        asset.updated_date = clock::timestamp_ms(clock); // Update the asset's updated date
    }

    // Burn tokens from the asset
    public fun burn_tokens(
        asset: &mut TokenizedGamingAsset,
        amount: u64,
        ctx: &mut TxContext,
        clock: &Clock
    ) {
        assert!(
            coin::value(&asset.total_supply) >= amount,
            INSUFFICIENT_BALANCE
        ); // Assert if there are enough tokens to burn
        asset.total_supply = coin::split(&mut asset.total_supply, amount, ctx); // Decrease total supply
        let transaction = Transaction { // Create a burn transaction
            transaction_type: string::utf8(b"burn"),
            amount: amount,
            to: none(),
            from: some(asset.owner), // Tokens are burned from the asset owner
        };
        vector::push_back(&mut asset.transactions, transaction); // Record the burn transaction
        asset.updated_date = clock::timestamp_ms(clock); // Update the asset's updated date
    }

    // Transfer tokens between accounts
    public fun transfer_tokens(
        asset: &mut TokenizedGamingAsset,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext,
        clock: &Clock
    ) {
        assert!(
            coin::value(&asset.total_supply) >= amount,
            INSUFFICIENT_BALANCE
        ); // Assert if there are enough tokens to transfer
        let transaction = Transaction { // Create a transfer transaction
            transaction_type: string::utf8(b"transfer"),
            amount: amount,
            to: some(recipient),
            from: some(asset.owner), // Tokens are transferred from the asset owner
        };
        vector::push_back(&mut asset.transactions, transaction); // Record the transfer transaction
        asset.updated_date = clock::timestamp_ms(clock); // Update the asset's updated date
        transfer::public_transfer(coin::new(ctx, amount), recipient); // Transfer tokens to the recipient
    }

    // Get the total supply of the asset
    public fun get_total_supply(asset: &TokenizedGamingAsset) : u64 {
        coin::value(&asset.total_supply) // Return the total supply
    }

    // Get the owner of the asset
    public fun get_owner(asset: &TokenizedGamingAsset) :address {
        asset.owner // Return the owner
    }

    // Get the creation date of the asset
    public fun get_create_date(asset: &TokenizedGamingAsset): u64 {
        asset.create_date // Return the creation date
    }

    // Get the last updated date of the asset
    public fun get_updated_date(asset: &TokenizedGamingAsset) : u64 {
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
    ) : (String, u64, Option<address>, Option<address>) {
        assert!(
            index < vector::length(&asset.transactions),
            INVALID_INDEX
        ); // Assert if the index is within bounds
        let transaction = vector::borrow(&asset.transactions, index); // Get the transaction at the specified index
        (
            transaction.transaction_type,
            transaction.amount,
            transaction.to,
            transaction.from,
        ) // Return transaction details
    }

        // Update the owner of the asset
    public fun update_owner(
        asset: &mut TokenizedGamingAsset,
        new_owner: address,
        clock: &Clock,
    ) {
        asset.owner = new_owner; // Update the owner
        asset.updated_date = clock::timestamp_ms(clock); // Update the asset's updated date
    }

    // Get the balance of the asset owner
    public fun get_owner_balance(asset: &TokenizedGamingAsset) : u64 {
        coin::value(&asset.total_supply) // Return the total supply as owner balance
    }

    // View all transactions of the asset
    public fun view_all_transactions(
        asset: &TokenizedGamingAsset,
        ctx: &mut TxContext,
    ) : vector<(String, u64, Option<address>, Option<address>)> {
        asset.transactions // Return all transactions
    }

}
