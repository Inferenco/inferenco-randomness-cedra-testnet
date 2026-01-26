import sys
import os
import time
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.random_provider import provider

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def main():
    clear_screen()
    print("\033[1;35m📦  INFERENCO RANDOMNESS: LOOT BOX DEMO  📦\033[0m")
    print("Opening a loot box with 3 random items...")
    print("Connecting to contract...\n")
    time.sleep(1)

    # Call simple provider method which mocks or calls contract
    try:
        # Requesting 3 items
        items = provider.open_loot_box(3)
    except Exception as e:
        print(f"Error fetching loot: {e}")
        return

    # Mock items if provider returns empty (likely due to no cli connection in this env)
    if not items:
        # This fallback mimics what the contract would return for visual demo
        import random
        print("\033[1;30m(Simulation Mode - Contract response empty/failed)\033[0m")
        for i in range(3):
            rarity = random.choices([0, 1, 2, 3, 4], weights=[50, 30, 15, 4, 1])[0]
            items.append({
                'item_id': random.randint(1000, 9999),
                'rarity': rarity,
                'power': random.randint(10, 100)
            })
            time.sleep(0.5)

    rarity_names = {
        0: ("COMMON", "\033[97m"),      # White
        1: ("UNCOMMON", "\033[92m"),    # Green
        2: ("RARE", "\033[94m"),        # Blue
        3: ("EPIC", "\033[95m"),        # Purple
        4: ("LEGENDARY", "\033[93m")    # Gold/Yellow
    }

    for item in items:
        r_name, color = rarity_names.get(item['rarity'], ("UNKNOWN", ""))
        reset = "\033[0m"
        
        print(f"{color}[{r_name}]{reset} Item #{item['item_id']}")
        print(f"  └── Power: {item['power']}")
        print("")
        time.sleep(0.8)

    print("\033[1;32mDone!\033[0m")

if __name__ == "__main__":
    main()
