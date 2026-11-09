#!/usr/bin/env python3
"""check_stubs.py —— 编译前门禁。

两件事：
1. 每个 ClassHook<T> 的 T 必须在 stubs/FVPrivate.h 里有 @interface 声明；
   少一个，theos 会在 CI 里报 "cannot find type 'X' in scope"，白烧一轮 runner。
2. 每个 orig.<sel>(...) 调用的 selector 必须能在对应目标类的声明里找到，
   否则报 "value of type 'X' has no member 'sel'"。

用法：python3 tools/check_stubs.py        # 有错退出码 1
"""

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 这些类 theos 的 iPhoneOS SDK 里已经带了声明（UIKit 私有头），
# 我们不能重复声明，否则 clang 报 duplicate interface definition。
SDK_PROVIDED = {"_UIKeyboardLayerHostView", "UIKeyboardSceneDelegate"}
STUB = os.path.join(ROOT, "stubs", "FVPrivate.h")


def read(p):
    with open(p, encoding="utf-8", errors="ignore") as f:
        return f.read()


def strip_comments(text):
    """去掉 // 与 /* */ 注释，避免注释里的示例写法被当成真实代码。"""
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def declared_classes(header):
    """返回 {类名: 该 @interface 块内的全部 selector 名}"""
    out = {}
    for m in re.finditer(r"@interface\s+(\w+)\s*:\s*(\w+)(.*?)@end", header, re.S):
        name, _super, body = m.group(1), m.group(2), m.group(3)
        sels = set()
        for line in body.split("\n"):
            line = line.strip()
            if not line.startswith(("-", "+")):
                continue
            # 取 selector：把 :(type) 折叠成 ':'，再去掉 : 得到方法名
            spec = re.sub(r":\s*\([^)]*\)\s*\w+", ":", line)
            spec = re.sub(r"^[-+]\s*", "", spec)
            spec = re.sub(r"^\([^)]*\)\s*", "", spec)
            spec = re.sub(r":\s*\w+", ":", spec)
            name_part = spec.split(":")[0].strip()
            name_part = re.sub(r"[\s;{].*$", "", name_part)
            if name_part:
                sels.add(name_part)
        out[name] = sels
    return out


def main():
    decl = declared_classes(read(STUB))
    errors = []

    hooks = []
    for f in glob.glob(os.path.join(ROOT, "Sources", "**", "*.swift"), recursive=True):
        text = strip_comments(read(f))
        for m in re.finditer(r"ClassHook<\s*(\w+)\s*>", text):
            hooks.append((os.path.relpath(f, ROOT), m.group(1)))

    for path, target in hooks:
        if target in SDK_PROVIDED:
            continue
        if target not in decl:
            errors.append(f"缺少桩头：{target}（{path} 里 ClassHook<{target}>）")

    # orig.<sel>( 检查
    for f in glob.glob(os.path.join(ROOT, "Sources", "Hooks", "*.swift")):
        text = strip_comments(read(f))
        for m in re.finditer(r"ClassHook<\s*(\w+)\s*>", text):
            target = m.group(1)
            if target in SDK_PROVIDED or target not in decl:
                continue
            for sel in sorted(set(re.findall(r"orig\.(\w+)\s*\(", text))):
                if sel not in decl[target]:
                    errors.append(f"桩头缺 selector：{target}.{sel}（{os.path.basename(f)}）")

    print(f"桩头类: {len(decl)}  钩子: {len(hooks)}")
    if errors:
        print(f"\n发现 {len(errors)} 个问题：")
        for e in errors:
            print("  ✗", e)
        return 1
    print("✓ 桩头门禁通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
