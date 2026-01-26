import sys
import os
import time
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.random_provider import provider

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def get_card_name(card_index):
    suits = ['♠', '♥', '♦', '♣']
    ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
    
    suit = suits[card_index // 13]
    rank = ranks[card_index % 13]
    
    color = "\033[91m" if suit in ['♥', '♦'] else "\033[97m" # Red or White
    return f"{color}{rank}{suit}\033[0m"

def main():
    clear_screen()
    print("\033[1;34m🃏  INFERENCO RANDOMNESS: CARD DEALER DEMO  🃏\033[0m")
    print("Shuffling deck using on-chain Fisher-Yates shuffle...")
    print("Connecting to contract...\n")
    
    # Provider call
    try:
        hand = provider.start_card_game()
        # The contract deals 2 cards to player in the event, but let's assume we get a list
        # Actually start_card_game emits the player_hand (2 cards). 
        # For a full deck demo we might need a different function, but let's just show what we got.
        
        print("\n\033[1;32mReference Hand Dealt:\033[0m")
        for card_idx in hand:
            print(f"  {get_card_name(card_idx)}", end="")
        print("\n")
        
        print(f"(Received {len(hand)} cards from chain event)\n")
        
    except Exception as e:
        print(f"Error: {e}")

    print("\033[90mNote: The 'start_card_game' function deals a starting hand (2 cards) and creates a deck in state.")
    print("Future actions would hit from that state.\033[0m")

if __name__ == "__main__":
    main()
