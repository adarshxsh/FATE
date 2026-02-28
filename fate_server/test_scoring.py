import os
import sys

# Ensure core module can be imported
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from core.scoring import calculate_digital_score, calculate_notification_score

def print_result(test_name, result):
    print(f"\n--- {test_name} ---")
    print(f"Score: {result:.2f}")

if __name__ == "__main__":
    print("=== TESTING DIGITAL (APP USAGE) SCORING ===")
    
    # PRODUCTIVITY (Limit 4 hours)
    print_result("PRODUCTIVITY: 2 hours (Under limit)", calculate_digital_score("PRODUCTIVITY", 2 * 3600))
    print_result("PRODUCTIVITY: 5 hours (1 hour OVER limit)", calculate_digital_score("PRODUCTIVITY", 5 * 3600))
    
    # ENTERTAINMENT (Limit 30 minutes)
    print_result("ENTERTAINMENT: 15 minutes (Under limit)", calculate_digital_score("ENTERTAINMENT", 15 * 60))
    print_result("ENTERTAINMENT: 1 hour (30 mins OVER limit)", calculate_digital_score("ENTERTAINMENT", 60 * 60))
    print_result("ENTERTAINMENT: 3 hours (2.5 hours OVER limit)", calculate_digital_score("ENTERTAINMENT", 3 * 3600))
    
    print("\n=== TESTING NOTIFICATION SCORING ===")
    
    # URGENT KEYWORD in content ("deadline")
    print_result("URGENT (Productivity App): Ignored", 
                 calculate_notification_score("PRODUCTIVITY", "Submit assignment before deadline", None))
    print_result("URGENT (Productivity App): Clicked in 30 seconds", 
                 calculate_notification_score("PRODUCTIVITY", "Submit assignment before deadline", 30))
    print_result("URGENT (Productivity App): Clicked in 10 minutes (Missed window)", 
                 calculate_notification_score("PRODUCTIVITY", "Submit assignment before deadline", 600))
    
    # SOCIAL/DISTRACTING KEYWORD in content ("reel", "liked")
    print_result("SOCIAL DISTRACTION (Social App): Ignored (GOOD)", 
                 calculate_notification_score("SOCIAL", "someone liked your reel", None))
    print_result("SOCIAL DISTRACTION (Social App): Clicked instantly in 10s (BAD)", 
                 calculate_notification_score("SOCIAL", "someone liked your reel", 10))
    print_result("SOCIAL DISTRACTION (Social App): Clicked after 5 mins", 
                 calculate_notification_score("SOCIAL", "someone liked your reel", 300))
