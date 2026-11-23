"""Proposal: stdin metadata in, stdout digests/status only. No file output or test execution."""
import hashlib,json,os,stat,subprocess,sys,select,time
from pathlib import Path
LIMIT=1024*1024
class Refused(ValueError):pass
def digest(v):return hashlib.sha256(json.dumps(v,sort_keys=True,separators=(',',':')).encode()).hexdigest()
def head(root):
 env={'PATH':'/usr/bin:/bin','HOME':'/nonexistent','GIT_CONFIG_NOSYSTEM':'1','GIT_CONFIG_GLOBAL':'/dev/null','GIT_TERMINAL_PROMPT':'0','LC_ALL':'C'}
 def git(*args):return subprocess.check_output(['/usr/bin/git','--no-optional-locks','-C',str(root),*args],env=env,stderr=subprocess.DEVNULL,timeout=5).decode().strip()
 if Path(git('rev-parse','--show-toplevel')).resolve()!=root:raise Refused()
 return git('rev-parse','--verify','HEAD^{commit}')
def scan(root,names):
 if not isinstance(names,list) or not names or len(names)>100 or any(not isinstance(n,str) for n in names):raise Refused()
 if len(set(names))!=len(names):raise Refused()
 result={};total=0
 for name in sorted(names):
  p=Path(name)
  if not p.parts or p.is_absolute() or str(p)!=name or any(v in ('.','..','.git') for v in p.parts):raise Refused()
  fd=os.open(root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
  try:
   for part in p.parts[:-1]:
    nxt=os.open(part,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW,dir_fd=fd);os.close(fd);fd=nxt
   try:f=os.open(p.parts[-1],os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK,dir_fd=fd)
   except FileNotFoundError:result[name]={'state':'missing'};continue
   try:
    a=os.fstat(f)
    if not stat.S_ISREG(a.st_mode) or a.st_nlink!=1 or a.st_size>LIMIT:raise Refused()
    h=hashlib.sha256();size=0
    while True:
     b=os.read(f,min(65536,LIMIT+1-size))
     if not b:break
     h.update(b);size+=len(b)
     if size>LIMIT:raise Refused()
    z=os.fstat(f);identity=lambda x:(x.st_dev,x.st_ino,x.st_size,x.st_mtime_ns,x.st_ctime_ns,x.st_mode)
    if identity(a)!=identity(z):raise Refused()
    total+=size
    if total>8*LIMIT:raise Refused()
    result[name]={'state':'file','sha256':h.hexdigest(),'mode':stat.S_IMODE(z.st_mode)}
   finally:os.close(f)
  finally:os.close(fd)
 return result
def observe(source,names):
 root=Path(source).resolve(strict=True);rev=head(root);first=scan(root,names)
 if head(root)!=rev or scan(root,names)!=first:raise Refused()
 return {'schema':2,'repository_digest':digest(str(root)),'revision':rev,'scope_digest':digest(first),'atomicity':'UNVERIFIED'}
def make(source,names):
 p=observe(source,names);p['packet_digest']=digest(p);return p
def process(request):
 # No path, code, command, provenance or arbitrary error text is returned.
 if not isinstance(request,dict) or request.get('action') not in ('snapshot','check'):raise Refused()
 allowed={'action','source','paths'} if request['action']=='snapshot' else {'action','source','paths','packet','receipt'}
 if set(request)-allowed or not isinstance(request.get('source'),str):raise Refused()
 current=make(request['source'],request.get('paths'))
 if request['action']=='snapshot':return {'state':'SNAPSHOT_UNVERIFIED','packet':current}
 p=request.get('packet');required={'schema','repository_digest','revision','scope_digest','atomicity','packet_digest'}
 if not isinstance(p,dict) or set(p)!=required or p['schema']!=2 or p['atomicity']!='UNVERIFIED':raise Refused()
 if any(not isinstance(p[k],str) for k in required-{'schema'}):raise Refused()
 if p['packet_digest']!=digest({k:v for k,v in p.items() if k!='packet_digest'}):raise Refused()
 if p!=current:return {'state':'STALE'}
 receipt=request.get('receipt')
 if receipt is None:return {'state':'NOT_RUN'}
 if not isinstance(receipt,dict) or set(receipt)!={'schema','packet_digest','outcome','provenance'} or receipt.get('schema')!=2:return {'state':'UNVERIFIED'}
 if receipt['packet_digest']!=current['packet_digest']:return {'state':'STALE'}
 if receipt['outcome'] not in ('PASS','FAIL','NOT_RUN') or not isinstance(receipt['provenance'],str):return {'state':'UNVERIFIED'}
 return {'state':'BOUND_UNVERIFIED'}
def safe_process(request):
 try:return process(request)
 except (Refused,OSError,ValueError,TypeError,KeyError,subprocess.SubprocessError,RecursionError):return {'state':'REFUSED'}
def read_input():
 # macOS/POSIX protocol: stop even if a pipe stays open without EOF.
 deadline=time.monotonic()+5;chunks=[];size=0
 while True:
  left=deadline-time.monotonic()
  if left<=0 or not select.select([sys.stdin.fileno()],[],[],left)[0]:raise Refused()
  chunk=os.read(sys.stdin.fileno(),min(65536,LIMIT+1-size))
  if not chunk:return b''.join(chunks)
  chunks.append(chunk);size+=len(chunk)
  if size>LIMIT:raise Refused()
def bounded_shape(value):
 stack=[(value,0)];count=0
 while stack:
  node,depth=stack.pop();count+=1
  if depth>20 or count>2000:raise Refused()
  if isinstance(node,dict):stack.extend((v,depth+1) for v in node.values())
  elif isinstance(node,list):stack.extend((v,depth+1) for v in node)
def main():
 try:
  request=json.loads(read_input());bounded_shape(request)
  result=safe_process(request)
 except (Refused,ValueError,UnicodeError,OSError,RecursionError):result={'state':'REFUSED'}
 sys.stdout.write(json.dumps(result,sort_keys=True)+'\n')
 return 0 if result['state']=='SNAPSHOT_UNVERIFIED' else 2
if __name__=='__main__':raise SystemExit(main())
