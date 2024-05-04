#[lint_allow(self_transfer)] // Allowing self transfer lint
#[allow(unused_imports)] // Allowing unused imports

module dacade_deepbook::book {
    // Simplified and corrected imports
    use sui::tx_context::TxContext; 
    use sui::object::{ID, UID}; 
    use sui::coin::Coin;
    use sui::table::Table;
    use sui::transfer;
    use sui::sui::SUI;
    use sui::clock::Clock;
    use std::string::String;
    use std::vector;
    use std::option::{Option, none, some};

    // Error codes
    const INSUFFICIENT_BALANCE: u64 = 1;
    const INVALID_INDEX: u64 = 2;

    struct Transaction has store, copy, drop {
        transaction_type: String,
        amount: u64,
        to: Option<address>,
        from: Option<address>,
    }

    struct TokenizedGamingAsset has key, store {
        id: UID,
        create_date: u64,
        updated_date: u64,
        total_supply: Coin<SUI>,
        owner: address,
        transactions: vector<Transaction>,
        trading_enabled: bool, // New field to control trading
    }

    public fun create_asset(ctx: &mut TxContext, clock: &Clock) {
        let id = UID::new(ctx);
        let total_supply = Coin::<SUI>::zero();
        let owner = TxContext::sender(ctx);
        let create_date = Clock::now_ms(clock);
        let transactions = vector::empty<Transaction>();
        let asset = TokenizedGamingAsset {
            id,
            create_date,
            updated_date: create_date,
            total_supply,
            owner,
            transactions,
            trading_enabled: true, // Initialize trading as enabled
        };
        transfer::share_object(ctx, asset);
    }

    public fun mint_tokens(asset: &mut TokenizedGamingAsset, amount: u64, ctx: &mut TxContext) {
        assert!(asset.trading_enabled, "Trading is disabled.");
        asset.total_supply = Coin::mint(asset.total_supply, amount, ctx);
        let transaction = Transaction {
            transaction_type: "mint".to_string(),
            amount,
            to: some(asset.owner),
            from: none(),
        };
        vector::push_back(&mut asset.transactions, transaction);
        asset.updated_date = Clock::now_ms(ctx);
    }

    public fun burn_tokens(asset: &mut TokenizedGamingAsset, amount: u64, ctx: &mut TxContext) {
        assert!(asset.trading_enabled, "Trading is disabled.");
        asset.total_supply = Coin::burn(asset.total_supply, amount, ctx);
        let transaction = Transaction {
            transaction_type: "burn".to_string(),
            amount,
            to: none(),
            from: some(asset.owner),
        };
        vector::push_back(&mut asset.transactions, transaction);
        asset.updated_date = Clock::now_ms(ctx);
    }

    public fun transfer_tokens(asset: &mut TokenizedGamingAsset, recipient: address, amount: u64, ctx: &mut TxContext) {
        assert!(asset.trading_enabled, "Trading is disabled.");
        Coin::transfer(asset.total_supply, recipient, amount, ctx);
        let transaction = Transaction {
            transaction_type: "transfer".to_string(),
            amount,
            to: some(recipient),
            from: some(asset.owner),
        };
        vector::push_back(&mut asset.transactions, transaction);
        asset.updated_date = Clock::now_ms(ctx);
    }

    public fun toggle_trading(asset: &mut TokenizedGamingAsset) {
        asset.trading_enabled = !asset.trading_enabled; // Toggle trading state
        asset.updated_date = Clock::now_ms(ctx);
    }

    public fun is_trading_enabled(asset: &TokenizedGamingAsset): bool {
        asset.trading_enabled
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
