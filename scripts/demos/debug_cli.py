
import sys
import os
import subprocess

print("DEBUG: Checking cedra version...")
try:
    res = subprocess.run(["cedra", "--version"], capture_output=True, text=True, check=True)
    print(f"STDOUT: {res.stdout}")
    print(f"STDERR: {res.stderr}")
except Exception as e:
    print(f"ERROR: {e}")

print("\nDEBUG: Running dice_roll with stderr capture...")
cmd = [
    "cedra", "move", "run",
    "--function-id", "0xffc8b7e8ba733db4e66a992570a9531e80b92b4303cca0bb93f2fba987def403::game_examples::roll_dice",
    "--profile", "testnet",
    "--args", "u64:6"
]
try:
    # Not using check=True to see output even on failure
    res = subprocess.run(cmd, capture_output=True, text=True)
    print(f"Return Code: {res.returncode}")
    print("--- STDOUT ---")
    print(res.stdout)
    print("--- STDERR ---")
    print(res.stderr)
except Exception as e:
    print(f"ERROR executing run: {e}")
