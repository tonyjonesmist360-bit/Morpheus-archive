import re, os, subprocess, json, collections
ROOT='resources'
res={}  # name -> {path, files:{rel:content}, manifest:str, side:{rel:'client'|'server'|'shared'}}
for grp in sorted(os.listdir(ROOT)):
    for r in sorted(os.listdir(os.path.join(ROOT,grp))):
        p=os.path.join(ROOT,grp,r)
        if not os.path.isdir(p): continue
        files={}
        for dp,_,fs in os.walk(p):
            for f in fs:
                rel=os.path.relpath(os.path.join(dp,f),p).replace('\\','/')
                files[rel]=open(os.path.join(dp,f),encoding='utf-8',errors='replace').read()
        res[r]={'path':p,'group':grp,'files':files,'manifest':files.get('fxmanifest.lua','')}
F=collections.defaultdict(list)  # findings by severity
def find(sev,res_,msg): F[sev].append((res_,msg))

# ── 1. syntax ──
for r,d in res.items():
    for rel,c in d['files'].items():
        if rel.endswith('.lua') and not (rel.startswith('data/') or (rel.startswith('data/') or '/data/' in rel)):
            tmp='/tmp/diag.lua'; open(tmp,'w').write(re.sub(r'`[^`]*`','0',c))
            out=subprocess.run(['luac5.4','-p',tmp],capture_output=True,text=True)
            if out.returncode: find('ERROR',r,f'syntax {rel}: {out.stderr.strip()}')
        elif rel.endswith('.lua') and (rel.startswith('data/') or '/data/' in rel) and 'snippet' in rel: find('INFO',r,f'{rel} is a paste-in fragment (not loaded, not syntax-checked as a file)')

# ── 2. manifest: referenced files exist; lua files are referenced; side classification ──
side={}
for r,d in res.items():
    m=d['manifest']
    refs=re.findall(r"'([^']+\.(?:lua|html|png|jpg|css|js))'",m)
    for ref in refs:
        if ref.startswith('@'): continue
        if ref not in d['files']: find('ERROR',r,f'manifest references missing file {ref}')
    for rel in d['files']:
        if rel.endswith('.lua') and rel!='fxmanifest.lua' and not (rel.startswith('data/') or (rel.startswith('data/') or '/data/' in rel)) and rel not in refs:
            find('WARN',r,f'{rel} exists but is not in fxmanifest (never loaded)')
        elif rel.endswith('.lua') and (rel.startswith('data/') or '/data/' in rel) and 'snippet' not in rel and rel not in refs:
            find('ERROR',r,f'{rel} data file is not in fxmanifest')
    # side by which block the file is in
    for block,tag in [('client_scripts','client'),('server_scripts','server'),('shared_scripts','shared')]:
        mm=re.search(block+r"\s*\{([^}]*)\}",m)
        if mm:
            for ref in re.findall(r"'([^']+)'",mm.group(1)):
                if not ref.startswith('@'): side[(r,ref)]=tag
    if 'ui_page' in m and 'files' not in m: find('ERROR',r,'ui_page without files {}')

def sideof(r,rel): return side.get((r,rel),'shared' if rel.startswith('shared') else ('client' if rel.startswith('client') else ('server' if rel.startswith('server') else 'unknown')))

# ── 3. events ──
reg=collections.defaultdict(set)   # name -> set((res,side))
trig=collections.defaultdict(set)  # name -> set((res,side,kind))
for r,d in res.items():
    for rel,c in d['files'].items():
        if not rel.endswith('.lua') or rel=='fxmanifest.lua': continue
        s=sideof(r,rel)
        for n in re.findall(r"(?:RegisterNetEvent|AddEventHandler)\(\s*'([^']+)'",c): reg[n].add((r,s))
        for kind,n in re.findall(r"(TriggerEvent|TriggerClientEvent|TriggerServerEvent)\(\s*'([^']+)'",c): trig[n].add((r,s,kind))
        for n in re.findall(r"\bevent\s*=\s*'([^']+)'",c): trig[n].add((r,s,'TriggerEvent'))
        for n in re.findall(r"(?:RegisterNetEvent|AddEventHandler)\(\s*'([^']+)'\s*\.\.",c): reg[n+'*'].add((r,s))
EXT_EVENTS={'QBCore:Server:PlayerLoaded','QBCore:Client:OnPlayerLoaded','QBCore:Client:OnJobUpdate','playerDropped','gameEventTriggered','ox_lib:notify','mm_radio:client:use','chat:addMessage','chat:addSuggestion','chat:addTemplate','pma-voice:setTalkingOnRadio','pma-voice:radioActive'}
for n,ts in trig.items():
    if n in EXT_EVENTS or n.startswith('outbreak:event:'): continue
    for (r,s,kind) in ts:
        need={'TriggerClientEvent':'client','TriggerServerEvent':'server','TriggerEvent':s}[kind]
        ok=any((need==rs or rs=='shared') for (_,rs) in reg.get(n,()))
        if not ok:
            # dynamic registrations (prefix*)
            if any(n.startswith(k[:-1]) for k in reg if k.endswith('*')): continue
            find('ERROR',r,f"{kind}('{n}') from {s} side but no {need}-side handler anywhere")
for n,rs in reg.items():
    if n.endswith('*') or n in EXT_EVENTS: continue
    if n not in trig and not n.startswith('outbreak:event:'): find('INFO',next(iter(rs))[0],f"handler '{n}' registered but never triggered (dead or external)")

# ── 4. exports ──
defs=collections.defaultdict(set)  # (res,side) -> names
calls=[]  # (res,side,target,name,guarded)
for r,d in res.items():
    for rel,c in d['files'].items():
        if not rel.endswith('.lua') or rel=='fxmanifest.lua': continue
        s=sideof(r,rel)
        for n in re.findall(r"exports\(\s*'([^']+)'",c): defs[(r,s)].add(n)
        for m in re.finditer(r"exports(?:\.([A-Za-z_][\w]*)|\['([^']+)'\])[:.]([A-Za-z_]\w*)\s*\(",c):
            target=m.group(1) or m.group(2); name=m.group(3)
            pre=c[max(0,m.start()-160):m.start()]
            calls.append((r,s,target,name,'pcall' in pre))
EXT_RES={'ox_inventory','ox_target','pma-voice','illenium-appearance','qb-core','qbx_core','mm_radio','ox_lib','oxmysql','bob74_ipl','qbx_vehiclekeys'}
for (r,s,target,name,g) in calls:
    if target in EXT_RES: continue
    if target not in res: find('ERROR',r,f'{s}: calls exports.{target}:{name}() but resource does not exist'); continue
    if name not in defs.get((target,s),set()) and name not in defs.get((target,'shared'),set()):
        other='server' if s=='client' else 'client'
        if name in defs.get((target,other),set()): find('ERROR',r,f"{s}: calls exports.{target}:{name}() but it is only defined on the {other} side")
        else: find('ERROR' if not g else 'WARN',r,f"{s}: calls exports.{target}:{name}() which is not defined {'(pcall-guarded)' if g else ''}")
    else:
        pass

# ── 5. config globals across resources ──
cfgdef={}
for r,d in res.items():
    for rel,c in d['files'].items():
        for n in re.findall(r"^([A-Z][A-Za-z]*(?:Cfg|Catalog))\s*=",c,re.M): cfgdef[n]=(r,rel)
for r,d in res.items():
    m=d['manifest']
    for rel,c in d['files'].items():
        if not rel.endswith('.lua') or rel=='fxmanifest.lua' or (rel.startswith('data/') or '/data/' in rel): continue
        for n in set(re.findall(r"\b([A-Z][A-Za-z]*(?:Cfg|Catalog))\b",c)):
            if n not in cfgdef: find('WARN',r,f'{rel} uses undefined config global {n}'); continue
            dr,drel=cfgdef[n]
            if dr!=r and ('@'+dr+'/'+drel) not in m:
                find('ERROR',r,f"{rel} uses {n} (defined in {dr}/{drel}) but manifest does not include '@{dr}/{drel}'")

# ── 6. lib callbacks ──
cbreg=set(); cbawait=collections.defaultdict(set)
for r,d in res.items():
    for rel,c in d['files'].items():
        for n in re.findall(r"lib\.callback\.register\(\s*'([^']+)'",c): cbreg.add(n)
        for n in re.findall(r"lib\.callback\.await\(\s*'([^']+)'",c): cbawait[n].add(r)
for n,rs in cbawait.items():
    if n not in cbreg: find('ERROR',next(iter(rs)),f"lib.callback.await('{n}') has no register")

# ── 7. NUI callbacks vs html fetch ──
for r,d in res.items():
    htmls=[c for rel,c in d['files'].items() if rel.endswith('.html')]
    luas=' '.join(c for rel,c in d['files'].items() if rel.endswith('.lua'))
    for h in htmls:
        for n in set(re.findall(r"GetParentResourceName\(\)\}/([A-Za-z_]+)",h)+re.findall(r"post\('([a-z_]+)'",h)):
            if f"RegisterNUICallback('{n}'" not in luas: find('ERROR',r,f"html posts NUI callback '{n}' but no RegisterNUICallback")
    for n in re.findall(r"SendNUIMessage\(\{\s*action\s*=\s*'([^']+)'",luas):
        if htmls and not any(f"'{n}'" in h for h in htmls): find('WARN',r,f"SendNUIMessage action '{n}' not handled in html")
    if 'SendNUIMessage' in luas and not htmls and 'ui_page' not in d['manifest']: find('ERROR',r,'SendNUIMessage used but resource has no ui_page')

# ── 8. statebags ──
sbset=collections.defaultdict(set); sbget=collections.defaultdict(set)
for r,d in res.items():
    for rel,c in d['files'].items():
        for n in re.findall(r"state:set\(\s*'([^']+)'",c): sbset[n].add(r)
        for n in re.findall(r"\.state\.([A-Za-z_]\w*)",c): sbget[n].add(r)
        for n in re.findall(r"GlobalState\.([A-Za-z_]\w*)\s*=",c): sbset[n].add(r)
        for n in re.findall(r"GlobalState\.([A-Za-z_]\w*)",c): sbget[n].add(r)
for n,rs in sbget.items():
    if n in ('set',) : continue
    if n not in sbset: find('WARN',next(iter(rs)),f"statebag '{n}' read but never set")

# ── 9. dependency sanity ──
for r,d in res.items():
    for dep in re.findall(r"dependencies\s*\{([^}]*)\}",d['manifest']):
        for n in re.findall(r"'([^']+)'",dep):
            if n not in res and n not in EXT_RES: find('WARN',r,f"declares dependency '{n}' which is not in the pack (external?)")

# ── report ──
out=['# DIAGNOSTIC REPORT (static, pre-boot)\n',f'Resources scanned: {len(res)}  ·  files: {sum(len(d["files"]) for d in res.values())}\n']
for sev in ('ERROR','WARN','INFO'):
    out.append(f'\n## {sev} ({len(F[sev])})\n')
    for r,m in sorted(F[sev]): out.append(f'- **{r}** — {m}')
out.append('''
## What this pass cannot see (runtime only)
- Native names/signatures, animation dictionary + clip names, prop model names, blip sprites — all from memory
- World coordinates (houses, stations, camps, decoy, spawn points)
- Framework API surface: qb-core bridge functions, `exports.qbx_core:Logout`, `illenium-appearance` exports, `mm_radio` exports, `pma-voice` `getRadioChannel`
- ox_inventory client weight exports; ox_lib `registerRadial` payload shape; NUI focus + keyboard behaviour
- OneSync entity ownership behaviour (zombie migration, wave election), `TaskWarpPedIntoVehicle` on anim-locked peds
- JavaScript inside NUI html (not parsed here)
''')
open('DIAGNOSTIC-REPORT.md','w').write('\n'.join(out))
print('\n'.join(out))
