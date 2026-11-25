set -euo pipefail

cd "$(dirname "$0")"

log() { printf '[%s] %s\n' "$(date +%T)" "$*"; }
die() { printf '[%s] 错误: %s\n' "$(date +%T)" "$*" >&2; exit 1; }
command -v git >/dev/null 2>&1 || die "缺少 git，请先安装"
command -v awk >/dev/null 2>&1 || die "缺少 awk，请先安装"

if [[ -d .git ]]; then
    die "当前目录已经是 git 仓库（存在 .git）。本脚本只用于首次初始化，请换一个空目录。"
fi
[[ -f tools/genlog.sh ]] || die "缺少 tools/genlog.sh —— 本脚本要求两个文件同时就位，请先放好再跑。"
mkdir -p data/logs out conf tools
: >data/logs/.gitkeep
: >out/.gitkeep
log "步骤 1/6 目录骨架就绪：data/logs  out  conf  tools"
cat >.gitignore <<'EOF'
.env
out/*
!out/.gitkeep
data/logs/*
!data/logs/.gitkeep
!data/logs/access.log
.DS_Store
Thumbs.db
EOF
cat >.gitattributes <<'EOF'
* text=auto eol=lf
*.sh text eol=lf
*.png binary
*.jpg binary
*.pdf binary
EOF

log "步骤 2/6 .gitignore / .gitattributes 已写入"
if ! git init -q -b main 2>/dev/null; then
    git init -q
fi

if [[ -z "$(git config --get user.name || true)" ]]; then
    if [[ -n "${GIT_USER_NAME:-}" && -n "${GIT_USER_EMAIL:-}" ]]; then
        git config --local user.name "$GIT_USER_NAME"
        git config --local user.email "$GIT_USER_EMAIL"
        log "  已写入本仓库 git 身份：$GIT_USER_NAME <$GIT_USER_EMAIL>"
    else
        die "未配置 git 身份。请先执行：
  git config --global user.name  \"你的名字\"
  git config --global user.email \"你的邮箱\"
或者用环境变量跑本脚本：
  GIT_USER_NAME=\"你的名字\" GIT_USER_EMAIL=\"你的邮箱\" bash setup_repo.sh"
    fi
fi

git add .gitignore .gitattributes data/logs/.gitkeep out/.gitkeep
git commit -q -m "chore: 初始化 logops 仓库骨架与目录结构（对应文档 4.1）"
log "步骤 3/6 骨架提交完成：$(git rev-parse --short HEAD)"
chmod +x tools/genlog.sh
[[ -f setup_repo.sh ]] && chmod +x setup_repo.sh

if [[ -f setup_repo.sh ]]; then
    git add tools/genlog.sh setup_repo.sh
else
    git add tools/genlog.sh
fi
git commit -q -m "feat(tools): 样例日志生成器（固定种子可复现）与仓库初始化脚本"
log "步骤 4/6 生成器提交完成：$(git rev-parse --short HEAD)"

log "步骤 5/6 生成 10 万行样例日志（Linux 约 1 秒）"
./tools/genlog.sh
if git check-ignore -q data/logs/access.log; then
    die "data/logs/access.log 被 .gitignore 忽略了。检查规则顺序：!data/logs/access.log 必须在 data/logs/* 之后。"
fi

lines=$(wc -l <data/logs/access.log | tr -d ' ')
[[ "$lines" = "100000" ]] || die "行数不是 100000，实际为 $lines"

git add data/logs/access.log
git commit -q -m "data: 10 万行样例访问日志（12 段 combined，时间递增）"
log "步骤 6/6 数据提交完成：$(git rev-parse --short HEAD)"

printf '\n===== 仓库就绪 =====\n'
git log --oneline
printf '\n工作区状态（应为空）:\n'
git status --short || true
printf '\n样例日志: %s 行, %s\n' "$lines" "$(du -h data/logs/access.log | awk '{ print $1 }')"
printf '\n下一步：\n'
printf '  1. 建远端仓库并推送：git remote add origin <url> && git push -u origin main\n'
printf '  2. 给每个组员开分支：git checkout -b feature/m1-init\n'
printf '  3. 把「命名规定」那段贴进 README 顶部，作为唯一契约\n'
