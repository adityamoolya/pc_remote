import argparse

# 1. Create the parser
parser = argparse.ArgumentParser(description="A simple test script.")

# 2. Add the arguments you want to look for
# action="store_true" means: if --pair is present, set args.pair to True.
# If it's not present, it will be False by default.
parser.add_argument(
    '--pair', 
    action='store_true', 
    help="Run in pairing mode."
)

# This one shows how to accept a value (like --unpair DEVICE_ID)
parser.add_argument(
    '--name', 
    help="Provide a name."
)

# 3. Parse the arguments
# This line reads the command line (like "python test_args.py --pair")
args = parser.parse_args()

# 4. Use the arguments
if args.pair:
    print("✅ Pairing mode is ON.")

elif args.name:
    print(f"a👋 Hello, {args.name}!")
    
else:
    print("...Running in normal mode...")