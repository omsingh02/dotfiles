local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt

-- Load standard community snippets from friendly-snippets
pcall(function()
  require("luasnip.loaders.from_vscode").lazy_load()
end)

-- Helper: get filename without extension for Java class name
local function get_filename(_, _)
  local name = vim.fn.expand("%:t:r")
  if name == "" then
    return "Main"
  end
  return name
end

-- =============================================================================
-- JAVA SNIPPETS
-- =============================================================================
ls.add_snippets("java", {
  -- imp: import statement
  s("imp", fmt("import {};", { i(1, "java.util.*") })),

  -- impu: quick import java.util.*
  s("impu", t("import java.util.*;")),

  -- impi: quick import java.io.*
  s("impi", t("import java.io.*;")),

  -- sout: System.out.println
  s("sout", fmt("System.out.println({});", { i(1) })),

  -- souf: System.out.printf
  s("souf", fmt([[System.out.printf("{}\n", {});]], { i(1), i(2) })),

  -- psvm: public static void main
  s("psvm", fmt([[
public static void main(String[] args) {{
    {}
}}
]], { i(1) })),

  -- main: alias for psvm
  s("main", fmt([[
public static void main(String[] args) {{
    {}
}}
]], { i(1) })),

  -- fori: indexed for loop
  s("fori", fmt([[
for (int {} = 0; {} < {}; {}++) {{
    {}
}}
]], {
    i(1, "i"),
    f(function(args) return args[1][1] end, { 1 }),
    i(2, "n"),
    f(function(args) return args[1][1] end, { 1 }),
    i(0),
  })),

  -- fore: enhanced for-each loop
  s("fore", fmt([[
for ({} {} : {}) {{
    {}
}}
]], { i(1, "var"), i(2, "item"), i(3, "items"), i(0) })),

  -- scan: Scanner initialization
  s("scan", fmt("Scanner {} = new Scanner(System.in);", { i(1, "sc") })),

  -- cls: Standalone Class with main method (auto-named after file)
  s("cls", fmt([[
import java.util.*;

public class {} {{
    public static void main(String[] args) {{
        Scanner sc = new Scanner(System.in);
        {}
    }}
}}
]], { f(get_filename, {}), i(0) })),

  -- fastio: Fast I/O Template for DSA / Competitive Programming
  s("fastio", fmt([[
import java.io.*;
import java.util.*;

public class {} {{
    static class FastScanner {{
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        StringTokenizer st = new StringTokenizer("");
        String next() throws IOException {{
            while (!st.hasMoreTokens()) st = new StringTokenizer(br.readLine());
            return st.nextToken();
        }}
        int nextInt() throws IOException {{ return Integer.parseInt(next()); }}
        long nextLong() throws IOException {{ return Long.parseLong(next()); }}
        double nextDouble() throws IOException {{ return Double.parseDouble(next()); }}
    }}

    public static void main(String[] args) throws IOException {{
        FastScanner sc = new FastScanner();
        PrintWriter out = new PrintWriter(System.out);
        {}
        out.flush();
    }}
}}
]], { f(get_filename, {}), i(0) })),
})

-- =============================================================================
-- C & CPP SNIPPETS
-- =============================================================================
local cpp_c_snippets = {
  -- inc: #include <...>
  s("inc", fmt("#include <{}>", { i(1, "stdio.h") })),

  -- main: int main()
  s("main", fmt([[
int main() {{
    {}
    return 0;
}}
]], { i(0) })),

  -- fori: indexed for loop
  s("fori", fmt([[
for (int {} = 0; {} < {}; ++{}) {{
    {}
}}
]], {
    i(1, "i"),
    f(function(args) return args[1][1] end, { 1 }),
    i(2, "n"),
    f(function(args) return args[1][1] end, { 1 }),
    i(0),
  })),
}

ls.add_snippets("c", cpp_c_snippets)

local cpp_only_snippets = {
  -- incc: #include <iostream>
  s("incc", t("#include <iostream>")),

  -- incbits: #include <bits/stdc++.h>
  s("incbits", t("#include <bits/stdc++.h>")),

  -- cout: std::cout
  s("cout", fmt([[cout << {} << "\n";]], { i(1) })),

  -- cin: std::cin
  s("cin", fmt("cin >> {};", { i(1) })),

  -- vec: std::vector
  s("vec", fmt("vector<{}> {}({});", { i(1, "int"), i(2, "arr"), i(3) })),

  -- cp / dsa: Competitive Programming / DSA C++20 boilerplate
  s("cp", fmt([[
#include <bits/stdc++.h>
using namespace std;

void solve() {{
    {}
}}

int main() {{
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    int t = 1;
    // cin >> t;
    while (t--) {{
        solve();
    }}

    return 0;
}}
]], { i(0) })),

  s("dsa", fmt([[
#include <bits/stdc++.h>
using namespace std;

int main() {{
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    {}

    return 0;
}}
]], { i(0) })),
}

-- Add combined C and C++ snippets for cpp filetype
local all_cpp = {}
for _, snip in ipairs(cpp_c_snippets) do table.insert(all_cpp, snip) end
for _, snip in ipairs(cpp_only_snippets) do table.insert(all_cpp, snip) end
ls.add_snippets("cpp", all_cpp)

-- =============================================================================
-- SQL SNIPPETS
-- =============================================================================
ls.add_snippets("sql", {
  -- sel: SELECT statement
  s("sel", fmt("SELECT {} FROM {} WHERE {};", { i(1, "*"), i(2, "table_name"), i(3, "1=1") })),

  -- ins: INSERT statement
  s("ins", fmt("INSERT INTO {} ({}) VALUES ({});", { i(1, "table_name"), i(2, "cols"), i(3, "vals") })),

  -- upd: UPDATE statement
  s("upd", fmt("UPDATE {} SET {} = {} WHERE {};", { i(1, "table_name"), i(2, "col"), i(3, "val"), i(4, "condition") })),

  -- del: DELETE statement
  s("del", fmt("DELETE FROM {} WHERE {};", { i(1, "table_name"), i(2, "condition") })),

  -- crt: CREATE TABLE statement
  s("crt", fmt([[
CREATE TABLE IF NOT EXISTS {} (
    id INT PRIMARY KEY AUTO_INCREMENT,
    {}
);
]], { i(1, "table_name"), i(0) })),

  -- join: INNER JOIN
  s("join", fmt("INNER JOIN {} ON {}.{} = {}.{}", {
    i(1, "other_table"),
    i(2, "t1"),
    i(3, "id"),
    f(function(args) return args[1][1] end, { 1 }),
    i(4, "other_id"),
  })),
})

return true
