#!/usr/bin/env python3
"""
WorldSim Module Unit Tests
Tests TimeManager and EventManager logic in Python
"""

import random

# ===== TimeManager Tests =====

SEASONS = ["春", "夏", "秋", "冬"]
DAYS_PER_SEASON = 30

def advance_day(current_day):
    """Simulates TimeManager.advance_day()"""
    current_day += 1
    new_season = SEASONS[(current_day // DAYS_PER_SEASON) % 4]
    return current_day, new_season

def test_time_manager():
    print("=" * 50)
    print("TimeManager Tests")
    print("=" * 50)

    # Note: season index = (day // 30) % 4
    # day 1-29 -> index 0 -> 春
    # day 30 -> index 1 -> 夏 (season changes at day 30)
    # day 60 -> index 2 -> 秋
    # day 90 -> index 3 -> 冬
    # day 120 -> index 4 -> 春 (cycles back)
    test_cases = [
        # (start_day, expected_day, expected_season)
        (1, 2, "春"),    # day 2: 2//30=0 -> 春
        (29, 30, "夏"),  # day 30: 30//30=1 -> 夏 (season transition!)
        (30, 31, "夏"),  # day 31: 31//30=1 -> 夏
        (59, 60, "秋"),  # day 60: 60//30=2 -> 秋 (season transition!)
        (60, 61, "秋"),  # day 61: 61//30=2 -> 秋
        (89, 90, "冬"),  # day 90: 90//30=3 -> 冬 (season transition!)
        (90, 91, "冬"),  # day 91: 91//30=3 -> 冬
        (119, 120, "春"),# day 120: 120//30=4%4=0 -> 春 (season transition!)
        (120, 121, "春"),# day 121: 121//30=4%4=0 -> 春
    ]

    all_passed = True
    for start_day, expected_day, expected_season in test_cases:
        result_day, result_season = advance_day(start_day)
        passed = result_day == expected_day and result_season == expected_season
        status = "PASS" if passed else "FAIL"
        print(f"  advance_day({start_day}) -> day={result_day}, season={result_season} [{status}]")
        if not passed:
            print(f"    Expected: day={expected_day}, season={expected_season}")
            all_passed = False

    return all_passed

# ===== EventManager Tests =====

class EventConfig:
    def __init__(self, event_id, name, weight, min_day):
        self.event_id = event_id
        self.name = name
        self.weight = weight
        self.min_day = min_day

def weighted_random_select(event_configs, seed):
    """Simulates EventManager._weighted_random_select()"""
    total_weight = sum(e.weight for e in event_configs)
    if total_weight == 0:
        return None

    random.seed(seed)
    roll = random.randint(0, total_weight - 1)

    current = 0
    for e in event_configs:
        current += e.weight
        if roll < current:
            return e
    return None

def check_conditions(current_day, config):
    """Simulates EventManager._check_conditions()"""
    if current_day < config.min_day:
        return False
    return True

def test_event_manager():
    print("\n" + "=" * 50)
    print("EventManager Tests")
    print("=" * 50)

    # Create test event configs
    events = [
        EventConfig("e1", "江湖事件", 10, 1),
        EventConfig("e2", "门派争斗", 20, 10),
        EventConfig("e3", "稀世珍宝", 5, 30),
    ]

    # Test 1: Weighted random selection with different seeds
    print("\n  Test 1: Weighted Random Selection")
    all_passed = True

    # Run multiple times with same seed should give same result
    results = {}
    for seed in [1, 2, 3, 10, 30]:
        selected = weighted_random_select(events, seed)
        results[seed] = selected.event_id if selected else None

    # Same seed = same result (deterministic)
    for seed in [1, 2, 3, 10, 30]:
        selected = weighted_random_select(events, seed)
        expected = results[seed]
        actual = selected.event_id if selected else None
        passed = actual == expected
        status = "PASS" if passed else "FAIL"
        print(f"    Seed {seed}: selected={actual} [{status}]")
        if not passed:
            all_passed = False

    # Test 2: min_day condition filtering
    # check_conditions returns True if current_day >= min_day
    print("\n  Test 2: min_day Condition Filtering")
    for day, expected_pass in [(1, False), (5, False), (9, False), (10, True), (29, True), (30, True)]:
        passed = check_conditions(day, events[1])  # events[1] has min_day=10
        status = "PASS" if passed == expected_pass else "FAIL"
        print(f"    day={day}, min_day=10, expected_pass={expected_pass}, actual={passed} [{status}]")
        if passed != expected_pass:
            all_passed = False

    # Test 3: Verify weight distribution
    print("\n  Test 3: Weight Distribution (1000 samples per seed)")
    events_simple = [
        EventConfig("A", "Event A", 75, 1),
        EventConfig("B", "Event B", 25, 1),
    ]

    samples = 1000
    seed = 42
    counts = {"A": 0, "B": 0}
    for _ in range(samples):
        selected = weighted_random_select(events_simple, seed)
        if selected:
            counts[selected.event_id] += 1
        seed += 1

    # A should appear roughly 75% of the time
    a_ratio = counts["A"] / samples
    passed = 0.70 < a_ratio < 0.80
    status = "PASS" if passed else "FAIL"
    print(f"    Event A: {counts['A']}/{samples} ({a_ratio*100:.1f}%) [{status}]")
    print(f"    Event B: {counts['B']}/{samples} ({100-a_ratio*100:.1f}%)")
    if not passed:
        all_passed = False

    return all_passed

# ===== Main =====
if __name__ == "__main__":
    print("\n" + "=" * 50)
    print("WorldSim Module Unit Tests")
    print("=" * 50)

    time_passed = test_time_manager()
    event_passed = test_event_manager()

    print("\n" + "=" * 50)
    print("Summary")
    print("=" * 50)
    print(f"  TimeManager: {'ALL PASSED' if time_passed else 'SOME FAILED'}")
    print(f"  EventManager: {'ALL PASSED' if event_passed else 'SOME FAILED'}")
    print(f"  Overall: {'PASS' if (time_passed and event_passed) else 'FAIL'}")
    print("=" * 50)