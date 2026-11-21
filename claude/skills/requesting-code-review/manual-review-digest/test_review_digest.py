import unittest,tempfile,subprocess,json,os,sys,io,contextlib
from pathlib import Path
from unittest.mock import patch
import review_digest as m
class DigestTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(prefix='digest-synthetic-',dir='/tmp');self.root=Path(self.tmp.name).resolve();self.repo=self.root/'repo';self.repo.mkdir();self.env={'PATH':'/usr/bin:/bin','HOME':str(self.root),'GIT_CONFIG_NOSYSTEM':'1','GIT_CONFIG_GLOBAL':'/dev/null','GIT_TERMINAL_PROMPT':'0'}
  self.git('init','-q');self.git('config','user.name','Synthetic');self.git('config','user.email','test@example.invalid');self.path='PRIVATE_PATH_SENTINEL.txt';self.code='PRIVATE_CODE_SENTINEL_29b4';self.put(self.path,self.code);self.put('dep.txt','original');self.git('add','.');self.git('commit','-qm','base')
 def tearDown(self):self.tmp.cleanup()
 def git(self,*a):return subprocess.check_output(['/usr/bin/git','-c','core.hooksPath=/dev/null','-c','commit.gpgsign=false','-C',str(self.repo),*a],env=self.env,stderr=subprocess.PIPE).decode().strip()
 def put(self,n,s):(self.repo/n).write_text(s)
 def request(self,action='snapshot',**kw):return {'action':action,'source':str(self.repo),'paths':[self.path],**kw}
 def packet(self):return m.safe_process(self.request())['packet']
 def check(self,p,receipt=None):return m.safe_process(self.request('check',packet=p,receipt=receipt))
 def receipt(self,p):return {'schema':2,'packet_digest':p['packet_digest'],'outcome':'PASS','provenance':'FORGED_PROVENANCE_SENTINEL'}
 def test_no_code_or_path_in_output(self):
  s=json.dumps(m.safe_process(self.request()));self.assertNotIn(self.code,s);self.assertNotIn(self.path,s);self.assertNotIn(str(self.repo),s)
 def test_no_evidence_not_run(self):self.assertEqual(self.check(self.packet())['state'],'NOT_RUN')
 def test_matching_forged_pass_unverified(self):
  p=self.packet();v=self.check(p,self.receipt(p));self.assertEqual(v,{'state':'BOUND_UNVERIFIED'});self.assertNotIn('FORGED',json.dumps(v))
 def test_dirty_stale(self):
  p=self.packet();self.put(self.path,'working');self.assertEqual(self.check(p)['state'],'STALE')
 def test_head_stale(self):
  p=self.packet();self.put('dep.txt','new');self.git('add','dep.txt');self.git('commit','-qm','head');self.assertEqual(self.check(p)['state'],'STALE')
 def test_unselected_dependency_unverified(self):
  p=self.packet();self.put('dep.txt','broken');self.assertEqual(self.check(p,self.receipt(p))['state'],'BOUND_UNVERIFIED')
 def test_unknown_evidence(self):
  p=self.packet();self.assertEqual(self.check(p,{'result':'PASS'})['state'],'UNVERIFIED')
 def test_rehashed_forgery_stays_unverified(self):
  p=self.packet();self.put(self.path,'new untested bytes');current=m.make(str(self.repo),[self.path]);p['scope_digest']=current['scope_digest'];p['packet_digest']=m.digest({k:v for k,v in p.items() if k!='packet_digest'});self.assertEqual(self.check(p,self.receipt(p))['state'],'BOUND_UNVERIFIED')
 def test_snapshot_no_file_write_even_if_old_output_relocated(self):
  out=self.root/'old-output';out.mkdir();out.rename(self.repo/'relocated-output')
  before=self.git('status','--porcelain');index=(self.repo/'.git/index').read_bytes();
  with patch.object(m.os,'mkdir',side_effect=AssertionError('must not mkdir')),patch.object(Path,'write_text',side_effect=AssertionError('must not write')):
   self.packet()
  self.assertEqual(self.git('status','--porcelain'),before);self.assertEqual((self.repo/'.git/index').read_bytes(),index);self.assertFalse(list((self.repo/'relocated-output').iterdir()))
 def test_source_open_is_read_only(self):
  real=m.os.open;flags=[]
  def watch(path,mode,*a,**kw):
   if str(path) != '/dev/null':flags.append(mode)
   return real(path,mode,*a,**kw)
  with patch.object(m.os,'open',watch):self.packet()
  self.assertTrue(flags);self.assertTrue(all(not x&(os.O_CREAT|os.O_WRONLY|os.O_RDWR|os.O_TRUNC) for x in flags))
 def test_leaf_parent_link_and_dot_refused(self):
  (self.repo/'link').symlink_to(self.repo/self.path);(self.repo/'dir').symlink_to(self.repo,target_is_directory=True)
  for paths in [['link'],['dir/'+self.path],['.'],['../x'],['.git/config']]:
   self.assertEqual(m.safe_process({**self.request(),'paths':paths})['state'],'REFUSED')
 def test_changed_between_reads_refused(self):
  real=m.scan;n=0
  def moving(*a,**kw):
   nonlocal n
   n+=1
   if n==2:self.put(self.path,'changed')
   return real(*a,**kw)
  with patch.object(m,'scan',moving):self.assertEqual(m.safe_process(self.request())['state'],'REFUSED')
 def test_aba_remains_unverified(self):
  real=m.scan;n=0
  def aba(*a,**kw):
   nonlocal n
   n+=1
   if n==2:self.put(self.path,'transient');self.put(self.path,self.code)
   return real(*a,**kw)
  with patch.object(m,'scan',aba):self.assertEqual(m.safe_process(self.request())['state'],'SNAPSHOT_UNVERIFIED')
 def test_after_observation_change_remains_unverified(self):
  p=self.packet();real=m.make
  def moving(*a,**kw):v=real(*a,**kw);self.put(self.path,'after');return v
  with patch.object(m,'make',moving):self.assertEqual(self.check(p,self.receipt(p))['state'],'BOUND_UNVERIFIED')
 def test_unknown_fields_and_exception_do_not_leak(self):
  self.assertEqual(m.safe_process({**self.request(),'output':str(self.repo)}),{'state':'REFUSED'})
  with patch.object(m,'observe',side_effect=OSError(self.code)):
   self.assertEqual(m.safe_process(self.request()),{'state':'REFUSED'})
 def test_actual_stdin_stdout_protocol(self):
  cp=subprocess.run([sys.executable,'-B',str(Path(m.__file__).resolve())],input=json.dumps(self.request()),text=True,capture_output=True,env={**self.env,'PYTHONDONTWRITEBYTECODE':'1'})
  self.assertEqual(cp.returncode,0);self.assertEqual(cp.stderr,'');self.assertNotIn(self.code,cp.stdout);self.assertNotIn(self.path,cp.stdout);self.assertEqual(json.loads(cp.stdout)['state'],'SNAPSHOT_UNVERIFIED')
 def test_protocol_bad_inputs_fixed_output(self):
  for raw in [b'',b'\xff',b'['*1200+b'0'+b']'*1200,b'x'*(m.LIMIT+1),b'{"unknown":1}']:
   cp=subprocess.run([sys.executable,'-B',str(Path(m.__file__).resolve())],input=raw,capture_output=True,env=self.env,timeout=8)
   self.assertEqual(cp.returncode,2);self.assertEqual(cp.stderr,b'');self.assertEqual(json.loads(cp.stdout),{'state':'REFUSED'})
 def test_git_timeout_fixed_output(self):
  with patch.object(m.subprocess,'check_output',side_effect=subprocess.TimeoutExpired('synthetic',5)):
   self.assertEqual(m.safe_process(self.request()),{'state':'REFUSED'})
 def test_stdin_open_pipe_times_out(self):
  cp=subprocess.Popen([sys.executable,'-B',str(Path(m.__file__).resolve())],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=self.env)
  try:
   cp.wait(timeout=8);self.assertEqual(cp.returncode,2);self.assertEqual(json.loads(cp.stdout.read()),{'state':'REFUSED'});self.assertEqual(cp.stderr.read(),b'')
  finally:
   if cp.poll() is None:cp.kill();cp.wait()
   cp.stdin.close();cp.stdout.close();cp.stderr.close()
if __name__=='__main__':unittest.main()
