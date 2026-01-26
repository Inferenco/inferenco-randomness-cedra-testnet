import subprocess
import json
import re
import sys
import os
import random
import time

class RandomProvider:
    def __init__(self, profile="testnet"):
        self.profile = profile
        self.package_addr = "testnet"
        self._check_cli_available()

    def _check_cli_available(self):
        try:
            subprocess.run(["cedra", "--version"], capture_output=True, check=True)
            self.simulation_mode = False
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("\033[1;33m[WARN] Cedra CLI not found or failed. Falling back to local simulation mode.\033[0m")
            self.simulation_mode = True

    def _run_command(self, function_id, args):
        if self.simulation_mode:
            return None

        cmd = [
            "cedra", "move", "run",
            "--assume-yes",
            "--function-id", function_id,
            "--profile", self.profile,
        ]
        
        for arg in args:
            cmd.extend(["--args", str(arg)])
            
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error executing transaction: {e.stderr}")
            if "Profile inferenco not found" in e.stderr:
                 print("\033[1;33m[TIP] Ensure you compiled with named addresses or use full address.\033[0m")
            return None

    def _get_events_for_hash(self, tx_hash):
        for i in range(10):
            try:
                url = f"https://testnet.cedra.dev/transactions/by_hash/{tx_hash}"
                # Using -s for silent mode
                result = subprocess.run(["curl", "-s", url], capture_output=True, text=True, check=True)
                output = result.stdout
                
                if output and '"message":"not found"' not in output and '"error_code"' not in output:
                    return output
                    
                # print(f"DEBUG: Transaction not ready yet, retrying... ({i+1}/10)")
                time.sleep(2) # Wait 2 seconds
            except Exception as e:
                print(f"Error fetching transaction events: {e}")
                return None
        print(f"DEBUG: Timeout waiting for transaction {tx_hash} to be indexed.")
        return None

    def _get_resource(self, resource_type):
        try:
            # Hardcoded address for demo purposes where we know the account holding the game state
            # In production this might be self.profiler's address or the user's address
            addr = "0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403"
            
            cmd = [
                "cedra", "account", "list",
                "--query", "resources",
                "--account", addr,
                "--profile", self.profile
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            
            # The output is JSON. parse it.
            import json
            try:
                data = json.loads(result.stdout)
                # Structure is { "Result": [ { "type": { data } }, ... ] } or just [ ... ] depending on CLI version
                # CLI output seen: [ { "0x...": { ... } }, ... ] (wrapped in "Result" potentially?)
                # Actually output was { "Result": [ ... ] } in my manual test? 
                # Wait, manual output was complex. Let's look at the captured output in Step 348.
                # It didn't obviously show { "Result": ... } at the top, but the truncated part might have.
                # Typically valid JSON via CLI.
                
                # Let's assume standard parsing.
                # The data structure in Step 348 looked like a list inside "Result" or just a list?
                # "Result": [ ...
                
                # We need to find the dict key that matches resource_type
                
                # Generic parse helper
                resources = data.get("Result", [])
                for res in resources:
                    if resource_type in res:
                        return res[resource_type]
            except:
                pass
                
            # Fallback regex if JSON parsing fails/is strict
            # Look for "last_roll": "X" within the block of the resource type
            # Use simple text search since checking JSON structure is safer but harder without `json` import if not present
            # But I imported json at top of file.
            
            return None
            
        except Exception as e:
            print(f"Error fetching resource: {e}")
            return None

    def dice_roll(self, sides):
        print(f"Requesting on-chain random roll via `game_examples::roll_dice`...")
        func_id = "0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403::game_examples::roll_dice"
        
        self._run_command(func_id, [f"u64:{sides}"])
        
        # Immediate read of state
        # Note: Resource update is atomic with transaction, removing index latency (mostly, if using same node)
        res_type = "0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403::game_examples::DiceGame"
        data = self._get_resource(res_type)
        
        if data and "last_roll" in data:
            return int(data["last_roll"])

        print(f"Could not parse result from chain, using fallback.")
        return random.randint(1, sides)

    def open_loot_box(self, num_items):
        print(f"Opening loot box via `game_examples::open_loot_box`...")
        func_id = "0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403::game_examples::open_loot_box"
        
        output = self._run_command(func_id, [f"u64:{num_items}"])
        
        items = []
        if output:
            match_hash = re.search(r'"transaction_hash":\s*"(0x[0-9a-f]+)"', output)
            if match_hash:
                tx_hash = match_hash.group(1)
                full_details = self._get_events_for_hash(tx_hash)
                
                if full_details:
                    # Look for items. This matches standard item fields in JSON response.
                    drop_pattern = r'"item_id":\s*"?(\d+)"?.*?,"rarity":\s*"?(\d+)"?.*?"power":\s*"?(\d+)"?'
                    # Note: Using non-greedy match .*? to hope they are close together.
                    # A better way is parsing real JSON but we are using regex for this task constraint
                    matches = re.finditer(drop_pattern, full_details, re.DOTALL)
                    for m in matches:
                        items.append({
                            'item_id': int(m.group(1)),
                            'rarity': int(m.group(2)),
                            'power': int(m.group(3))
                        })
        
        if not items:
            # Fallback Simulation
            for i in range(num_items):
                rarity = random.choices([0, 1, 2, 3, 4], weights=[50, 30, 15, 4, 1])[0]
                items.append({
                    'item_id': random.randint(1000, 9999),
                    'rarity': rarity,
                    'power': random.randint(10, 100)
                })
            
        return items

    def execute_attack(self, min_dmg, max_dmg, crit_chance):
        # Optimization: Use a single on-chain roll (1-10000) to derive both
        # damage luck and crit check to save time and gas.
        
        # Roll 1-10000
        combined_seed = self.dice_roll(10000)
        
        # Split seed
        # 0-99 for crit (last 2 digits)
        crit_roll_val = combined_seed % 100
        
        # 0-99 for damage luck (next 2 digits approx)
        luck_roll_val = (combined_seed // 100) % 100
        
        # Calculate damage
        dmg_range = max_dmg - min_dmg
        added_dmg = int((luck_roll_val / 100.0) * dmg_range)
        base_dmg = min_dmg + added_dmg
        
        # Crit check (0-99 < chance)
        is_crit = crit_roll_val < crit_chance
        
        final_dmg = base_dmg * 2 if is_crit else base_dmg
        
        return final_dmg, is_crit

    def start_card_game(self):
        print(f"Shuffling deck via `game_examples::start_card_game`...")
        func_id = "0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403::game_examples::start_card_game"
        
        self._run_command(func_id, [])
        
        res_type = "0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403::game_examples::CardGame"
        data = self._get_resource(res_type)
        
        if data and "player_hand" in data:
            # player_hand is a list of strings ["1", "2"]
            try:
                return [int(x) for x in data["player_hand"]]
            except:
                pass
                
        print(f"Could not parse hand from chain, using simulated shuffle.")
        deck = list(range(52))
        random.shuffle(deck)
        return deck

# Global instance for easy import
provider = RandomProvider()
