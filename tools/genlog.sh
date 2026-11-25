#!/usr/bin/env bash
# tools/genlog.sh —— 生成 10 万行 nginx combined 样例日志（12 段，时间递增，结果可复现）
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=data/logs/access.log
if [[ -f "$OUT" ]]; then
    echo "已存在 $OUT，要重生成先 rm -f $OUT"
    exit 1
fi
mkdir -p data/logs

awk '
function rnd() { s = (16807 * s) % 2147483647; return s / 2147483647 }
BEGIN {
  s = 20261123
  split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", MN, " ")
  split("/ /index.html /login /search /static/css/app.css /static/js/app.js /static/js/vendor.js /static/img/logo.png /api/list /api/detail /api/save /api/upload /course/list /course/detail /download/report.pdf /favicon.ico /news", P, " ")
  split("10 12 6 5 8 9 6 5 8 7 3 2 5 4 3 4 3", PW, " ")
  split("3 2 2 2 2 2 3 6 8 12 18 19 10 9 11 12 13 12 14 18 19 17 9 5", W, " ")
  N = 17
  for (i = 1; i <= N; i++) { TP += PW[i]; CP[i] = TP }
  for (h = 0; h < 24; h++) TW += W[h + 1]

  for (d = 0; d < 7; d++)
    for (h = 0; h < 24; h++) {
      c[d, h] = int(100000 * W[h + 1] / (TW * 7))
      used += c[d, h]
    }
  rest = 100000 - used
  for (d = 0; rest > 0; d++)
    for (h = 0; h < 24 && rest > 0; h++) { c[d, h]++; rest-- }

  for (i = 0; i < 800; i++)
    IP[i] = "10." (int(i / 100) + 1) "." (int(i % 100 / 10)) "." (i % 10 + 1)

  UA[0] = "\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36\""
  UA[1] = "\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15\""
  UA[2] = "\"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36\""
  UA[3] = "\"Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148\""
  UA[4] = "\"curl/8.4.0\""

  for (d = 0; d < 7; d++) {
    day = 17 + d
    for (h = 0; h < 24; h++) {
      cnt = c[d, h]
      step = cnt > 0 ? 3600 / cnt : 3600
      for (i = 0; i < cnt; i++) {
        t = int(i * step) + int(rnd() * step)
        if (t > 3599) t = 3599

        ip = (rnd() < 0.3) ? IP[int(rnd() * 6) * 5] : IP[int(rnd() * 800)]

        r = rnd() * TP
        k = 1
        while (k < N && r > CP[k]) k++
        u = P[k]
        if (rnd() < 0.15 && (u ~ /detail$/ || u ~ /list$/)) u = u "?page=" (1 + int(rnd() * 5))

        r = rnd()
        if (u ~ /^\/api\//) st = (r < 0.82) ? 200 : (r < 0.92 ? 500 : (r < 0.97 ? 502 : 302))
        else                st = (r < 0.88) ? 200 : (r < 0.93 ? 302 : (r < 0.99 ? 404 : 503))

        by = (st == 200) ? 180 + int(rnd() * 9000) : int(rnd() * 300)
        rf = (rnd() < 0.8) ? "\"-\"" : "\"http://course.example.edu/index.html\""

        r = rnd()
        agent = UA[r < 0.5 ? 0 : (r < 0.7 ? 1 : (r < 0.9 ? 2 : (r < 0.97 ? 3 : 4)))]

        printf "%s - - [%02d/%s/2026:%02d:%02d:%02d +0800] \"GET %s HTTP/1.1\" %d %d %s %s\n", ip, day, MN[11], h, int(t / 60), t % 60, u, st, by, rf, agent
      }
    }
  }
}' > "$OUT"

echo "生成完成：$OUT  $(wc -l < "$OUT") 行"
