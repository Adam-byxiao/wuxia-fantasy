#!/usr/bin/env python3
"""
整体测试运行器
执行所有验证场景并报告结果
"""

import os
import sys
import subprocess
import time
from pathlib import Path
from typing import Optional, List, Dict

# 项目根目录
PROJECT_ROOT = Path(r"F:\Godot Project\wuxia-fantasy")

# Godot 常用路径
GODOT_PATHS = [
    # Windows
    "C:\\Program Files\\Godot_v4.6-stable\\Godot_v4.6-stable.exe",
    "C:\\Program Files\\Godot\\Godot_v4.6.exe",
    # WSL
    "/mnt/c/Program Files/Godot_v4.6-stable/Godot_v4.6-stable.exe",
    # Steam
    os.path.expanduser("~/.steam/steamapps/common/Godot_v4.6/Godot_v4.6.exe"),
    # Godot in PATH
    "godot",
    "godot4",
]

class TestRunner:
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.godot_path: Optional[str] = None
        self.tests: List[Dict] = []

    def find_godot(self) -> bool:
        """查找 Godot 可执行文件"""
        print("Searching for Godot executable...")

        for path in GODOT_PATHS:
            if os.path.exists(path):
                self.godot_path = path
                print(f"Found Godot at: {path}")
                return True

        # 尝试从 PATH 查找
        for name in ["godot", "godot4", "Godot_v4.6", "Godot_v4.6-stable"]:
            try:
                result = subprocess.run([name, "--version"],
                                      capture_output=True,
                                      text=True,
                                      timeout=5)
                if result.returncode == 0:
                    self.godot_path = name
                    print(f"Found Godot in PATH: {name}")
                    print(f"Version: {result.stdout.strip()}")
                    return True
            except:
                pass

        print("Godot not found!")
        return False

    def run_script_test(self, script_path: Path) -> Dict:
        """运行 GDScript 测试（静态分析）"""
        result = {
            "name": script_path.stem,
            "path": str(script_path),
            "passed": False,
            "output": "",
            "error": ""
        }

        try:
            content = script_path.read_text(encoding='utf-8')
            errors = self._validate_gdscript(content)
            result["passed"] = len(errors) == 0
            result["output"] = f"Lines: {len(content.splitlines())}, Errors: {len(errors)}"
            if errors:
                result["error"] = "\n".join(errors[:5])  # 前5个错误
        except Exception as e:
            result["error"] = str(e)

        return result

    def _validate_gdscript(self, content: str) -> List[str]:
        """验证 GDScript 基本语法"""
        errors = []

        # 括号匹配检查（简单的字符串计数可能产生误报）
        # 统计平衡情况
        parens = content.count('(') - content.count(')')
        brackets = content.count('[') - content.count(']')
        braces = content.count('{') - content.count('}')

        if parens != 0:
            errors.append(f"Parentheses imbalance: diff={parens}")
        if brackets != 0:
            errors.append(f"Bracket imbalance: diff={brackets}")
        if braces != 0:
            errors.append(f"Brace imbalance: diff={braces}")

        # 基本结构检查
        lines = content.split('\n')
        has_extends = any('extends' in line for line in lines[:5])
        has_class_name = any('class_name' in line for line in lines[:5])

        if has_class_name and not has_extends:
            errors.append("class_name should come after extends")

        # 检查是否有必要的结构
        if not any(line.strip().startswith('func ') for line in lines):
            errors.append("No functions found")

        return errors

    def run_verification_scene(self, scene_path: Path) -> Dict:
        """运行验证场景"""
        result = {
            "name": scene_path.stem,
            "path": str(scene_path),
            "passed": False,
            "output": "",
            "error": ""
        }

        if not self.godot_path:
            result["error"] = "Godot not found - cannot run scene"
            return result

        try:
            # 使用 --headless 运行验证场景
            cmd = [
                self.godot_path,
                "--headless",
                "--path", str(self.project_root),
                "--scene", str(scene_path)
            ]

            proc = subprocess.run(cmd,
                                 capture_output=True,
                                 text=True,
                                 timeout=30)

            result["output"] = proc.stdout[:500] if proc.stdout else ""
            result["error"] = proc.stderr[:500] if proc.stderr else ""
            result["passed"] = proc.returncode == 0

        except subprocess.TimeoutExpired:
            result["error"] = "Timeout after 30 seconds"
        except Exception as e:
            result["error"] = str(e)

        return result

    def scan_verification_scenes(self) -> List[Path]:
        """扫描所有验证场景"""
        verify_dir = self.project_root / "scenes" / "verification"
        if not verify_dir.exists():
            return []

        scenes = []
        for f in verify_dir.glob("*.gd"):
            scenes.append(f)
        return sorted(scenes)

    def run_all_tests(self) -> int:
        """运行所有测试"""
        print("=" * 60)
        print("Integration Test Runner")
        print("=" * 60)

        # 查找 Godot
        godot_found = self.find_godot()

        # 扫描验证场景
        scenes = self.scan_verification_scenes()
        print(f"\nFound {len(scenes)} verification scripts:")

        for scene in scenes:
            print(f"  - {scene.name}")

        print("\n" + "-" * 60)
        print("Running GDScript Static Analysis...")
        print("-" * 60)

        all_passed = True
        results = []

        # 静态分析测试
        for scene in scenes:
            result = self.run_script_test(scene)
            results.append(result)

            status = "PASS" if result["passed"] else "FAIL"
            symbol = "[+]" if result["passed"] else "[-]"
            print(f"  [{status}] {symbol} {result['name']}")
            if result.get("error"):
                print(f"         {result['error'][:100]}")

            if not result["passed"]:
                all_passed = False

        # 如果 Godot 可用，尝试运行实际场景测试
        if godot_found:
            print("\n" + "-" * 60)
            print("Running Godot Scene Tests (headless)...")
            print("-" * 60)

            for scene in scenes:
                tscn_path = scene.with_suffix('.tscn')
                if tscn_path.exists():
                    result = self.run_verification_scene(tscn_path)
                    results.append(result)

                    status = "PASS" if result["passed"] else "FAIL"
                    symbol = "[+]" if result["passed"] else "[-]"
                    print(f"  [{status}] {symbol} {result['name']} (scene)")
                    if result.get("error"):
                        print(f"         {result['error'][:100]}")

                    if not result["passed"]:
                        all_passed = False
        else:
            print("\n[SKIP] Godot not available - scene tests skipped")
            print("       Install Godot 4.6 to run full integration tests")

        # 总结
        print("\n" + "=" * 60)
        print("Summary")
        print("=" * 60)

        total = len(results)
        passed = sum(1 for r in results if r["passed"])
        failed = total - passed

        print(f"Total tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {failed}")

        if failed > 0:
            print("\nFailed tests:")
            for r in results:
                if not r["passed"]:
                    print(f"  - {r['name']}: {r.get('error', 'Unknown error')[:80]}")

        print("=" * 60)

        return 0 if all_passed else 1

def main():
    runner = TestRunner(PROJECT_ROOT)
    return runner.run_all_tests()

if __name__ == "__main__":
    sys.exit(main())
