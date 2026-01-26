#[test_only]
module inferenco::game_tests {
    use std::signer;
    use cedra_framework::timestamp;
    use inferenco::game_examples;
    use inferenco::random;

    #[test(player = @0x123, framework = @0x1)]
    fun test_dice_game_flow(player: &signer, framework: &signer) {
        // Setup time
        timestamp::set_time_has_started_for_testing(framework);
        
        // Initialize
        game_examples::initialize_dice(player);
        
        // Play
        game_examples::roll_dice(player, 6);
        game_examples::roll_dice(player, 20);
    }

    #[test(player = @0x123, framework = @0x1)]
    fun test_card_game_flow(player: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        random::initialize(player); // Needed for random functions

        // Start game
        game_examples::start_card_game(player);
        
        // Hit a few times
        game_examples::hit_card(player);
        game_examples::hit_card(player);
    }

    #[test(player = @0x123, opponent = @0x456, framework = @0x1)]
    fun test_pvp_flow(player: &signer, opponent: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        random::initialize(player);

        let opponent_addr = signer::address_of(opponent);
        
        // Start combat
        game_examples::initiate_combat(player, opponent_addr, 100);
        
        // Attack
        game_examples::execute_attack(player, 10, 20, 10);
    }

    #[test(player = @0x123, framework = @0x1)]
    fun test_loot_box(player: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        random::initialize(player);

        game_examples::open_loot_box(player, 5);
    }

    #[test(player = @0x123, framework = @0x1)]
    fun test_dungeon_generation(player: &signer, framework: &signer) {
        timestamp::set_time_has_started_for_testing(framework);
        random::initialize(player);

        game_examples::generate_dungeon(player, 5); // Difficulty 5
    }

    #[test(player1 = @0x123, player2 = @0x456, admin = @inferenco, framework = @0x1)]
    fun test_matchmaking(player1: &signer, player2: &signer, admin: &signer, framework: &signer) {
         timestamp::set_time_has_started_for_testing(framework);
         random::initialize(admin);
         
         let admin_addr = signer::address_of(admin);

         // Helper to set up pool (since there's no explicit init function in example, 
         // but create_random_match checks for it, we might need to init it via create_random_match first 
         // OR check logic: create_random_match initializes if not exists.
         
         // In game_examples: 
         // create_random_match(admin) -> inits if not exists
         // join_matchmaking(player, pool_owner) -> returns if no pool
         
         // 1. Admin inits pool
         game_examples::create_random_match(admin);
         
         // 2. Players join
         game_examples::join_matchmaking(player1, admin_addr);
         game_examples::join_matchmaking(player2, admin_addr);
         
         // 3. Create match
         game_examples::create_random_match(admin);
    }
}
