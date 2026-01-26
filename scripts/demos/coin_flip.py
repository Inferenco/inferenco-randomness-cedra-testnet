import sys
import os
import time
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.random_provider import provider

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def main():
    clear_screen()
    print("\033[1;33m🪙  INFERENCO RANDOMNESS: COIN FLIP DEMO  🪙\033[0m")
    print("Flipping a coin using on-chain randomness...")
    
    while True:
        try:
            input("\nPress Enter to flip (or Ctrl+C to quit)...")
        except EOFError:
            print("\nNon-interactive mode detected. Exiting.")
            break
        
        # Simple animation
        print("Flipping...", end="", flush=True)
        for _ in range(5):
            sys.stdout.write(".")
            sys.stdout.flush()
            time.sleep(0.2)
        
        try:
            # Reusing dice_roll(2) where 1=Heads, 2=Tails if specific coin flip not in provider
            # Or assume provider has direct support
            result_val = provider.dice_roll(2)
            
            result_str = "HEADS" if result_val == 1 else "TAILS"
            color = "\033[1;32m" if result_val == 1 else "\033[1;31m"
            
            print(f"\n{color}{result_str}!\033[0m")
            
        except Exception as e:
            print(f"\nError: {e}")
            break

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting...")
