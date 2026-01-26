import sys
import time
import os
import random
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.random_provider import provider

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def get_dice_art(number):
    """Returns list of strings for a dice face."""
    faces = {
        1: ["┌───────┐", "│       │", "│   ●   │", "│       │", "└───────┘"],
        2: ["┌───────┐", "│ ●     │", "│       │", "│     ● │", "└───────┘"],
        3: ["┌───────┐", "│ ●     │", "│   ●   │", "│     ● │", "└───────┘"],
        4: ["┌───────┐", "│ ●   ● │", "│       │", "│ ●   ● │", "└───────┘"],
        5: ["┌───────┐", "│ ●   ● │", "│   ●   │", "│ ●   ● │", "└───────┘"],
        6: ["┌───────┐", "│ ●   ● │", "│ ●   ● │", "│ ●   ● │", "└───────┘"]
    }
    return faces.get(number, faces[1])

def draw_two_dice(d1, d2):
    """Combines two dice side-by-side."""
    art1 = get_dice_art(d1)
    art2 = get_dice_art(d2)
    
    combined = []
    for line1, line2 in zip(art1, art2):
        combined.append(f"{line1}   {line2}")
    
    return "\n".join(combined)

def main():
    clear_screen()
    print("\033[1;36m🎲  INFERENCO RANDOMNESS: 2D6 DICE ROLL  🎲\033[0m")
    print("Rolling two dice on-chain...")
    time.sleep(1)

    # Animation
    print("\n") # Spacer
    lines_to_clear = 6 # 5 lines of art + 1 newline

    for _ in range(15):
        r1 = random.randint(1, 6)
        r2 = random.randint(1, 6)
        
        sys.stdout.write(draw_two_dice(r1, r2) + "\n")
        sys.stdout.flush()
        time.sleep(0.1)
        
        # Move cursor up and clear lines
        for _ in range(lines_to_clear):
            sys.stdout.write("\033[F") # Header of previous line
            sys.stdout.write("\033[K") # Clear line

    # Request Randomness
    # Optimization: Roll 1-36, split into two d6
    # 0..35 -> divmod(6) -> (0..5, 0..5) -> +1 -> (1..6, 1..6)
    try:
        raw_result = provider.dice_roll(36)
        
        # Map 1..36 to 0..35
        val_0_35 = raw_result - 1
        d1 = (val_0_35 // 6) + 1
        d2 = (val_0_35 % 6) + 1
        
    except Exception as e:
        print(f"\nError: {e}")
        d1, d2 = 1, 1

    # Final Draw
    sys.stdout.write(draw_two_dice(d1, d2) + "\n")
    print(f"\n\033[1;32mRESULT: {d1} + {d2} = {d1+d2}\033[0m")

if __name__ == "__main__":
    main()
