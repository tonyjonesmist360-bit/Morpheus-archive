import re, os, subprocess, collections, json
ROOT='resources'; F=collections.defaultdict(list)
def find(sev,r,m): F[sev].append((r,m))
res={}
for grp in sorted(os.listdir(ROOT)):
    for r in sorted(os.listdir(os.path.join(ROOT,grp))):
        p=os.path.join(ROOT,grp,r)
        if not os.path.isdir(p): continue
        files={}
        for dp,_,fs in os.walk(p):
            for f in fs:
                rel=os.path.relpath(os.path.join(dp,f),p).replace('\\','/'); files[rel]=open(os.path.join(dp,f),encoding='utf-8',errors='replace').read()
        res[r]={'group':grp,'files':files}
lua=lambda r: [(rel,c) for rel,c in res[r]['files'].items() if rel.endswith('.lua') and not rel.startswith('data/')]
alltext=' '.join(c for r in res for _,c in lua(r))

# ── A. command collisions ──
cmds=collections.defaultdict(set)
for r in res:
    for rel,c in lua(r):
        for n in re.findall(r"RegisterCommand\(\s*'([^']+)'",c): cmds[n].add(r)
        if re.search(r"for id in pairs\(EmoteCfg\.Emotes\) do RegisterCommand\(id",c):
            for n in re.findall(r"^\s{4}([a-z]+)\s*=\s*\{\s*label",res[r]['files'].get('shared/emotes.lua',''),re.M): cmds[n].add(r+' (dynamic)')
        if re.search(r"for name, fn in pairs\(cmds\) do\s*RegisterCommand\(name",c):
            for n in re.findall(r"^\s{2}(ob_\w+)\s*=\s*function",c,re.M): cmds[n].add(r+' (dynamic)')
for n,rs in cmds.items():
    if len(rs)>1: find('ERROR','*',f"command '{n}' registered in {sorted(rs)} (collision)")
# keymappings outside binds
for r in res:
    for rel,c in lua(r):
        if 'RegisterKeyMapping(' in c and r!='outbreak_binds': find('WARN',r,f'{rel} registers key mappings (binds is the only owner)')
# bound commands exist
for n in re.findall(r"bind\('([^']+)'",res['outbreak_binds']['files']['client/binds.lua']):
    if n not in cmds and n not in ('inv',): find('ERROR','outbreak_binds',f"binds '{n}' but no RegisterCommand anywhere")

# ── B. items referenced vs defined ──
snippet=res['outbreak_items']['files']['data/ox_items_snippet.lua']
defined=set(re.findall(r"^\['([^']+)'\]",snippet,re.M))
wsnip=res['outbreak_weapons']['files']['data/weapons_snippet.lua']; defined|=set(re.findall(r"\['([^']+)'\]",wsnip))
OX_DEFAULT={'ammo-9','ammo-rifle','ammo-shotgun','ammo-44','ammo-sniper','ammo-flare','ammo-grenadelauncher','WEAPON_PISTOL','WEAPON_REVOLVER','WEAPON_PUMPSHOTGUN','WEAPON_CARBINERIFLE','WEAPON_SNIPERRIFLE','WEAPON_MG','WEAPON_GRENADELAUNCHER','WEAPON_FLAREGUN','WEAPON_BAT','WEAPON_CROWBAR','WEAPON_KNIFE','WEAPON_MACHETE','WEAPON_HATCHET'}
used=collections.defaultdict(set)
pats=[r"AddItem\([^,]+,\s*'([^']+)'", r"RemoveItem\([^,]+,\s*'([^']+)'", r"GetItemCount\([^,]+,\s*'([^']+)'", r"\{\s*'([a-z][a-z0-9_\-]+)'\s*,\s*\d+\s*,\s*\d+\s*,\s*[\d.]+\s*\}", r"\{\s*'([a-z][a-z0-9_\-]+)'\s*,\s*\d+\s*\}", r"item\s*=\s*'([a-z][a-z0-9_\-]+)'", r"CreateUseableItem\(\s*'([^']+)'", r"\bItem\s*=\s*'([a-z][a-z0-9_\-]+)'", r"(?:give|get)\s*=\s*\{\s*'([a-z][a-z0-9_\-]+)'"]
for r in res:
    for rel,c in lua(r):
        for p in pats:
            for n in re.findall(p,c):
                if n in ('__prop',): continue
                used[n].add(r)
# useables table keys in items.lua
for n in re.findall(r"^\s{2}([a-z_]+)\s*=\s*\{\s*(?:requires|effects)",res['outbreak_items']['files']['server/items.lua'],re.M): used[n].add('outbreak_items')
for n,rs in sorted(used.items()):
    if n not in defined and n not in OX_DEFAULT and not n.startswith('WEAPON_') and n not in ('plate','house','fuel','intel','text','model','name','description'):
        find('ERROR',sorted(rs)[0],f"item '{n}' used but not defined in ox_items_snippet / weapons_snippet / ox defaults")

# ── C. SQL tables referenced vs migrated ──
mig=' '.join(open(os.path.join('sql/migrations',f)).read() for f in sorted(os.listdir('sql/migrations')))
tables=set(re.findall(r"CREATE TABLE IF NOT EXISTS (\w+)",mig))
usedt=collections.defaultdict(set)
for r in res:
    for rel,c in lua(r):
        for t in re.findall(r"\b(?:FROM|INTO|UPDATE|JOIN)\s+(outbreak_\w+)",c): usedt[t].add(r)
for t,rs in usedt.items():
    if t not in tables: find('ERROR',sorted(rs)[0],f"SQL table {t} used but not in any migration")
for t in tables:
    if t not in usedt: find('INFO','sql',f"table {t} migrated but not referenced by code")
# columns: crude check of INSERT column lists vs CREATE
for t in tables:
    m=re.search(r"CREATE TABLE IF NOT EXISTS %s\s*\((.*?)\);"%t,mig,re.S)
    cols=set(re.findall(r"^\s*(\w+)\s",m.group(1),re.M)) if m else set()
    cols|=set(re.findall(r",\s*(\w+)\s+(?:VARCHAR|INT|FLOAT|BIGINT|TINYINT|LONGTEXT|TIMESTAMP|TEXT)",m.group(1))) if m else set()
    for r in res:
        for rel,c in lua(r):
            for ins in re.findall(r"INSERT INTO %s\s*\(([^)]*)\)"%t,c):
                for col in re.findall(r"\w+",ins):
                    if cols and col not in cols and col.upper() not in ('PRIMARY','KEY'): find('ERROR',r,f"INSERT INTO {t} uses column '{col}' not in migration")

# ── D. stash id collisions / registered ──
st=collections.defaultdict(set)
for r in res:
    for rel,c in lua(r):
        for n in re.findall(r"RegisterStash\(\s*'([^']+)'",c): st[n].add(r)
for n,rs in st.items():
    if len(rs)>1: find('WARN','*',f"stash '{n}' registered by {sorted(rs)}")

# ── E. start order vs dependencies ──
cfg=open('server.cfg.additions').read()
order=[l.split()[1] for l in cfg.splitlines() if l.strip().startswith('ensure ')]
held=[l.split()[2] for l in cfg.splitlines() if l.strip().startswith('# ensure ')]
for r in res:
    m=res[r]['files'].get('fxmanifest.lua','')
    deps=re.findall(r"'([^']+)'",re.search(r"dependencies\s*\{([^}]*)\}",m).group(1)) if 'dependencies' in m else []
    if r in order:
        for d in deps:
            if d.startswith('outbreak_') and d not in order[:order.index(r)]:
                find('ERROR' if d in order else 'WARN',r,f"ensured before its dependency {d} ({'later in order' if d in order else 'held/not ensured'})")
    elif r not in held: find('WARN',r,'not in server.cfg.additions at all (neither ensured nor held)')

# ── F. NUI JavaScript syntax via node ──
try:
    subprocess.run(['node','-v'],capture_output=True,check=True); have=True
except Exception: have=False
if have:
    for r in res:
        for rel,c in res[r]['files'].items():
            if rel.endswith('.html'):
                for i,js in enumerate(re.findall(r"<script>(.*?)</script>",c,re.S)):
                    js="const GetParentResourceName=()=>'x';"+js
                    tmp='/tmp/nui.js'; open(tmp,'w').write(js)
                    out=subprocess.run(['node','--check',tmp],capture_output=True,text=True)
                    if out.returncode: find('ERROR',r,f"{rel} <script> #{i+1}: {out.stderr.strip().splitlines()[-1][:160]}")
else: find('INFO','*','node not available: NUI JavaScript not parsed')

# ── G. debug/test surfaces present ──
for need in ['ob_kit','ob_zombie','ob_wound','ob_down','ob_opp','ob_revive','dm','journal','placeitem','writenote']:
    if need not in cmds: find('WARN','*',f"expected command '{need}' missing")

out=['# SYSTEMS CHECK — pass 2 (static)\n',f'Resources: {len(res)} · Lua files: {sum(len(lua(r)) for r in res)} · migrations: {len(os.listdir("sql/migrations"))} · items defined: {len(defined)} · commands: {len(cmds)}\n']
for sev in ('ERROR','WARN','INFO'):
    out.append(f'\n## {sev} ({len(F[sev])})'); out+= [f'- **{r}** — {m}' for r,m in sorted(F[sev])]
open('DIAGNOSTIC-REPORT-2.md','w').write('\n'.join(out)); print('\n'.join(out))
