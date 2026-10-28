#!/usr/bin/env python3
"""Generates the hover documentation of the language server from the official sources.

- eventb.tsv: the operator tables of the Rodin Handbook's chapter on the
  mathematical notation, with each operator's description and
  well-definedness condition.
- classical.tsv: ProB's "Summary of B Syntax".

Each line is: key, title, description, details, link, source, and "1" if
the key names the entry rather than being part of it (tab-separated).

Usage: python3 generate.py   (writes the files next to this script)
"""

import html
import os
import re
import urllib.request

HANDBOOK = "https://www3.hhu.de/stups/handbook/rodin/current/html/"
SYNTAX = "https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax"
HERE = os.path.dirname(os.path.abspath(__file__))


def fetch(url):
    with urllib.request.urlopen(url) as response:
        return response.read().decode("utf-8")


# ---------------------------------------------------------------------------
# LaTeX as used in the handbook, to Unicode

MACROS = {
    "in": "∈", "notin": "∉", "land": "∧", "lor": "∨", "lnot": "¬", "neg": "¬",
    "Rightarrow": "⇒", "Leftrightarrow": "⇔", "forall": "∀", "exists": "∃",
    "top": "⊤", "bot": "⊥", "neq": "≠", "leq": "≤", "geq": "≥", "le": "≤", "ge": "≥",
    "subseteq": "⊆", "subset": "⊂", "not": "¬", "cup": "∪", "cap": "∩", "setminus": "∖",
    "emptyset": "∅", "bigcup": "⋃", "bigcap": "⋂", "times": "×", "mapsto": "↦",
    "leftrightarrow": "↔", "rightarrow": "→", "leftarrow": "←", "twoheadrightarrow": "↠",
    "rightarrowtail": "↣", "circ": "∘", "otimes": "⊗", "lhd": "◁", "rhd": "▷",
    "lambda": "λ", "alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ",
    "cdot": "·", "ldots": "…", "div": "÷", "bmod": "mod", "mid": "∣", "min": "min", "max": "max",
    "Box": "□", "quad": " ", "enskip": " ", "mathcal": "", "widehat": "",
}

SYMBOLS = {
    r"\mathbb N": "ℕ", r"\mathbb Z": "ℤ", r"\mathbb P": "ℙ",
}


def latex(text):
    """Turns the handbook's LaTeX into readable Unicode text."""
    text = html.unescape(text)
    # Composite arrows, drawn from several symbols.
    text = re.sub(r"\\rightarrowtail\s*(?:\\mkern\s*-?[0-9.]+mu\s*)*\\twoheadrightarrow", "⤖", text)
    gap = r"\s*(?:\\mkern\s*-?[0-9.]+mu\s*)*"
    text = re.sub(r"\\mapstochar" + gap + r"\\rightarrowtail", "⤔", text)
    text = re.sub(r"\\mapstochar" + gap + r"\\twoheadrightarrow", "⤀", text)
    text = re.sub(r"\\mapstochar" + gap + r"\\rightarrow", "⇸", text)
    text = re.sub(r"\\mathcal\{L\}", "L", text)
    # Set braces survive; grouping braces do not.
    text = text.replace("\\{", "\x01").replace("\\}", "\x02")
    text = re.sub(r"\\mathrel\s*\{\\widehat=\}", "≙", text)
    text = re.sub(r"\\widehat=", "≙", text)
    text = re.sub(r"\\mathbin\s*\{\.\\mkern\s*1mu\.\}", "‥", text)
    text = re.sub(r"\\mathbin\s*\{\\widehat\{\\enskip\s*\}\}", "^", text)
    text = re.sub(r"\\mathbb\s*\{?([NZP])\}?", lambda m: SYMBOLS["\\mathbb " + m.group(1)], text)
    text = re.sub(r"\\mathbb\s*\{?([NZP])\}?1", lambda m: SYMBOLS["\\mathbb " + m.group(1)] + "1", text)
    text = re.sub(r"\\mkern\s*-?[0-9.]+mu", "", text)
    text = re.sub(r"\\raisebox\{[^}]*\}", "", text)
    text = re.sub(r"\\(?:hbox|mbox)\{\}", "", text)
    text = re.sub(r"\\not\s*\\in", "∉", text)
    text = re.sub(r"\\not\s*\\subseteq", "⊈", text)
    text = re.sub(r"\\not\s*\\subset", "⊄", text)
    text = re.sub(r"\\mapstochar\s*\\rightarrow", "⇸", text)
    text = re.sub(r"\\(textsf|textsl|textit|mathrm|mathsf|ensuremath|mathop|mathbin|mathrel|mathord|nolimits)\b", "", text)
    text = re.sub(r"\\([A-Za-z]+)", lambda m: MACROS.get(m.group(1), ""), text)
    text = text.replace("$", "").replace("{", "").replace("}", "").replace("~", " ")
    text = text.replace("\x01", "{").replace("\x02", "}")
    text = re.sub(r"\\[,;! ]", " ", text)
    text = text.replace("\\", "")
    text = re.sub(r"\s*_\s*([0-9A-Za-z])", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def plain(fragment):
    """Text of an HTML fragment, with line breaks kept as ' ; '."""
    fragment = re.sub(r"<br\s*/?>", "\n", fragment)
    fragment = re.sub(r"</p>\s*<p>", "\n", fragment)
    fragment = re.sub(r"<[^>]+>", "", fragment)
    lines = [latex(line) for line in fragment.split("\n")]
    return " — ".join(line for line in lines if line)


# ---------------------------------------------------------------------------
# Rodin Handbook

# Separates the details of an entry; "|" occurs in the formulas.
DETAILS = " \u2016 "

PAGES = ["predicates", "booleans", "sets", "relations", "arithmetic", "typing", "assignments"]


def keyboard():
    """Rodin's keyboard table (lua/prob/symbols.lua): ASCII combination to symbol."""
    path = os.path.join(HERE, "..", "..", "..", "lua", "prob", "symbols.lua")
    table = {}
    for combo, symbol in re.findall(r"\{ '((?:[^'\\]|\\.)*)', '((?:[^'\\]|\\.)*)'", open(path, encoding="utf-8").read()):
        combo = combo.replace("\\\\", "\\")
        symbol = re.sub(r"\\u\{([0-9A-Fa-f]+)\}", lambda m: chr(int(m.group(1), 16)), symbol)
        table.setdefault(combo, symbol)
    return table


def handbook():
    rows = []
    symbols = keyboard()
    for page in PAGES:
        source = fetch(HANDBOOK + page + ".html")
        # Formulas are images whose alt text is their LaTeX source.
        source = re.sub(r'<img[^>]*alt="([^"]*)"[^>]*>', lambda m: m.group(1).replace("<", "&lt;"), source)
        # Each section starts with a heading; its operators are in a table followed by a description list.
        for section in re.split(r"(?=<h[234] id=)", source):
            heading = re.match(r'<h[234] id="([^"]+)">([^<]+)</h[234]>', section)
            if not heading:
                continue
            anchor, title = heading.group(1), html.unescape(heading.group(2)).strip()
            link = f"{HANDBOOK}{page}.html#{anchor}"
            where = f"Rodin Handbook, {title}"
            fields = dict(
                (latex(re.sub(r"<[^>]+>", "", dt)), plain(dd))
                for dt, dd in re.findall(r"<dt>(.*?)</dt>\s*<dd>(.*?)</dd>", section, re.S)
            )
            for table in re.findall(r'<table class="tabular".*?</table>', section, re.S):
                for row in re.findall(r"<tr>(.*?)</tr>", table, re.S):
                    cells = [c for c in re.findall(r"<td[^>]*>(.*?)</td>", row, re.S)]
                    if len(cells) < 3:
                        continue
                    symbol = latex(re.sub(r"<[^>]+>", "", cells[0]))
                    # The HTML renders "--" as an en dash.
                    ascii_ = html.unescape(re.sub(r"<[^>]+>", "", cells[1])).strip().replace("–", "--")
                    name = latex(re.sub(r"<[^>]+>", "", cells[2]))
                    if not name:
                        continue
                    details = []
                    if ascii_:
                        details.append(f"ASCII: `{ascii_}`")
                    for field in ("Definition", "Types", "WD", "Example"):
                        if fields.get(field):
                            details.append(f"{field}: {fields[field]}")
                    description = fields.get("Description", "")
                    # Rodin's symbol for the ASCII input; the LaTeX only approximates some arrows.
                    symbol = symbols.get(ascii_, symbol)
                    for key in dict.fromkeys([symbol, ascii_]):
                        if key and " " not in key and "$" not in key and not re.fullmatch(r"[A-Za-z]|exprs|\{.*\}.+|\{(?:exprs|E\|P|ids\..*)\}|…|\(…\)|\[…\]", key):
                            rows.append((key, name, description, DETAILS.join(details), link, where, "1"))
    return rows


# ---------------------------------------------------------------------------
# ProB's Summary of B Syntax

PLACEHOLDER = re.compile(r"^(?:[A-Za-z]|[A-Za-z][0-9n]|ID|tl|tr|Dom|Ran|Pair|OP|BODY|NAME[0-9]?|LBL|DESC|PATH|PRAGMA|VALUE|SETNAME|OPNAME|FILE|Expression|E[0-9n]?|G[0-9n]?|P[0-9n]?|x[0-9n]?|r[0-9]|ss|cx|cy|cv|cw|e[0-9]|x[0-9]|astring|tstring|Expr)$")


LOWERCASE_WORDS = {"mod", "or", "not", "btrue", "bfalse", "skip"}


def keys_of(syntax):
    """The keywords, built-in functions and operators of an entry's syntax."""
    keys = []
    for alternative in re.split(r"\s+or\s+", re.sub(r'"[^"]*"', "", syntax)):
        for word in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", alternative):
            keyword = re.fullmatch(r"[A-Z][A-Z0-9_]+", word) is not None
            function = re.search(re.escape(word) + r"\(", alternative) is not None and word[0].islower()
            if PLACEHOLDER.match(word) or not (keyword or function or word in LOWERCASE_WORDS):
                continue
            if word not in keys:
                keys.append(word)
        for operator in re.findall(r"[^\sA-Za-z0-9_(),.\[\]{}'\"`$]+", alternative):
            if operator not in keys and operator not in ("...", "…", "_", "•"):
                keys.append(operator)
    return keys


# Sections of explanations rather than syntax.
PROSE = {"Differences with AtelierB/B4Free", "Other notes", "Free Types", "Event-B Syntax", "Comments and Pragmas"}


def syntax_summary():
    rows = []
    raw = fetch(SYNTAX + "&action=raw")
    section = "Summary of B Syntax"
    in_pre = False
    for line in raw.splitlines():
        heading = re.match(r"^===\s*(.+?)\s*===\s*$", line)
        if heading:
            section = heading.group(1)
            continue
        if "<pre>" in line:
            in_pre = True
            line = line.split("<pre>", 1)[1]
        if "</pre>" in line:
            in_pre = False
            continue
        if not in_pre or section in PROSE or not line.strip() or not line.startswith(" ") or line.startswith("  " * 6):
            continue
        parts = re.split(r"\s{2,}", line.strip(), maxsplit=1)
        syntax = parts[0]
        description = parts[1] if len(parts) > 1 else ""
        # Machine sections have three columns: keyword, its argument, a description in parentheses.
        if section == "Machine sections":
            argument = re.split(r"\s{2,}", description, maxsplit=1)
            syntax = f"{syntax} {argument[0]}"
            description = argument[1].strip("()") if len(argument) == 2 else ""
        if syntax.startswith("-"):
            continue
        link = SYNTAX + "#" + section.replace(" ", "_")
        where = f"ProB, Summary of B Syntax: {section}"
        keys = keys_of(syntax)
        for key in keys:
            # The first key names the construct; THEN in IF … THEN … END does not.
            rows.append((key, syntax, description, "", link, where, "1" if key == keys[0] else ""))
    return rows


def write(name, rows):
    with open(os.path.join(HERE, name), "w", encoding="utf-8") as out:
        for row in rows:
            out.write("\t".join(field.replace("\t", " ").replace("\n", " ") for field in row) + "\n")


if __name__ == "__main__":
    write("eventb.tsv", handbook())
    write("classical.tsv", syntax_summary())
