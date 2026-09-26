local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

return {
    s("for", {
        t("for (int "),
        i(2, "i"),
        t(" = "),
        i(3, "0"),
        t("; "),
        f(function(args)
            return args[1][1]
        end, { 2 }),
        t(" < "),
        i(4, "n"),
        t("; "),
        f(function(args)
            return args[1][1]
        end, { 2 }),
        t("++) {"),
        t({ "", "    " }),
        i(1),
        t({ "", "}" }),
    }),

    s("forr", {
        t("for (int "),
        i(2, "i"),
        t(" = "),
        i(3, "n - 1"),
        t("; "),
        f(function(args)
            return args[1][1]
        end, { 2 }),
        t(" >= "),
        i(4, "0"),
        t("; "),
        f(function(args)
            return args[1][1]
        end, { 2 }),
        t("--) {"),
        t({ "", "    " }),
        i(1),
        t({ "", "}" }),
    }),

    s("fora", {
        t("for (auto &"),
        i(2, "x"),
        t(" : "),
        i(3, "v"),
        t(") {"),
        t({ "", "    " }),
        i(1),
        t({ "", "}" }),
    }),

    s("vin", {
        t("for (auto &x : "),
        i(1, "a"),
        t(") cin >> x;"),
    }),

    s("vout", {
        t("for (auto &x : "),
        i(1, "a"),
        t([[) cout << x << ' ';]]),
        t({ "", [[cout << '\n';]] }),
    }),

    s("vi", {
        t("vector<int> "),
        i(1, "v"),
        t("("),
        i(2, "n"),
        t(");"),
    }),

    s("vl", {
        t("vector<long long> "),
        i(1, "v"),
        t("("),
        i(2, "n"),
        t(");"),
    }),

    s("vvi", {
        t("vector<vector<"),
        i(1, "int"),
        t(">> "),
        i(2, "a"),
        t("("),
        i(3, "n"),
        t(", vector<"),
        f(function(args)
            return args[1][1]
        end, { 1 }),
        t(">("),
        i(4, "m"),
        t("));"),
    }),

    s("solve", {
        t("auto "),
        i(1, "solve"),
        t(" = [&]("),
        i(2),
        t(") -> "),
        i(3, "void"),
        t(" {"),
        t({ "", "    " }),
        i(0),
        t({ "", "};" }),
    }),

    s("custom", {
        t("auto "),
        i(1, "custom"),
        t(" = [&]("),
        i(2, "int n"),
        t(") -> "),
        i(3, "void"),
        t(" {"),
        t({ "", "    " }),
        i(0),
        t({ "", "};" }),
    }),

    s("dfs", {
        t("auto dfs = [&](auto &&self, int u, int p) -> void {"),
        t({ "", "    for (int v : adj[u]) {" }),
        t({ "", "        if (v == p) continue;" }),
        t({ "", "        " }),
        i(0),
        t({ "", "        self(self, v, u);" }),
        t({ "", "    }" }),
        t({ "", "};" }),
    }),

    s("bfs", {
        t("queue<int> q;"),
        t({ "", "q.push(" }),
        i(1, "s"),
        t(");"),
        t({ "", "vis[" }),
        f(function(args)
            return args[1][1]
        end, { 1 }),
        t("] = true;"),
        t({ "", "" }),
        t({ "", "while (!q.empty()) {" }),
        t({ "", "    int u = q.front();" }),
        t({ "", "    q.pop();" }),
        t({ "", "" }),
        t({ "", "    for (int v : adj[u]) {" }),
        t({ "", "        if (vis[v]) continue;" }),
        t({ "", "        vis[v] = true;" }),
        t({ "", "        q.push(v);" }),
        t({ "", "    }" }),
        t({ "", "}" }),
        i(0),
    }),

    s("pq", {
        t("priority_queue<"),
        i(1, "int"),
        t("> "),
        i(2, "pq"),
        t(";"),
    }),

    s("minpq", {
        t("priority_queue<"),
        i(1, "int"),
        t(", vector<"),
        f(function(args)
            return args[1][1]
        end, { 1 }),
        t(">, greater<"),
        f(function(args)
            return args[1][1]
        end, { 1 }),
        t(">> "),
        i(2, "pq"),
        t(";"),
    }),

    s("minpqp", {
        t("using P = pair<"),
        i(1, "long long"),
        t(", "),
        i(2, "int"),
        t(">;"),
        t({ "", "priority_queue<P, vector<P>, greater<P>> pq;" }),
    }),

    s("dijk", {
        t("using P = pair<long long, int>;"),
        t({ "", "priority_queue<P, vector<P>, greater<P>> pq;" }),
        t({ "", "vector<long long> dist(n, LLONG_MAX);" }),
        t({ "", "" }),
        t({ "", "dist[" }),
        i(1, "s"),
        t("] = 0;"),
        t({ "", "pq.push({0, " }),
        f(function(args)
            return args[1][1]
        end, { 1 }),
        t("});"),
        t({ "", "" }),
        t({ "", "while (!pq.empty()) {" }),
        t({ "", "    auto [d, u] = pq.top();" }),
        t({ "", "    pq.pop();" }),
        t({ "", "" }),
        t({ "", "    if (d != dist[u]) continue;" }),
        t({ "", "" }),
        t({ "", "    for (auto [v, w] : adj[u]) {" }),
        t({ "", "        if (dist[v] > d + w) {" }),
        t({ "", "            dist[v] = d + w;" }),
        t({ "", "            pq.push({dist[v], v});" }),
        t({ "", "        }" }),
        t({ "", "    }" }),
        t({ "", "}" }),
        i(0),
    }),

    s("bs", {
        t("int l = "),
        i(1, "0"),
        t(", r = "),
        i(2, "n - 1"),
        t(";"),
        t({ "", "" }),
        t({ "", "while (l <= r) {" }),
        t({ "", "    int mid = l + (r - l) / 2;" }),
        t({ "", "" }),
        t({ "", "    if (" }),
        i(3, "condition"),
        t(") {"),
        t({ "", "        " }),
        i(4, "r = mid - 1;"),
        t({ "", "    } else {" }),
        t({ "", "        " }),
        i(5, "l = mid + 1;"),
        t({ "", "    }" }),
        t({ "", "}" }),
        i(0),
    }),

    s("bsa", {
        t("long long l = "),
        i(1, "0"),
        t(", r = "),
        i(2, "1e18"),
        t(";"),
        t({ "", "" }),
        t({ "", "while (l < r) {" }),
        t({ "", "    long long mid = l + (r - l) / 2;" }),
        t({ "", "    if (" }),
        i(3, "ok(mid)"),
        t(") r = mid;"),
        t({ "", "    else l = mid + 1;" }),
        t({ "", "}" }),
        i(0),
    }),

    s("gcd", {
        t("gcd("),
        i(1, "a"),
        t(", "),
        i(2, "b"),
        t(")"),
    }),

    s("fastpow", {
        t("auto fast_pow = [](long long a, long long e, long long mod) {"),
        t({ "", "    long long res = 1;" }),
        t({ "", "    while (e) {" }),
        t({ "", "        if (e & 1) res = res * a % mod;" }),
        t({ "", "        a = a * a % mod;" }),
        t({ "", "        e >>= 1;" }),
        t({ "", "    }" }),
        t({ "", "    return res;" }),
        t({ "", "};" }),
    }),
}
