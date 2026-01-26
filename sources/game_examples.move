/// Example game implementations using the custom randomness module
module inferenco::game_examples {
    use std::signer;
    use std::vector;
    use std::string::{Self, String};
    use cedra_framework::event;
    use cedra_framework::timestamp;
    use inferenco::random;

    // ========================================================================
    // EXAMPLE 1: Dice Game
    // ========================================================================
    
    struct DiceGame has key {
        total_rolls: u64,
        last_roll: u64,
        last_roll_time: u64,
    }

    #[event]
    struct DiceRolled has drop, store {
        player: address,
        roll: u64,
        timestamp: u64,
    }

    public entry fun initialize_dice(account: &signer) {
        random::initialize(account);
        
        move_to(account, DiceGame {
            total_rolls: 0,
            last_roll: 0,
            last_roll_time: 0,
        });
    }

    public entry fun roll_dice(player: &signer, sides: u64) acquires DiceGame {
        let player_addr = signer::address_of(player);
        
        // Roll the dice
        let result = random::dice_roll(player_addr, sides);
        
        // Update state
        let game = borrow_global_mut<DiceGame>(player_addr);
        game.total_rolls = game.total_rolls + 1;
        game.last_roll = result;
        game.last_roll_time = timestamp::now_microseconds();
        
        // Emit event
        event::emit(DiceRolled {
            player: player_addr,
            roll: result,
            timestamp: timestamp::now_microseconds(),
        });
    }

    // ========================================================================
    // EXAMPLE 2: Card Game (Poker/Blackjack)
    // ========================================================================

    const DECK_SIZE: u64 = 52;
    
    struct CardGame has key {
        deck: vector<u64>,
        player_hand: vector<u64>,
        dealer_hand: vector<u64>,
        game_active: bool,
    }

    #[event]
    struct GameStarted has drop, store {
        player: address,
        player_cards: vector<u64>,
        dealer_up_card: u64,
    }

    #[event]
    struct CardDealt has drop, store {
        player: address,
        card: u64,
        hand_total: u64,
    }

    public entry fun start_card_game(player: &signer) acquires CardGame {
        let player_addr = signer::address_of(player);
        
        if (!exists<CardGame>(player_addr)) {
            move_to(player, CardGame {
                deck: vector::empty(),
                player_hand: vector::empty(),
                dealer_hand: vector::empty(),
                game_active: false,
            });
        };
        
        let game = borrow_global_mut<CardGame>(player_addr);
        
        // Shuffle deck using permutation
        game.deck = random::permutation(player_addr, DECK_SIZE);
        game.player_hand = vector::empty();
        game.dealer_hand = vector::empty();
        game.game_active = true;
        
        // Deal initial cards
        let player_card1 = vector::pop_back(&mut game.deck);
        let dealer_card1 = vector::pop_back(&mut game.deck);
        let player_card2 = vector::pop_back(&mut game.deck);
        let dealer_card2 = vector::pop_back(&mut game.deck);
        
        vector::push_back(&mut game.player_hand, player_card1);
        vector::push_back(&mut game.player_hand, player_card2);
        vector::push_back(&mut game.dealer_hand, dealer_card1);
        vector::push_back(&mut game.dealer_hand, dealer_card2);
        
        event::emit(GameStarted {
            player: player_addr,
            player_cards: *&game.player_hand,
            dealer_up_card: dealer_card1,
        });
    }

    public entry fun hit_card(player: &signer) acquires CardGame {
        let player_addr = signer::address_of(player);
        let game = borrow_global_mut<CardGame>(player_addr);
        
        assert!(game.game_active, 0);
        
        let card = vector::pop_back(&mut game.deck);
        vector::push_back(&mut game.player_hand, card);
        
        event::emit(CardDealt {
            player: player_addr,
            card,
            hand_total: vector::length(&game.player_hand),
        });
    }

    // ========================================================================
    // EXAMPLE 3: PvP Combat with Random Damage
    // ========================================================================

    struct CombatState has key {
        opponent: address,
        my_hp: u64,
        opponent_hp: u64,
        my_turn: bool,
        combat_active: bool,
    }

    #[event]
    struct AttackExecuted has drop, store {
        attacker: address,
        defender: address,
        damage: u64,
        was_critical: bool,
        defender_hp_remaining: u64,
    }

    #[event]
    struct CombatEnded has drop, store {
        winner: address,
        loser: address,
    }

    public entry fun initiate_combat(
        player: &signer,
        opponent: address,
        starting_hp: u64
    ) {
        move_to(player, CombatState {
            opponent,
            my_hp: starting_hp,
            opponent_hp: starting_hp,
            my_turn: true,
            combat_active: true,
        });
    }

    public entry fun execute_attack(
        player: &signer,
        min_damage: u64,
        max_damage: u64,
        crit_chance: u8
    ) acquires CombatState {
        let player_addr = signer::address_of(player);
        let state = borrow_global_mut<CombatState>(player_addr);
        
        assert!(state.combat_active, 0);
        assert!(state.my_turn, 1);
        
        // Roll damage
        let base_damage = random::u64_range(player_addr, min_damage, max_damage + 1);
        
        // Check for critical hit
        let is_crit = random::critical_hit(player_addr, crit_chance);
        let final_damage = if (is_crit) {
            base_damage * 2
        } else {
            base_damage
        };
        
        // Apply damage
        state.opponent_hp = if (state.opponent_hp > final_damage) {
            state.opponent_hp - final_damage
        } else {
            0
        };
        
        event::emit(AttackExecuted {
            attacker: player_addr,
            defender: state.opponent,
            damage: final_damage,
            was_critical: is_crit,
            defender_hp_remaining: state.opponent_hp,
        });
        
        // Check for combat end
        if (state.opponent_hp == 0) {
            state.combat_active = false;
            event::emit(CombatEnded {
                winner: player_addr,
                loser: state.opponent,
            });
        } else {
            state.my_turn = false;
        };
    }

    // ========================================================================
    // EXAMPLE 4: Loot Box / Gacha System
    // ========================================================================

    const RARITY_COMMON: u8 = 0;
    const RARITY_UNCOMMON: u8 = 1;
    const RARITY_RARE: u8 = 2;
    const RARITY_EPIC: u8 = 3;
    const RARITY_LEGENDARY: u8 = 4;

    struct LootDrop has drop, store {
        item_id: u64,
        rarity: u8,
        power: u64,
    }

    #[event]
    struct LootBoxOpened has drop, store {
        player: address,
        items: vector<LootDrop>,
    }

    public entry fun open_loot_box(player: &signer, num_items: u64) {
        let player_addr = signer::address_of(player);
        let items = vector::empty<LootDrop>();
        
        let i = 0;
        while (i < num_items) {
            let item = generate_random_item(player_addr);
            vector::push_back(&mut items, item);
            i = i + 1;
        };
        
        event::emit(LootBoxOpened {
            player: player_addr,
            items,
        });
    }

    fun generate_random_item(player_addr: address): LootDrop {
        // Weighted rarity chances
        let weights = vector::empty<u64>();
        vector::push_back(&mut weights, 50); // 50% Common
        vector::push_back(&mut weights, 30); // 30% Uncommon
        vector::push_back(&mut weights, 15); // 15% Rare
        vector::push_back(&mut weights, 4);  // 4% Epic
        vector::push_back(&mut weights, 1);  // 1% Legendary
        
        let rarity_idx = random::weighted_choice(player_addr, &weights);
        let rarity = (rarity_idx as u8);
        
        // Generate item ID
        let item_id = random::u64_range(player_addr, 1, 1000);
        
        // Power based on rarity
        let (min_power, max_power) = if (rarity == RARITY_COMMON) {
            (10, 20)
        } else if (rarity == RARITY_UNCOMMON) {
            (20, 40)
        } else if (rarity == RARITY_RARE) {
            (40, 70)
        } else if (rarity == RARITY_EPIC) {
            (70, 100)
        } else {
            (100, 150)
        };
        
        let power = random::u64_range(player_addr, min_power, max_power + 1);
        
        LootDrop {
            item_id,
            rarity,
            power,
        }
    }

    // ========================================================================
    // EXAMPLE 5: Random Event System
    // ========================================================================

    const EVENT_RESOURCE_BONUS: u8 = 0;
    const EVENT_ENEMY_ATTACK: u8 = 1;
    const EVENT_WEATHER_CHANGE: u8 = 2;
    const EVENT_MARKET_FLUCTUATION: u8 = 3;
    const EVENT_RARE_ENCOUNTER: u8 = 4;

    #[event]
    struct RandomEventTriggered has drop, store {
        player: address,
        event_type: u8,
        event_value: u64,
        description: String,
    }

    public entry fun trigger_random_event(player: &signer) {
        let player_addr = signer::address_of(player);
        
        // Roll for event type (weighted)
        let weights = vector::empty<u64>();
        vector::push_back(&mut weights, 30); // Resource bonus
        vector::push_back(&mut weights, 20); // Enemy attack
        vector::push_back(&mut weights, 20); // Weather
        vector::push_back(&mut weights, 20); // Market
        vector::push_back(&mut weights, 10); // Rare event
        
        let event_idx = random::weighted_choice(player_addr, &weights);
        let event_type = (event_idx as u8);
        
        // Generate event value based on type
        let event_value = random::u64_range(player_addr, 1, 100);
        
        let description = if (event_type == EVENT_RESOURCE_BONUS) {
            string::utf8(b"You found extra resources!")
        } else if (event_type == EVENT_ENEMY_ATTACK) {
            string::utf8(b"Enemy forces approach!")
        } else if (event_type == EVENT_WEATHER_CHANGE) {
            string::utf8(b"The weather shifts...")
        } else if (event_type == EVENT_MARKET_FLUCTUATION) {
            string::utf8(b"Market prices fluctuate!")
        } else {
            string::utf8(b"A rare encounter occurs!")
        };
        
        event::emit(RandomEventTriggered {
            player: player_addr,
            event_type,
            event_value,
            description,
        });
    }

    // ========================================================================
    // EXAMPLE 6: Tournament Matchmaking
    // ========================================================================

    struct MatchmakingPool has key {
        waiting_players: vector<address>,
    }

    #[event]
    struct MatchCreated has drop, store {
        player1: address,
        player2: address,
        match_id: u64,
    }

    public entry fun join_matchmaking(player: &signer, pool_owner: address) acquires MatchmakingPool {
        let player_addr = signer::address_of(player);
        
        if (!exists<MatchmakingPool>(pool_owner)) {
            // This should be called by pool owner initially
            return
        };
        
        let pool = borrow_global_mut<MatchmakingPool>(pool_owner);
        vector::push_back(&mut pool.waiting_players, player_addr);
    }

    public entry fun create_random_match(admin: &signer) acquires MatchmakingPool {
        let admin_addr = signer::address_of(admin);
        
        if (!exists<MatchmakingPool>(admin_addr)) {
            move_to(admin, MatchmakingPool {
                waiting_players: vector::empty(),
            });
            return
        };
        
        let pool = borrow_global_mut<MatchmakingPool>(admin_addr);
        let num_waiting = vector::length(&pool.waiting_players);
        
        if (num_waiting < 2) {
            return
        };
        
        // Randomly select 2 players
        let p1_idx = random::u64_range(admin_addr, 0, num_waiting);
        let player1 = vector::swap_remove(&mut pool.waiting_players, p1_idx);
        
        let num_remaining = vector::length(&pool.waiting_players);
        let p2_idx = random::u64_range(admin_addr, 0, num_remaining);
        let player2 = vector::swap_remove(&mut pool.waiting_players, p2_idx);
        
        let match_id = random::u64_integer(admin_addr);
        
        event::emit(MatchCreated {
            player1,
            player2,
            match_id,
        });
    }

    // ========================================================================
    // EXAMPLE 7: Procedural Dungeon Generation
    // ========================================================================

    struct DungeonRoom has drop, store {
        room_type: u8,
        enemy_count: u64,
        has_treasure: bool,
        treasure_quality: u8,
    }

    struct Dungeon has key {
        rooms: vector<DungeonRoom>,
        current_room: u64,
    }

    #[event]
    struct DungeonGenerated has drop, store {
        player: address,
        num_rooms: u64,
        difficulty: u8,
    }

    public entry fun generate_dungeon(
        player: &signer,
        difficulty: u8
    ) {
        let player_addr = signer::address_of(player);
        
        // Number of rooms based on difficulty
        let num_rooms = random::u64_range(player_addr, 5, 11);
        
        let rooms = vector::empty<DungeonRoom>();
        let i = 0;
        
        while (i < num_rooms) {
            let room = generate_random_room(player_addr, difficulty);
            vector::push_back(&mut rooms, room);
            i = i + 1;
        };
        
        move_to(player, Dungeon {
            rooms,
            current_room: 0,
        });
        
        event::emit(DungeonGenerated {
            player: player_addr,
            num_rooms,
            difficulty,
        });
    }

    fun generate_random_room(player_addr: address, difficulty: u8): DungeonRoom {
        let room_type = (random::u64_range(player_addr, 0, 4) as u8);
        
        // Enemy count scales with difficulty
        let max_enemies = (difficulty as u64) + 3;
        let enemy_count = random::u64_range(player_addr, 0, max_enemies + 1);
        
        // Treasure chance increases with difficulty
        let treasure_chance = 20 + (difficulty as u8) * 5;
        let has_treasure = random::boolean(player_addr, treasure_chance);
        
        let treasure_quality = if (has_treasure) {
            (random::u64_range(player_addr, 1, 6) as u8)
        } else {
            0
        };
        
        DungeonRoom {
            room_type,
            enemy_count,
            has_treasure,
            treasure_quality,
        }
    }

    // ========================================================================
    // EXAMPLE 8: Procedural Map Generation (2D Grid)
    // ========================================================================

    const TERRAIN_WATER: u8 = 0;
    const TERRAIN_LAND: u8 = 1;
    const TERRAIN_MOUNTAIN: u8 = 2;
    const TERRAIN_FOREST: u8 = 3;

    struct MapGrid has key {
        width: u64,
        height: u64,
        grid: vector<vector<u8>>,
    }

    #[event]
    struct MapGenerated has drop, store {
        player: address,
        width: u64,
        height: u64,
    }

    public entry fun generate_map(player: &signer, width: u64, height: u64) acquires MapGrid {
        let player_addr = signer::address_of(player);
        let grid = vector::empty<vector<u8>>();
        
        let y = 0;
        while (y < height) {
            let row = vector::empty<u8>();
            let x = 0;
            while (x < width) {
                // Simple weighted terrain generation
                // Water: 30%, Land: 40%, Forest: 20%, Mountain: 10%
                let weights = vector::empty<u64>();
                vector::push_back(&mut weights, 30);
                vector::push_back(&mut weights, 40);
                vector::push_back(&mut weights, 10);
                vector::push_back(&mut weights, 20);

                // Note: Index mapping must match constants
                // 0->Water, 1->Land, 2->Mountain, 3->Forest
                // We pushed weights in order: Water, Land, Mountain, Forest
                
                let terrain_idx = random::weighted_choice(player_addr, &weights);
                vector::push_back(&mut row, (terrain_idx as u8));
                
                x = x + 1;
            };
            vector::push_back(&mut grid, row);
            y = y + 1;
        };
        
        if (exists<MapGrid>(player_addr)) {
            let map = borrow_global_mut<MapGrid>(player_addr);
            map.width = width;
            map.height = height;
            map.grid = grid;
        } else {
            move_to(player, MapGrid {
                width,
                height,
                grid,
            });
        };

        event::emit(MapGenerated {
            player: player_addr,
            width,
            height,
        });
    }

    // ========================================================================
    // EXAMPLE 9: Lottery System
    // ========================================================================

    struct Lottery has key {
        tickets: vector<address>,
        is_active: bool,
        ticket_price: u64,
    }

    #[event]
    struct LotteryWinner has drop, store {
        winner: address,
        prize_pool: u64,
        total_participants: u64,
    }

    public entry fun init_lottery(admin: &signer, ticket_price: u64) {
        let admin_addr = signer::address_of(admin);
        if (!exists<Lottery>(admin_addr)) {
            move_to(admin, Lottery {
                tickets: vector::empty(),
                is_active: true,
                ticket_price,
            });
        };
    }

    public entry fun buy_ticket(player: &signer, lottery_owner: address) acquires Lottery {
        let player_addr = signer::address_of(player);
        assert!(exists<Lottery>(lottery_owner), 0);
        
        let lottery = borrow_global_mut<Lottery>(lottery_owner);
        assert!(lottery.is_active, 1);
        
        // In a real app, we would charge coins here
        vector::push_back(&mut lottery.tickets, player_addr);
    }

    public entry fun draw_winner(admin: &signer) acquires Lottery {
        let admin_addr = signer::address_of(admin);
        let lottery = borrow_global_mut<Lottery>(admin_addr);
        
        assert!(lottery.is_active, 1);
        let num_tickets = vector::length(&lottery.tickets);
        
        if (num_tickets == 0) {
            lottery.is_active = false;
            return
        };
        
        // Select random index
        let winner_idx = random::u64_range(admin_addr, 0, num_tickets);
        let winner = *vector::borrow(&lottery.tickets, winner_idx);
        
        // Calculate prize (mock)
        let prize = num_tickets * lottery.ticket_price;
        
        event::emit(LotteryWinner {
            winner,
            prize_pool: prize,
            total_participants: num_tickets,
        });
        
        // Reset for next round
        lottery.tickets = vector::empty();
        lottery.is_active = true; // or false to end
    }
}
