#!/bin/sh
# =============================================================================
# dsh-alpine-installer
# 在 Alpine Linux 上一键安装 DeepSeek Harness (@deepseek-ai/dsh)
# 面向【全新安装的 Alpine】：跑完本脚本即可直接使用，无需任何手动步骤。
# 涵盖：apk 更新 → 基础工具/编译链/Node → npm 配置与镜像
#       → dsh 全局安装（原生模块源码编译）→ sharp wasm 兜底 → 启动包装器
#       → 默认工作区配置 → 逐项验证
#
# 解决的关键问题：
#   - koffi / node-pty 无预编译，需现场编译
#   - npm install-scripts 安全门跳过构建脚本（allow-scripts 放行）
#   - sharp 无预编译（@img/sharp-wasm32 WebAssembly 兜底）
#   - HMR 插件硬要求 --expose-internals（dsh 启动包装器）
#
# 用法： sh install-alpine.sh [--skip-upgrade] [--cn]
#        --cn            使用 npmmirror 镜像源（中国大陆网络推荐）
# 环境： Alpine Linux 3.18+，x86_64 / aarch64 / armv7
# =============================================================================
set -euo pipefail

# Ctrl+C / 异常退出时清理临时目录
SWDIR="$HOME/.dsh-alpine-sw"
trap 'rm -rf "$SWDIR"' EXIT

START_TS="$(date +%s)"

SKIP_UPGRADE=0
CN_MODE=0
for arg in "$@"; do
  case "$arg" in
    --skip-upgrade) SKIP_UPGRADE=1 ;;
    --cn) CN_MODE=1 ;;
    -h|--help) sed -n '1,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $arg（可用 --skip-upgrade / --cn）"; exit 1 ;;
  esac
done

log()  { printf '\033[1;36m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m  ✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
fail() { printf '\033[1;31m  ✗ %s\033[0m\n' "$*"; }

# ---- 0. 环境预检 --------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  warn "检测到 root 用户，建议使用普通用户运行（可用 adduser -D -s /bin/sh user && su - user）"
fi

# 检测是否为 Alpine
if [ ! -f /etc/alpine-release ]; then
  echo "错误: 未检测到 Alpine Linux（/etc/alpine-release 不存在）。"
  exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  TARGET="x86_64" ;;
  aarch64) TARGET="aarch64" ;;
  armv7l)  TARGET="armv7" ;;
  *)
    warn "未知架构 $ARCH，按 x86_64 处理，如编译失败请提交 issue"
    TARGET="x86_64" ;;
esac
log "架构: $ARCH   目标平台: $TARGET"

# ---- 1. 系统更新与编译工具链 ---------------------------------------------------
if [ "$SKIP_UPGRADE" -eq 0 ]; then
  log "apk update && apk upgrade（首次运行较久，务必等它完成）"
  apk update
  apk upgrade
else
  warn "已跳过 apk update/upgrade"
fi

log "安装基础工具与编译工具链: git curl cmake clang make python3 binutils pkgconfig linux-headers build-base"
apk add --no-cache git curl cmake clang make python3 binutils pkgconfig linux-headers build-base

# ---- 2. Node.js >= 22.12（dsh 依赖 commander 15 的硬性要求）-------------------
if ! command -v node >/dev/null 2>&1; then
  log "安装 nodejs npm"
  apk add --no-cache nodejs npm
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
NODE_MINOR="$(node -p 'process.versions.node.split(".")[1]')"
if [ "$NODE_MAJOR" -lt 22 ] || { [ "$NODE_MAJOR" -eq 22 ] && [ "$NODE_MINOR" -lt 12 ]; }; then
  echo "错误: dsh 需要 Node >= 22.12，当前是 $(node -v)。请先执行 apk upgrade && apk add nodejs npm 再重跑本脚本。"
  exit 1
fi
ok "Node $(node -v)"

# ---- 3. npm 镜像与 install-scripts 放行 -----------------------------------------
ALLOW_LIST="@deepseek-ai/dsh-subprocess-local,koffi,node-pty,@google/genai,protobufjs,pnpm"
log "配置 npm：install-scripts 放行 + 网络超时调优"
if npm config set allow-scripts="$ALLOW_LIST" --location=user 2>/dev/null; then
  ok "npm install-scripts 已放行（新 npm 安全门）"
else
  warn "当前 npm 不支持 allow-scripts（较旧版本）——旧 npm 默认会执行构建脚本，可忽略此警告"
fi

if [ "$CN_MODE" -eq 1 ]; then
  log "使用 npmmirror 镜像源（--cn）"
  npm config set registry https://registry.npmmirror.com --location=user
fi

# 弱网/慢网健壮性：加大 npm 下载超时与重试，避免一次抖动就失败
npm config set fetch-retries 5 --location=user 2>/dev/null || true
npm config set fetch-retry-mintimeout 20000 --location=user 2>/dev/null || true
npm config set fetch-retry-maxtimeout 120000 --location=user 2>/dev/null || true
npm config set fetch-timeout 300000 --location=user 2>/dev/null || true

# ---- 4. node-gyp common.gypi 补丁（不再需要 Android NDK 路径，但保留兼容）-------
log "预下载 Node 头文件（如需要）"
NODE_GYP="$(npm root -g)/npm/node_modules/node-gyp/bin/node-gyp.js"
if [ -f "$NODE_GYP" ]; then
  node "$NODE_GYP" install || warn "node-gyp 头文件预下载失败（安装过程会自动重试）"
fi

# Alpine 不需要 android_ndk_path 补丁，但保留函数以备兼容
patch_common_gypi() {
  return 0
}
patch_common_gypi

# ---- 5. 全局安装 @deepseek-ai/dsh ---------------------------------------------
# 网络预检：官方源连不通就直接切 npmmirror，避免"黑网挂死、无任何输出"
if [ "$CN_MODE" -eq 0 ]; then
  if ! curl -fsS --max-time 8 -o /dev/null https://registry.npmjs.org/-/ping 2>/dev/null; then
    warn "registry.npmjs.org 连接超时 → 自动切换 npmmirror 镜像源"
    npm config set registry https://registry.npmmirror.com --location=user
  fi
fi

log "开始安装 @deepseek-ai/dsh —— 这是最耗时的一步（下载数百个包 + koffi 源码编译，约 5~15 分钟）"
log "下载阶段可能长时间无输出，属正常；请不要关闭终端"
export CMAKE_BUILD_PARALLEL_LEVEL="${CMAKE_BUILD_PARALLEL_LEVEL:-2}"
if ! npm install -g --foreground-scripts --no-audit --no-fund @deepseek-ai/dsh; then
  warn "首次安装失败，重试一次"
  if [ "$CN_MODE" -eq 0 ]; then
    warn "仍失败则自动切换 npmmirror 镜像源再试（中国大陆网络常见）"
    npm config set registry https://registry.npmmirror.com --location=user || true
  fi
  npm install -g --foreground-scripts --no-audit --no-fund @deepseek-ai/dsh
fi
unset CMAKE_BUILD_PARALLEL_LEVEL

# 硬性检查：npm 装完必须有 dsh 命令，否则立刻报错
if ! command -v dsh >/dev/null 2>&1; then
  echo ""
  echo "✗✗ 错误: npm 安装结束后仍未找到 dsh 命令 ✗✗"
  echo "   说明上面 npm install 实际失败了（常见原因）："
  echo "   1) 网络黑洞/超时：安装阶段长时间（>15分钟）无任何输出 —— 用 --cn 参数重跑，或确认 VPN/代理"
  echo "   2) 进程被杀：内存不足（OOM） —— 关闭后台应用后重跑"
  echo "   3) 磁盘空间不足 —— 检查: df -h"
  echo "   4) 编译失败 —— 向上翻终端找 \"npm error\" 开头的行，把最后 20 行发到仓库 issue"
  echo "   5) 本脚本幂等，任何一步失败直接重跑即可续上"
  exit 1
fi
ok "dsh 命令已就位: $(command -v dsh)"

# 定位 dsh 安装目录（npm global prefix 可能不同）
D="$(npm root -g)/@deepseek-ai/dsh"
[ -d "$D" ] || { echo "错误: 安装完成后未找到 $D"; exit 1; }

# ---- 5.5 link() -> rename() 补丁（部分系统全局禁用 link() 系统调用）---------
# 症状：会话保存报 EACCES: permission denied, link '...session.jsonl.zstd.tmp' -> '...'
# 方案：把 dsh-session-persistence-jsonl 与 dsh-attachment-local 里的原子发布从 link() 改为 rename()
patch_link_rename() {
  local f patched=0

  f="$D/node_modules/@deepseek-ai/dsh-session-persistence-jsonl/lib/index.js"
  if [ -f "$f" ]; then
    if grep -q "await rename(tmp, finalPath)" "$f"; then
      patched=1
    elif grep -q "await link(tmp, finalPath)" "$f"; then
      python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace(
    'import { link, mkdir, mkdtemp, open, readFile, readdir, realpath, rm, stat, truncate } from "node:fs/promises";',
    'import { link, mkdir, mkdtemp, open, readFile, readdir, realpath, rename, rm, stat, truncate } from "node:fs/promises";',
)
s = s.replace("await link(tmp, finalPath);", "await rename(tmp, finalPath);")
open(p, "w").write(s)
PY
      ok "已修补 $f（link -> rename）"
      patched=1
    fi
  fi

  f="$D/node_modules/@deepseek-ai/dsh-attachment-local/lib/index.js"
  if [ -f "$f" ]; then
    if grep -q "await rename(temporary, target)" "$f"; then
      patched=1
    elif grep -q "await link(temporary, target)" "$f"; then
      python3 - "$f" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace(
    'import { chmod, link, mkdir, open, readFile, unlink } from "node:fs/promises";',
    'import { chmod, link, mkdir, open, readFile, rename, unlink } from "node:fs/promises";',
)
s = s.replace("await link(temporary, target);", "await rename(temporary, target);")
old = "await unlink(temporary);"
new = ('await unlink(temporary).catch((cleanupError) => {\n'
       '\t\t\tif (!(cleanupError instanceof Error && "code" in cleanupError && cleanupError.code === "ENOENT")) throw cleanupError;\n'
       '\t\t});')
idx = s.find(old)
if idx != -1:
    s = s[:idx] + new + s[idx + len(old):]
open(p, "w").write(s)
PY
      ok "已修补 $f（link -> rename）"
      patched=1
    fi
  fi

  [ "$patched" -eq 0 ] && warn "link() 补丁未命中（包结构可能已变化，遇到 EACCES link 报错请发 issue）"
  return 0
}
patch_link_rename

# ---- 6. sharp WebAssembly 兜底（sharp 可能无预编译）--------------------------
SHARP_VER="$(python3 -c "import json;print(json.load(open('$D/node_modules/sharp/package.json'))['version'])" 2>/dev/null || echo "")"
if [ -z "$SHARP_VER" ]; then
  fail "读取 sharp 版本失败（$D/node_modules/sharp/package.json 不存在？）"
  exit 1
fi
log "安装 sharp@$SHARP_VER 的 WebAssembly 兜底 (@img/sharp-wasm32)"

wasm_present() { [ -d "$1" ] && ls "$1"/lib/*.wasm >/dev/null 2>&1; }

if wasm_present "$D/node_modules/@img/sharp-wasm32"; then
  ok "@img/sharp-wasm32 已存在，跳过"
else
  rm -rf "$SWDIR"
  mkdir -p "$SWDIR"
  cd "$SWDIR" || { fail "无法进入 $SWDIR"; exit 1; }
  npm init -y >/dev/null 2>&1 || true
  log "下载 @img/sharp-wasm32@$SHARP_VER ..."
  if ! npm install --no-save --no-audit --no-fund "@img/sharp-wasm32@$SHARP_VER"; then
    warn "官方源安装失败，改用 npmmirror 重试"
    if ! npm install --no-save --no-audit --no-fund --registry=https://registry.npmmirror.com "@img/sharp-wasm32@$SHARP_VER"; then
      fail "@img/sharp-wasm32 下载/安装失败（见上方输出）——请检查网络后重跑本脚本"
      exit 1
    fi
  fi
  if ! wasm_present node_modules/@img/sharp-wasm32; then
    fail "sharp-wasm32 安装结果异常（未找到 lib/*.wasm）"
    exit 1
  fi
  rm -rf "$D/node_modules/@img/sharp-wasm32" "$D/node_modules/@emnapi"
  mkdir -p "$D/node_modules/@img"
  cp -r node_modules/@img/sharp-wasm32 "$D/node_modules/@img/"
  if [ -d node_modules/@emnapi ]; then
    cp -r node_modules/@emnapi "$D/node_modules/"
  fi
  cd "$HOME" || exit 1
  rm -rf "$SWDIR"
  if ! wasm_present "$D/node_modules/@img/sharp-wasm32"; then
    fail "sharp-wasm32 复制到 dsh 失败"
    exit 1
  fi
  ok "sharp wasm 兜底已就位"
fi

# ---- 7. dsh 启动包装器（HMR 插件硬要求 --expose-internals）---------------------
log "安装 dsh 启动包装器（--expose-internals）"
NPM_BIN="$(npm bin -g)"
rm -f "$NPM_BIN/dsh"
cat > "$NPM_BIN/dsh" <<EOF
#!/bin/sh
exec node --expose-internals $D/lib/bin.js "\$@"
EOF
chmod +x "$NPM_BIN/dsh"
ok "包装器已写入 $NPM_BIN/dsh"

# 确保 npm bin 目录在 PATH 中
case ":$PATH:" in
  *":$NPM_BIN:"*) ;;
  *) export PATH="$NPM_BIN:$PATH" ;;
esac

# ---- 8. pnpm（dsh plugin 子命令依赖）------------------------------------------
if ! command -v pnpm >/dev/null 2>&1; then
  log "安装 pnpm（dsh plugin 管理用）"
  npm install -g --no-audit --no-fund pnpm
fi

# ---- 8.5 默认工作区配置 ---------------------------------------------------------
# Alpine 使用标准 Linux 路径，默认工作区设为 ~/dsh-workspace
log "配置默认工作区"
WORKSPACE="${DSH_WORKSPACE:-$HOME/dsh-workspace}"
if [ -n "$WORKSPACE" ]; then
  mkdir -p "$WORKSPACE"
  mkdir -p "$HOME/.dsh/profiles/web"
  PATCH="$HOME/.dsh/profiles/web/cordis.patch.yml"
  if grep -q "id: fs-sandbox" "$PATCH" 2>/dev/null; then
    ok "cordis.patch.yml 已含 fs-sandbox 工作区配置"
  elif [ -s "$PATCH" ] && ! grep -qE '^[[:space:]]*\[\][[:space:]]*$' "$PATCH"; then
    printf '\n- id: fs-sandbox\n  config:\n    cwd: %s\n' "$WORKSPACE" >> "$PATCH"
    ok "已追加 fs-sandbox 工作区配置 -> $WORKSPACE"
  else
    cat > "$PATCH" <<EOF
# dsh profile patch layer (generated by alpine-dsh)
# 默认工作区固定在 $WORKSPACE；如需修改请改下面 cwd，或删除本段恢复默认
- id: fs-sandbox
  config:
    cwd: $WORKSPACE
EOF
    ok "已写入默认工作区配置 -> $WORKSPACE"
  fi
else
  warn "已跳过工作区配置（DSH_WORKSPACE 为空）"
fi

# ---- 9. 验证 --------------------------------------------------------------------
echo ""
echo "==================== 验证 ===================="
FAIL=0
if dsh --version >/dev/null 2>&1; then ok "dsh"; else fail "dsh"; FAIL=1; fi
if (cd "$D" && node --input-type=module -e "await import('koffi')" >/dev/null 2>&1); then
  ok "koffi（原生 FFI 可加载）"
else
  fail "koffi 无法加载"; FAIL=1
fi
if [ -f "$D/node_modules/node-pty/build/Release/pty.node" ]; then
  ok "node-pty（pty.node 已编译）"
else
  fail "node-pty 未编译"; FAIL=1
fi
if (cd "$D" && node --input-type=module -e "const s=(await import('sharp')).default; if(!s.versions)process.exit(1)" >/dev/null 2>&1); then
  ok "sharp（WebAssembly 版可加载）"
else
  fail "sharp 无法加载"; FAIL=1
fi
if [ -d "$WORKSPACE" ]; then
  ok "工作区（$WORKSPACE）已就绪"
else
  warn "工作区不可访问"
fi

echo ""
ELAPSED="$(( $(date +%s) - START_TS ))"
echo "   总耗时: $((ELAPSED / 60)) 分 $((ELAPSED % 60)) 秒"
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "✅ 全部通过！启动方式："
  echo ""
  echo "   dsh web"
  echo ""
  echo "   然后："
  echo "   - 浏览器打开 http://127.0.0.1:3080"
  echo "   - 局域网访问: dsh web --host 0.0.0.0  然后用 http://服务器IP:3080"
  echo ""
  echo "   首次使用请在 Web UI 的 设置 → 模型 里配置 LLM API Key。"
  echo "   默认工作区已固定在 $WORKSPACE"
  echo "   注意：重新 npm 安装 dsh 后，需重跑本脚本恢复 sharp 兜底、启动包装器与工作区配置。"
else
  echo "⚠️ 部分验证未通过，请查看上方 ✗ 项，或到 GitHub 仓库提交 issue。"
  exit 1
fi