# logops —— 基于 Shell 与 Docker 的日志分析服务

三条命令跑完全流程：

    git clone <url> && cd logops
    ./init.sh
    ./analyze.sh --log data/logs/access.log --top 10 --out out
    ./deploy.sh

访问 http://127.0.0.1:8080/ ，报告在 /report/ 。

## 命名规定（唯一契约：改动先商量，先改本节再动代码）

- 目录：data/logs/  out/  conf/
- 输入：data/logs/access.log（唯一，cron 与 deploy 都写死此名）
- 产物：out/report.md  out/summary.csv
- 脚本：init.sh  analyze.sh  check.sh  deploy.sh（名字固定）
- .env：WEB_PORT=8080  TZ  DB_PASSWORD  DISK_THRESHOLD=80  MEM_THRESHOLD=90  HEALTH_TIMEOUT=120
- 告警文件：out/alert.log
- 退出码：0 成功 / 1 运行期错误 / 2 参数错误
- 服务名：web；端口 8080；挂载 /var/log/nginx 与 /usr/share/nginx/html/report
- 停容器：docker compose stop web

## 日志格式（12 段 combined）

脚本只读 $1(IP) $4(时间) $7(URL) $9(状态码)，前 9 段位置不能动。
时间必须用 $time_local（带方括号），不能用 $time_iso8601，否则按小时统计整列归零。
URL 禁空格；UA 可含空格但必须最后一列；末行必须有换行。
唯一性自检：行数 = 各状态码次数之和 = 各小时次数之和。

## 分工

- 甲（组长）：日志 + M1
- 乙：M2 + M5deploy
- 丙：M3 + M4
- 丁：M5check + 报告 + PPT
