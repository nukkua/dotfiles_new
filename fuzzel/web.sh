#!/usr/bin/env python3
# ponytail: CDP-powered Brave tab switcher + bookmarks via rofi
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

BOOKMARKS = """\
youtube → https://www.youtube.com/
github → https://github.com/
netflix → https://www.netflix.com/
chatgpt → https://chatgpt.com/
monkeytype → https://monkeytype.com/
meet → https://meet.google.com/
whatsapp → https://web.whatsapp.com/
firebase-klubo → https://console.firebase.google.com/project/klubo-7dd7d/overview
reservations-prod → https://reservas.klubo.mobi/
reservations-pr → https://github.com/KLUBOMOBI/klubo-reservations/pulls
admin-pr → https://github.com/KLUBOMOBI/klubo-admin-v2/pulls
reservations-local → http://localhost:9001
admin-local → http://localhost:9000
facebook → http://facebook.com
futbol-libre → https://search.brave.com/search?q=futbollibre
"""

CDP = "http://localhost:9222"
BRAVE = ["brave-origin", "--force-device-scale-factor=1.27"]
ROFI_THEME = os.path.expanduser("~/.config/rofi/sakura.rasi")


def cdp_json(path):
    try:
        with urllib.request.urlopen(f"{CDP}{path}", timeout=0.4) as r:
            return json.loads(r.read().decode())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return None


def get_tabs():
    data = cdp_json("/json/list")
    if not data:
        return []
    return [t for t in data if t.get("type") in ("page", None)]


def activate_tab(tab_id):
    return cdp_json(f"/json/activate/{tab_id}") is not None


def open_tab(url):
    return cdp_json(f"/json/new?{url}") is not None


def focus_brave():
    subprocess.run(["hyprctl", "dispatch", "focuswindow", "class:brave-origin"],
                   capture_output=True)
    subprocess.run(["hyprctl", "dispatch", "bringactivetotop"],
                   capture_output=True)


def brave_fallback(url):
    subprocess.run(BRAVE + [url])


def rofi(lines, prompt=" "):
    cmd = [
        "rofi", "-dmenu",
        "-theme", ROFI_THEME,
        "-p", prompt,
        "-matching", "fuzzy",
        "-sort",
        "-sorting-method", "fzf",
        "-i",
        "-format", "s",
        "-kb-custom-1", "Control+q",
    ]
    proc = subprocess.run(cmd, input="\n".join(lines) + "\n",
                          capture_output=True, text=True)
    out = proc.stdout.strip()
    # custom-1 (Ctrl+q) returns exit code 10
    close_requested = (proc.returncode == 10)
    return out, close_requested


def main():
    tabs_only = "--tabs-only" in sys.argv
    tabs = get_tabs()

    active_id = None
    for t in tabs:
        if t.get("type") == "page" and t.get("url"):
            active_id = t.get("id")
            break

    bookmark_lines = BOOKMARKS.strip().splitlines()
    bm_keywords = []
    for bm in bookmark_lines:
        if " → " not in bm:
            continue
        label, target = bm.split(" → ", 1)
        domain = target.split("/")[2] if "://" in target else target
        bm_keywords.append((domain, target, bm))

    import re
    notify_re = re.compile(r"^\(\d+\)\s+")

    tab_entries = []
    for t in tabs:
        raw_title = t.get("title") or t.get("url") or "untitled"
        title = notify_re.sub("", raw_title).strip()
        tid = t.get("id")
        url = t.get("url", "")
        is_active = t.get("type") == "page" and tid == active_id
        if not tid:
            continue
        tab_entries.append((title, tid, url, is_active))

    matched_tabs = []
    rest_tabs = []
    for title, tid, url, is_active in tab_entries:
        for domain, target, bm in bm_keywords:
            if domain in url or target == url:
                matched_tabs.append((title, tid, url, is_active))
                break
        else:
            rest_tabs.append((title, tid, url, is_active))

    items = []  # (display_text, kind, payload)

    # live tabs first
    seen = set()
    for title, tid, url, is_active in matched_tabs + rest_tabs:
        if tid in seen:
            continue
        seen.add(tid)
        prefix = "ACTIVE " if is_active else "OPEN "
        items.append((f"{prefix}{title}", "tab", tid))

    # then bookmarks
    if not tabs_only:
        for bm in bookmark_lines:
            items.append((bm, "bookmark", bm.split(" → ")[-1]))

    if not items:
        return

    lines = [it[0] for it in items]
    display_to_item = {it[0]: it for it in items}
    prompt = "tabs " if tabs_only else " "
    selection, close_requested = rofi(lines, prompt=prompt)
    if not selection:
        return

    # user picked an existing row
    if selection in display_to_item:
        kind, payload = display_to_item[selection][1], display_to_item[selection][2]
        if kind == "tab":
            if close_requested:
                cdp_json(f"/json/close/{payload}")
            else:
                if activate_tab(payload):
                    focus_brave()
            return
        # bookmark
        url = payload.strip()
    else:
        # user typed something not in the list
        url = selection.strip()

    if not (url.startswith("http://") or url.startswith("https://") or "." in url):
        url = f"https://search.brave.com/search?q={url.replace(' ', '+')}"

    for t in tabs:
        if url == t.get("url") or url in (t.get("url") or ""):
            if activate_tab(t.get("id")):
                focus_brave()
                return

    if not open_tab(url):
        brave_fallback(url)


if __name__ == "__main__":
    main()
