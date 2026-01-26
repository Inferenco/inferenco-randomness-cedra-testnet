import sys
import os
import time
import random 
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from shared.random_provider import provider

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def main():
    clear_screen()
    print("\033[1;31m⚔️  INFERENCO RANDOMNESS: COMBAT DEMO  ⚔️\033[0m")
    
    player_hp = 100
    enemy_hp = 100
    
    print(f"You encounter a Wild Hog! HP: {enemy_hp}")
    
    while player_hp > 0 and enemy_hp > 0:
        print(f"\nYour HP: {player_hp} | Enemy HP: {enemy_hp}")
        try:
            action = input("[A]ttack or [R]un? ").strip().upper()
        except EOFError:
            print("\nNon-interactive mode. Exiting combat.")
            break
        
        if action == 'R':
            print("You ran away!")
            return
            
        if action == 'A':
            # Simulate attack using provider (which would call contract)
            print("Attacking...")
            time.sleep(0.5)
            
            # Using dice roll to simulate damage calculation if full combat function isn't ready
            # In a real scenario we'd call provider.execute_attack(...)
            # Here we demonstrate composability
            
            try:
                # Use provider to calculate damage (simulated or real)
                damage, is_crit = provider.execute_attack(1, 20, 10) # 1-20 dmg, 10% crit
                
                msg = f"You hit for {damage} damage!"
                if is_crit:
                    msg += " \033[1;33mCRITICAL HIT!\033[0m"
                
                print(msg)
                enemy_hp -= damage
                
            except Exception as e:
                print(f"Error calling randomness: {e}")
                break
                
            if enemy_hp <= 0:
                print("\n\033[1;32mVICTORY! The Wild Hog is defeated.\033[0m")
                break
                
            # Enemy turn (local random for speed)
            print("Enemy attacks!")
            player_hp -= random.randint(5, 15)
            time.sleep(0.5)
            
    if player_hp <= 0:
        print("\n\033[1;31mDEFEAT! You have fallen.\033[0m")

if __name__ == "__main__":
    main()
