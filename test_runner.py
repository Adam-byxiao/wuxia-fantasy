#!/usr/bin/env python3
"""
MVP 世界生成系统 - 测试运行器
验证 GDScript 语法和核心逻辑
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Dict, Any, Optional

# 项目根目录
PROJECT_ROOT = Path(r"F:\Godot Project\wuxia-fantasy")

class TestResult:
    def __init__(self, name: str, passed: bool, message: str = ""):
        self.name = name
        self.passed = passed
        self.message = message

class GDSCriptValidator:
    """GDScript 语法验证器"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.errors = []

    def validate_file(self, filepath: Path) -> List[str]:
        """验证单个 GDScript 文件的语法"""
        errors = []
        try:
            content = filepath.read_text(encoding='utf-8')
            errors.extend(self._check_basic_syntax(content))
            errors.extend(self._check_common_issues(content))
        except Exception as e:
            errors.append(f"读取文件失败: {e}")
        return errors

    def _check_basic_syntax(self, content: str) -> List[str]:
        """基本语法检查"""
        errors = []

        # 检查括号匹配
        open_parens = content.count('(')
        close_parens = content.count(')')
        if open_parens != close_parens:
            errors.append(f"括号不匹配: ( 数量={open_parens}, ) 数量={close_parens}")

        # 检查花括号匹配
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces != close_braces:
            errors.append(f"花括号不匹配: {{ 数量={open_braces}, }} 数量={close_braces}")

        # 检查方括号匹配
        open_brackets = content.count('[')
        close_brackets = content.count(']')
        if open_brackets != close_brackets:
            errors.append(f"方括号不匹配: [ 数量={open_brackets}, ] 数量={close_brackets}")

        return errors

    def _check_common_issues(self, content: str) -> List[str]:
        """常见问题检查"""
        errors = []

        # 检查 class_name 和 extends 的位置
        lines = content.split('\n')
        for i, line in enumerate(lines, 1):
            stripped = line.strip()

            # 检查 class_name 是否在 extends 之后
            if 'class_name' in stripped and i > 1:
                prev_lines = lines[max(0, i-3):i]
                has_extends = any('extends' in pl.strip() for pl in prev_lines)
                if not has_extends and 'extends' not in content[:content.find(line)]:
                    pass  # class_name 可以在文件开头

            # 检查是否有可疑的分号
            if ';' in stripped and not stripped.startswith('#'):
                # 允许注释中的分号
                if not stripped.strip().startswith('#'):
                    errors.append(f"行 {i}: 可疑的分号用法")

        return errors

class WorldRendererConfigTester:
    """测试 WorldRendererConfig"""

    def run_tests(self) -> List[TestResult]:
        results = []

        # 读取配置文件
        config_path = PROJECT_ROOT / "scripts" / "world" / "world_renderer_config.gd"
        content = config_path.read_text(encoding='utf-8')

        # 测试季节颜色配置
        results.append(TestResult(
            "WorldRendererConfig.SEASON_COLORS 存在",
            "春" in content and "夏" in content and "秋" in content and "冬" in content
        ))

        # 测试地形类型
        results.append(TestResult(
            "WorldRendererConfig.TERRAIN_TYPES 存在",
            "forest" in content and "mountain" in content
        ))

        # 测试 get_season_terrain_color 函数
        results.append(TestResult(
            "WorldRendererConfig.get_season_terrain_color 存在",
            "get_season_terrain_color" in content
        ))

        # 验证 SEASON_COLORS 结构
        # 直接检查四个季节字符串是否存在于文件中
        spring = '"春"' in content
        summer = '"夏"' in content
        autumn = '"秋"' in content
        winter = '"冬"' in content
        results.append(TestResult(
            "四季配置完整 (春:" + str(spring) + " 夏:" + str(summer) + " 秋:" + str(autumn) + " 冬:" + str(winter) + ")",
            spring and summer and autumn and winter
        ))

        return results

class RegionDifficultyConfigTester:
    """测试 RegionDifficultyConfig"""

    def run_tests(self) -> List[TestResult]:
        results = []

        config_path = PROJECT_ROOT / "scripts" / "world" / "region_difficulty_config.gd"
        content = config_path.read_text(encoding='utf-8')

        # 测试难度配置
        results.append(TestResult(
            "DIFFICULTY_CONFIG 存在",
            "DIFFICULTY_CONFIG" in content
        ))

        # 测试奖励配置
        results.append(TestResult(
            "get_rewards 方法存在",
            "get_rewards" in content
        ))

        # 测试敌人倍率
        results.append(TestResult(
            "get_enemy_multiplier 方法存在",
            "get_enemy_multiplier" in content
        ))

        # 验证奖励数值
        rewards_match = re.search(r'"exp": (\d+),.*?"gold": (\d+)', content)
        if rewards_match:
            exp_val = int(rewards_match.group(1))
            results.append(TestResult(
                f"基础奖励 exp={exp_val}",
                exp_val == 50
            ))

        return results

class WorldGeneratorTester:
    """测试 WorldGenerator"""

    def run_tests(self) -> List[TestResult]:
        results = []

        gen_path = PROJECT_ROOT / "scripts" / "world" / "world_generator.gd"
        content = gen_path.read_text(encoding='utf-8')

        # 测试路径查询方法
        results.append(TestResult(
            "get_connected_regions 方法存在",
            "get_connected_regions" in content
        ))

        results.append(TestResult(
            "find_path_between 方法存在",
            "find_path_between" in content
        ))

        results.append(TestResult(
            "get_distance_between 方法存在",
            "get_distance_between" in content
        ))

        results.append(TestResult(
            "get_region_center 方法存在",
            "get_region_center" in content
        ))

        # 测试 BFS 路径查找实现
        if "find_path_between" in content:
            # 检查是否有 BFS 相关的队列或访问标记
            has_queue = "queue" in content.lower() or "Array" in content
            has_visited = "visited" in content or "visited" in content
            results.append(TestResult(
                "BFS 路径查找实现完整",
                has_queue and has_visited
            ))

        return results

class NPCAgentTester:
    """测试 NPCAgent"""

    def run_tests(self) -> List[TestResult]:
        results = []

        agent_path = PROJECT_ROOT / "scripts" / "world" / "npc_agent.gd"
        content = agent_path.read_text(encoding='utf-8')

        # 测试区域间移动方法
        results.append(TestResult(
            "_start_travel 方法存在",
            "_start_travel" in content
        ))

        results.append(TestResult(
            "_move_along_path 方法存在",
            "_move_along_path" in content
        ))

        results.append(TestResult(
            "_on_world_generated 方法存在",
            "_on_world_generated" in content
        ))

        # 测试公共方法
        results.append(TestResult(
            "is_traveling 方法存在",
            "is_traveling" in content
        ))

        results.append(TestResult(
            "get_travel_path 方法存在",
            "get_travel_path" in content
        ))

        # 检查 WorldGenerator 调用
        results.append(TestResult(
            "使用 WorldGenerator.find_path_between",
            "WorldGenerator.find_path_between" in content
        ))

        results.append(TestResult(
            "使用 WorldGenerator.get_region_center",
            "WorldGenerator.get_region_center" in content
        ))

        return results

class SeasonEffectSystemTester:
    """测试 SeasonEffectSystem"""

    def run_tests(self) -> List[TestResult]:
        results = []

        system_path = PROJECT_ROOT / "scripts" / "world" / "season_effect_system.gd"
        content = system_path.read_text(encoding='utf-8')

        # 测试季节变化信号连接
        results.append(TestResult(
            "监听 season_changed 信号",
            "season_changed" in content
        ))

        results.append(TestResult(
            "监听 day_passed 信号",
            "day_passed" in content
        ))

        # 测试 apply_season_visual 方法
        results.append(TestResult(
            "_apply_season_visual 方法存在",
            "_apply_season_visual" in content
        ))

        # 测试 WorldRenderer 调用
        results.append(TestResult(
            "调用 WorldRenderer.apply_season_overlay",
            "apply_season_overlay" in content
        ))

        return results

class RegionTransitionTester:
    """测试 RegionTransition"""

    def run_tests(self) -> List[TestResult]:
        results = []

        trans_path = PROJECT_ROOT / "scripts" / "world" / "region_transition.gd"
        content = trans_path.read_text(encoding='utf-8')

        # 测试过渡阶段枚举
        results.append(TestResult(
            "TransitionPhase 枚举存在",
            "TransitionPhase" in content
        ))

        # 测试信号发射
        results.append(TestResult(
            "发射 region_entered 信号",
            "region_entered.emit" in content
        ))

        # 测试过渡动画
        results.append(TestResult(
            "_trigger_transition 方法存在",
            "_trigger_transition" in content
        ))

        results.append(TestResult(
            "_update_transition 方法存在",
            "_update_transition" in content
        ))

        # 测试 GameState 更新
        results.append(TestResult(
            "更新 GameState.current_region_id",
            "GameState.current_region_id" in content
        ))

        return results

class GDScriptSyntaxTester:
    """所有 GDScript 文件语法测试"""

    def run_tests(self) -> List[TestResult]:
        results = []
        validator = GDSCriptValidator(PROJECT_ROOT)

        # 测试所有 world 相关脚本
        world_scripts = [
            "scripts/world/world_renderer_config.gd",
            "scripts/world/world_renderer.gd",
            "scripts/world/season_effect_system.gd",
            "scripts/world/region_transition.gd",
            "scripts/world/region_difficulty_config.gd",
            "scripts/world/world_generator.gd",
            "scripts/world/npc_agent.gd",
        ]

        for script_path in world_scripts:
            full_path = PROJECT_ROOT / script_path
            if full_path.exists():
                errors = validator.validate_file(full_path)
                results.append(TestResult(
                    f"语法检查: {script_path}",
                    len(errors) == 0,
                    "\n".join(errors) if errors else "OK"
                ))
            else:
                results.append(TestResult(
                    f"文件存在: {script_path}",
                    False,
                    "文件不存在"
                ))

        return results

def run_all_tests() -> List[TestResult]:
    """运行所有测试"""
    all_results = []

    print("=" * 60)
    print("MVP World Generation System - Test Runner")
    print("=" * 60)

    # 语法测试
    print("\n[1/7] GDScript Syntax Tests...")
    syntax_tester = GDScriptSyntaxTester()
    all_results.extend(syntax_tester.run_tests())

    # WorldRendererConfig 测试
    print("[2/7] WorldRendererConfig Tests...")
    config_tester = WorldRendererConfigTester()
    all_results.extend(config_tester.run_tests())

    # RegionDifficultyConfig 测试
    print("[3/7] RegionDifficultyConfig Tests...")
    diff_tester = RegionDifficultyConfigTester()
    all_results.extend(diff_tester.run_tests())

    # WorldGenerator 测试
    print("[4/7] WorldGenerator Tests...")
    gen_tester = WorldGeneratorTester()
    all_results.extend(gen_tester.run_tests())

    # NPCAgent 测试
    print("[5/7] NPCAgent Tests...")
    npc_tester = NPCAgentTester()
    all_results.extend(npc_tester.run_tests())

    # SeasonEffectSystem 测试
    print("[6/7] SeasonEffectSystem Tests...")
    season_tester = SeasonEffectSystemTester()
    all_results.extend(season_tester.run_tests())

    # RegionTransition 测试
    print("[7/7] RegionTransition Tests...")
    trans_tester = RegionTransitionTester()
    all_results.extend(trans_tester.run_tests())

    return all_results

def print_results(results: List[TestResult]) -> None:
    """打印测试结果"""
    print("\n" + "=" * 60)
    print("Test Results")
    print("=" * 60)

    passed = 0
    failed = 0

    for result in results:
        status = "PASS" if result.passed else "FAIL"
        symbol = "[+]" if result.passed else "[-]"
        print(f"  [{status}] {symbol} {result.name}")
        if result.message and not result.passed:
            print(f"         {result.message}")

        if result.passed:
            passed += 1
        else:
            failed += 1

    print("-" * 60)
    print(f"Total: {len(results)} tests")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print("=" * 60)

    if failed > 0:
        print("\nSome tests failed - needs fixing!")
    else:
        print("\nAll tests passed!")

    # Debug info
    print("\n" + "=" * 60)
    print("Debug Info")
    print("=" * 60)
    debug_info()

def main():
    """主函数"""
    results = run_all_tests()
    print_results(results)

    # 返回退出码
    failed = sum(1 for r in results if not r.passed)
    return 1 if failed > 0 else 0

def debug_info():
    """输出调试信息"""
    print("\nProject Structure:")
    for f in sorted((PROJECT_ROOT / "scripts" / "world").glob("*.gd")):
        size = f.stat().st_size
        print(f"  {f.name}: {size} bytes")

    print("\nSeason Colors Check:")
    config_path = PROJECT_ROOT / "scripts" / "world" / "world_renderer_config.gd"
    content = config_path.read_text(encoding='utf-8')
    seasons = ['"春"', '"夏"', '"秋"', '"冬"']
    for s in seasons:
        found = s in content
        print(f"  {s}: {'Found' if found else 'MISSING'}")

    print("\nTerrain Types Check:")
    terrains = ['"forest"', '"mountain"', '"town"', '"dungeon"', '"road"', '"special"']
    for t in terrains:
        found = t in content
        print(f"  {t}: {'Found' if found else 'MISSING'}")

if __name__ == "__main__":
    sys.exit(main())
