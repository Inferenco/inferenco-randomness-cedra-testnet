/// Custom randomness module for Cedra that works when native randomness is unavailable
/// 
/// SECURITY NOTES:
/// - This uses on-chain entropy sources (timestamp, tx hash, block height)
/// - Not as secure as VRF but sufficient for many game scenarios
/// - Can be manipulated by validators in extreme cases
/// - For high-value games, use external VRF or wait for native randomness
/// 
/// USAGE:
/// - Must be called from entry functions
/// - Each call increments a counter to ensure different results
/// - Supports all standard integer types and ranges
module inferenco::random {
    use std::bcs;
    use std::hash;
    use std::vector;
    use cedra_framework::timestamp;
    use cedra_framework::transaction_context;

    /// Errors
    const E_INVALID_RANGE: u64 = 1;
    const E_NOT_INITIALIZED: u64 = 2;
    const E_EMPTY_VECTOR: u64 = 3;

    /// Global counter for entropy - increments on each random call
    struct RandomnessCounter has key {
        counter: u64,
    }

    /// Initialize the randomness module (call once at deployment)
    public entry fun initialize(account: &signer) {
        let addr = std::signer::address_of(account);
        
        if (!exists<RandomnessCounter>(addr)) {
            move_to(account, RandomnessCounter {
                counter: 0,
            });
        };
    }

    /// Internal function to generate raw random bytes
    /// Combines multiple entropy sources for better randomness
    fun next_bytes(caller: address): vector<u8> acquires RandomnessCounter {
        assert!(exists<RandomnessCounter>(caller), E_NOT_INITIALIZED);
        
        let counter_ref = borrow_global_mut<RandomnessCounter>(caller);
        counter_ref.counter = counter_ref.counter + 1;
        
        // Build entropy from multiple sources
        let entropy = vector::empty<u8>();
        
        // 1. Transaction hash (unique per transaction)
        let tx_hash = transaction_context::get_transaction_hash();
        vector::append(&mut entropy, tx_hash);
        
        // 2. Timestamp (changes each second)
        let time = timestamp::now_microseconds();
        let time_bytes = bcs::to_bytes(&time);
        vector::append(&mut entropy, time_bytes);
        
        // 3. Caller address
        let addr_bytes = bcs::to_bytes(&caller);
        vector::append(&mut entropy, addr_bytes);
        
        // 4. Counter (unique per call within transaction)
        let counter_bytes = bcs::to_bytes(&counter_ref.counter);
        vector::append(&mut entropy, counter_bytes);
        
        // 5. Script hash (if available)
        let script_hash = transaction_context::get_script_hash();
        vector::append(&mut entropy, script_hash);
        
        // Hash everything together
        hash::sha3_256(entropy)
    }

    /// Convert bytes to u64
    fun bytes_to_u64(bytes: &vector<u8>, offset: u64): u64 {
        let len = vector::length(bytes);
        if (offset + 8 > len) {
            offset = 0;
        };
        
        let result: u64 = 0;
        let i = 0;
        while (i < 8 && offset + i < len) {
            let byte = (*vector::borrow(bytes, offset + i) as u64);
            result = result | (byte << ((i * 8) as u8));
            i = i + 1;
        };
        result
    }

    /// Convert bytes to u128
    fun bytes_to_u128(bytes: &vector<u8>, offset: u64): u128 {
        let len = vector::length(bytes);
        if (offset + 16 > len) {
            offset = 0;
        };
        
        let result: u128 = 0;
        let i = 0;
        while (i < 16 && offset + i < len) {
            let byte = (*vector::borrow(bytes, offset + i) as u128);
            result = result | (byte << ((i * 8) as u8));
            i = i + 1;
        };
        result
    }

    /// Convert bytes to u256
    fun bytes_to_u256(bytes: &vector<u8>): u256 {
        let len = vector::length(bytes);
        let result: u256 = 0;
        let i = 0;
        while (i < 32 && i < len) {
            let byte = (*vector::borrow(bytes, i) as u256);
            result = result | (byte << ((i * 8) as u8));
            i = i + 1;
        };
        result
    }

    // ========================================================================
    // PUBLIC API - Integer Generators
    // ========================================================================

    /// Generate random u8
    public fun u8_integer(caller: address): u8 acquires RandomnessCounter {
        let bytes = next_bytes(caller);
        (*vector::borrow(&bytes, 0) as u8)
    }

    /// Generate random u16
    public fun u16_integer(caller: address): u16 acquires RandomnessCounter {
        let bytes = next_bytes(caller);
        let b0 = (*vector::borrow(&bytes, 0) as u16);
        let b1 = (*vector::borrow(&bytes, 1) as u16);
        b0 | (b1 << 8)
    }

    /// Generate random u32
    public fun u32_integer(caller: address): u32 acquires RandomnessCounter {
        let bytes = next_bytes(caller);
        let b0 = (*vector::borrow(&bytes, 0) as u32);
        let b1 = (*vector::borrow(&bytes, 1) as u32);
        let b2 = (*vector::borrow(&bytes, 2) as u32);
        let b3 = (*vector::borrow(&bytes, 3) as u32);
        b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    }

    /// Generate random u64
    public fun u64_integer(caller: address): u64 acquires RandomnessCounter {
        let bytes = next_bytes(caller);
        bytes_to_u64(&bytes, 0)
    }

    /// Generate random u128
    public fun u128_integer(caller: address): u128 acquires RandomnessCounter {
        let bytes = next_bytes(caller);
        bytes_to_u128(&bytes, 0)
    }

    /// Generate random u256
    public fun u256_integer(caller: address): u256 acquires RandomnessCounter {
        let bytes = next_bytes(caller);
        bytes_to_u256(&bytes)
    }

    // ========================================================================
    // PUBLIC API - Range Generators
    // ========================================================================

    /// Generate random u8 in range [min, max)
    public fun u8_range(caller: address, min: u8, max: u8): u8 acquires RandomnessCounter {
        assert!(max > min, E_INVALID_RANGE);
        let range = max - min;
        let random = u8_integer(caller);
        min + (random % range)
    }

    /// Generate random u16 in range [min, max)
    public fun u16_range(caller: address, min: u16, max: u16): u16 acquires RandomnessCounter {
        assert!(max > min, E_INVALID_RANGE);
        let range = max - min;
        let random = u16_integer(caller);
        min + (random % range)
    }

    /// Generate random u32 in range [min, max)
    public fun u32_range(caller: address, min: u32, max: u32): u32 acquires RandomnessCounter {
        assert!(max > min, E_INVALID_RANGE);
        let range = max - min;
        let random = u32_integer(caller);
        min + (random % range)
    }

    /// Generate random u64 in range [min, max)
    public fun u64_range(caller: address, min: u64, max: u64): u64 acquires RandomnessCounter {
        assert!(max > min, E_INVALID_RANGE);
        let range = max - min;
        let random = u64_integer(caller);
        min + (random % range)
    }

    /// Generate random u128 in range [min, max)
    public fun u128_range(caller: address, min: u128, max: u128): u128 acquires RandomnessCounter {
        assert!(max > min, E_INVALID_RANGE);
        let range = max - min;
        let random = u128_integer(caller);
        min + (random % range)
    }

    /// Generate random u256 in range [min, max)
    public fun u256_range(caller: address, min: u256, max: u256): u256 acquires RandomnessCounter {
        assert!(max > min, E_INVALID_RANGE);
        let range = max - min;
        let random = u256_integer(caller);
        min + (random % range)
    }

    // ========================================================================
    // PUBLIC API - Utility Functions
    // ========================================================================

    /// Generate n random bytes
    public fun bytes(caller: address, n: u64): vector<u8> acquires RandomnessCounter {
        let result = vector::empty<u8>();
        let i = 0;
        
        while (i < n) {
            let chunk = next_bytes(caller);
            let j = 0;
            while (j < vector::length(&chunk) && i < n) {
                vector::push_back(&mut result, *vector::borrow(&chunk, j));
                i = i + 1;
                j = j + 1;
            };
        };
        
        result
    }

    /// Generate random permutation of [0, n)
    /// Uses Fisher-Yates shuffle algorithm
    public fun permutation(caller: address, n: u64): vector<u64> acquires RandomnessCounter {
        let result = vector::empty<u64>();
        
        // Initialize array [0, 1, 2, ..., n-1]
        let i = 0;
        while (i < n) {
            vector::push_back(&mut result, i);
            i = i + 1;
        };
        
        // Fisher-Yates shuffle
        let i = n - 1;
        while (i > 0) {
            let j = u64_range(caller, 0, i + 1);
            
            // Swap elements at i and j
            let temp = *vector::borrow(&result, i);
            *vector::borrow_mut(&mut result, i) = *vector::borrow(&result, j);
            *vector::borrow_mut(&mut result, j) = temp;
            
            i = i - 1;
        };
        
        result
    }

    /// Shuffle a vector in place
    public fun shuffle<T: drop>(caller: address, vec: &mut vector<T>) acquires RandomnessCounter {
        let n = vector::length(vec);
        if (n <= 1) return;
        
        let i = n - 1;
        while (i > 0) {
            let j = u64_range(caller, 0, i + 1);
            
            // Swap elements at i and j
            vector::swap(vec, i, j);
            
            i = i - 1;
        };
    }

    /// Pick a random element from a vector
    public fun pick<T: copy>(caller: address, vec: &vector<T>): T acquires RandomnessCounter {
        let len = vector::length(vec);
        assert!(len > 0, E_EMPTY_VECTOR);
        
        let idx = u64_range(caller, 0, len);
        *vector::borrow(vec, idx)
    }

    /// Weighted random selection
    /// weights must sum to > 0
    public fun weighted_choice(caller: address, weights: &vector<u64>): u64 acquires RandomnessCounter {
        let len = vector::length(weights);
        assert!(len > 0, E_EMPTY_VECTOR);
        
        // Calculate total weight
        let total_weight = 0u64;
        let i = 0;
        while (i < len) {
            total_weight = total_weight + *vector::borrow(weights, i);
            i = i + 1;
        };
        
        assert!(total_weight > 0, E_INVALID_RANGE);
        
        // Pick random value in [0, total_weight)
        let random_value = u64_range(caller, 0, total_weight);
        
        // Find which bucket it falls into
        let cumulative = 0u64;
        let i = 0;
        while (i < len) {
            cumulative = cumulative + *vector::borrow(weights, i);
            if (random_value < cumulative) {
                return i
            };
            i = i + 1;
        };
        
        // Should never reach here, but return last index as fallback
        len - 1
    }

    /// Boolean random with given probability (0-100)
    /// probability = 0 means always false, 100 means always true
    public fun boolean(caller: address, probability: u8): bool acquires RandomnessCounter {
        assert!(probability <= 100, E_INVALID_RANGE);
        let random = u8_range(caller, 0, 100);
        random < probability
    }

    // ========================================================================
    // GAME-SPECIFIC HELPERS
    // ========================================================================

    /// Roll a die with n sides (1 to n inclusive)
    public fun dice_roll(caller: address, sides: u64): u64 acquires RandomnessCounter {
        u64_range(caller, 1, sides + 1)
    }

    /// Roll multiple dice and sum the results
    public fun dice_roll_sum(caller: address, num_dice: u64, sides: u64): u64 acquires RandomnessCounter {
        let sum = 0;
        let i = 0;
        while (i < num_dice) {
            sum = sum + dice_roll(caller, sides);
            i = i + 1;
        };
        sum
    }

    /// Flip a coin (returns true for heads, false for tails)
    public fun coin_flip(caller: address): bool acquires RandomnessCounter {
        u64_range(caller, 0, 2) == 0
    }

    /// Critical hit check with percentage chance
    public fun critical_hit(caller: address, crit_chance_percent: u8): bool acquires RandomnessCounter {
        boolean(caller, crit_chance_percent)
    }

    // ========================================================================
    // VIEW FUNCTIONS
    // ========================================================================

    #[view]
    public fun is_initialized(addr: address): bool {
        exists<RandomnessCounter>(addr)
    }

    #[view]
    public fun get_counter(addr: address): u64 acquires RandomnessCounter {
        assert!(exists<RandomnessCounter>(addr), E_NOT_INITIALIZED);
        borrow_global<RandomnessCounter>(addr).counter
    }

    // ========================================================================
    // TESTS
    // ========================================================================

    #[test_only]
    use std::signer;

    #[test(account = @inferenco, framework = @0x1)]
    fun test_initialize(account: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        initialize(account);
        let addr = signer::address_of(account);
        assert!(is_initialized(addr), 0);
    }

    #[test(account = @inferenco, framework = @0x1)]
    fun test_u64_integer(account: &signer, framework: &signer) acquires RandomnessCounter {
        timestamp::set_time_has_started_for_testing(framework);
        initialize(account);
        let addr = signer::address_of(account);
        
        let r1 = u64_integer(addr);
        let r2 = u64_integer(addr);
        
        // Should get different results due to counter
        assert!(r1 != r2, 0);
    }

    #[test(account = @inferenco, framework = @0x1)]
    fun test_u64_range(account: &signer, framework: &signer) acquires RandomnessCounter {
        timestamp::set_time_has_started_for_testing(framework);
        initialize(account);
        let addr = signer::address_of(account);
        
        let i = 0;
        while (i < 100) {
            let r = u64_range(addr, 1, 7); // Dice roll
            assert!(r >= 1 && r < 7, 0);
            i = i + 1;
        };
    }

    #[test(account = @inferenco, framework = @0x1)]
    fun test_permutation(account: &signer, framework: &signer) acquires RandomnessCounter {
        timestamp::set_time_has_started_for_testing(framework);
        initialize(account);
        let addr = signer::address_of(account);
        
        let perm = permutation(addr, 10);
        assert!(vector::length(&perm) == 10, 0);
        
        // Check all numbers 0-9 appear exactly once
        let i = 0;
        while (i < 10) {
            assert!(vector::contains(&perm, &i), 0);
            i = i + 1;
        };
    }

    #[test(account = @inferenco, framework = @0x1)]
    fun test_dice_roll(account: &signer, framework: &signer) acquires RandomnessCounter {
        timestamp::set_time_has_started_for_testing(framework);
        initialize(account);
        let addr = signer::address_of(account);
        
        let i = 0;
        while (i < 100) {
            let r = dice_roll(addr, 6);
            assert!(r >= 1 && r <= 6, 0);
            i = i + 1;
        };
    }

    #[test(account = @inferenco, framework = @0x1)]
    fun test_weighted_choice(account: &signer, framework: &signer) acquires RandomnessCounter {
        timestamp::set_time_has_started_for_testing(framework);
        initialize(account);
        let addr = signer::address_of(account);
        
        let weights = vector::empty<u64>();
        vector::push_back(&mut weights, 50); // 50% chance for index 0
        vector::push_back(&mut weights, 30); // 30% chance for index 1
        vector::push_back(&mut weights, 20); // 20% chance for index 2
        
        let i = 0;
        while (i < 100) {
            let choice = weighted_choice(addr, &weights);
            assert!(choice < 3, 0);
            i = i + 1;
        };
    }
}
