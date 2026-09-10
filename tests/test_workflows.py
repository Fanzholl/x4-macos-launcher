"""Exercise shell workflows against isolated fixtures; never launch Wine or touch a bottle."""
import hashlib
import io
import os
from pathlib import Path
import plistlib
import shutil
import shlex
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MEMBER = 'MoltenVK/MoltenVK/dynamic/dylib/macOS/libMoltenVK.dylib'

class Workflows(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='x4-tests-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name).resolve()
        self.scripts = self.base / 'scripts'
        shutil.copytree(ROOT / 'scripts', self.scripts)
        self.src = self.base / 'Original.app'
        self.dst = self.base / 'Patched.app'
        self.librel = 'Contents/SharedSupport/CrossOver/lib64/libMoltenVK.dylib'
        (self.src / self.librel).parent.mkdir(parents=True)
        (self.src / self.librel).write_bytes(b'original library')
        (self.src / 'Contents/Resources').mkdir()
        self.plist = self.src / 'Contents/Info.plist'
        self.plist.write_bytes(plistlib.dumps({'CFBundleIdentifier':'com.codeweavers.CrossOver','CFBundleShortVersionString':'26.2'}))
        self.archive = self.base / 'official-fixture.tar'
        with tarfile.open(self.archive,'w') as tar:
            entry = tarfile.TarInfo(MEMBER)
            data = b'verified replacement'
            entry.size=len(data)
            tar.addfile(entry,io.BytesIO(data))
        fixture_hash=hashlib.sha256(self.archive.read_bytes()).hexdigest()
        common=self.scripts/'common.sh'
        # Only replace the release pin in the test copy, for an offline deterministic archive.
        common.write_text(common.read_text().replace('5e662d77f7f280d9bd692ac5d626831198f404e28b0c8d4d11aac04bff8ff418',fixture_hash))
        self.fake=self.base/'bin';self.fake.mkdir()
        self.shim('uname','echo Darwin')
        self.shim('sysctl','echo 1')
        self.shim('file','echo "Mach-O universal binary x86_64 arm64"')
        self.shim('codesign','[ "${X4_FAIL_SIGN:-0}" != 1 ]')
        self.shim('ps','printf "%s\\n" "${X4_FAKE_PROCESSES:-}"')
        self.shim('curl','echo "Unexpected network request" >&2; exit 90')
        self.env=dict(os.environ, PATH=str(self.fake)+':'+os.environ['PATH'])
        self.bottles=self.base/'Bottles';self.prefix=self.bottles/'Steam'
        self.steam=self.prefix/'drive_c/Program Files (x86)/Steam'
        (self.steam/'steamapps').mkdir(parents=True)
        (self.steam/'steam.exe').write_bytes(b'steam fixture')
        (self.steam/'steamapps/appmanifest_392160.acf').write_text('"StateFlags" "4"\n')
        (self.prefix/'cxbottle.conf').write_text('"WineArch" = "win64"\n')
    def shim(self,name,body):
        p=self.fake/name;p.write_text('#!/bin/bash\n'+body+'\n');p.chmod(0o755)
    def run_script(self,script,*args,ok=True,extra=None):
        env=self.env.copy();env.update(extra or {})
        p=subprocess.run(['/bin/bash',str(self.scripts/script),*map(str,args)],env=env,text=True,capture_output=True)
        if ok:self.assertEqual(p.returncode,0,p.stdout+p.stderr)
        else:self.assertNotEqual(p.returncode,0,p.stdout+p.stderr)
        return p
    def install(self,*args,**kwargs):
        return self.run_script('install.sh','--source-app',self.src,'--dest-app',self.dst,'--archive',self.archive,*args,**kwargs)
    def launch(self,*args,**kwargs):
        return self.run_script('launch.sh','--app',self.dst,'--bottles-dir',self.bottles,'--dry-run',*args,**kwargs)
    def test_automatic_entry_preserves_active_game(self):
        result=self.run_script('play.sh','--bottle','Steam',extra={'X4_FAKE_PROCESSES':r'C:\Steam\X4.exe'})
        self.assertIn('already running',result.stdout)
    def test_automatic_entry_without_options_reaches_launcher(self):
        # Isolate installation and Wine while exercising Play.command's entry path
        # using the real macOS Bash 3.2 interpreter and nounset behavior.
        (self.scripts/'install.sh').write_text('#!/bin/bash\nexit 0\n')
        (self.scripts/'launch.sh').write_text('#!/bin/bash\nprintf "launch reached, arguments: %s\\n" "$#"\n')
        result=self.run_script('play.sh')
        self.assertIn('launch reached, arguments: 0',result.stdout)
    def test_hud_restarts_existing_managed_steam_gracefully(self):
        common=self.scripts/'common.sh'
        common.write_text(common.read_text().replace('DEFAULT_APP="$HOME/Applications/CrossOver-X4.app"',
                                                    'DEFAULT_APP='+shlex.quote(str(self.dst))))
        marker=self.dst/'Contents/Resources/x4-macos-launcher.plist'
        marker.parent.mkdir(parents=True);marker.touch()
        called=self.base/'steam-shutdown'
        wine=self.dst/'Contents/SharedSupport/CrossOver/bin/wine'
        wine.parent.mkdir(parents=True)
        wine.write_text('#!/bin/bash\nprintf "%s\\n" "$@" > '+shlex.quote(str(called))+'\n')
        wine.chmod(0o755)
        self.shim('ps','[ -f '+shlex.quote(str(called))+' ] || printf "%s\\n" "${X4_FAKE_PROCESSES:-}"')
        (self.scripts/'install.sh').write_text('#!/bin/bash\nexit 0\n')
        (self.scripts/'launch.sh').write_text('#!/bin/bash\nexit 0\n')
        processes=str(wine.parent/'wineserver')+'\n'+r'C:\Steam\steam.exe'
        self.run_script('play.sh','--bottle','Steam','--metal-hud',extra={'X4_FAKE_PROCESSES':processes})
        self.assertTrue(called.exists(),'Existing managed Steam must restart to inherit Metal HUD')
        self.assertIn('-shutdown',called.read_text().splitlines())
    def test_help_and_missing_options(self):
        for script in ('install.sh','launch.sh','doctor.sh','uninstall.sh'):
            self.run_script(script,'--help')
            self.run_script(script,'--nonsense',ok=False)
        self.run_script('install.sh','--dest-app',ok=False)
    def test_dry_run_has_no_mutations(self):
        self.install('--dry-run')
        self.assertFalse(self.dst.exists())
        self.assertFalse(Path(str(self.dst)+'.install-lock').exists())
    def test_install_preserves_source_and_is_idempotent(self):
        self.install()
        self.assertEqual((self.src/self.librel).read_bytes(),b'original library')
        self.assertEqual((self.dst/self.librel).read_bytes(),b'verified replacement')
        m=self.dst/'Contents/Resources/x4-macos-launcher.plist'
        before=m.read_bytes();self.install();self.assertEqual(m.read_bytes(),before)
    def test_checksum_mismatch_installs_nothing(self):
        self.archive.write_bytes(b'corrupt')
        p=self.install(ok=False);self.assertIn('checksum mismatch',p.stderr)
        self.assertFalse(self.dst.exists())
        self.assertFalse(Path(str(self.dst)+'.install-lock').exists())
    def test_signature_failure_cleans_staging(self):
        self.install(ok=False,extra={'X4_FAIL_SIGN':'1'})
        self.assertFalse(self.dst.exists())
        self.assertFalse(list(self.base.glob('.x4-install.*')))
    def test_same_source_and_symlink_refused(self):
        self.run_script('install.sh','--source-app',self.src,'--dest-app',self.src,ok=False)
        self.dst.symlink_to(self.src)
        self.install(ok=False)
        self.assertEqual((self.src/self.librel).read_bytes(),b'original library')
    def test_unknown_destination_preserved(self):
        self.dst.mkdir();sentinel=self.dst/'personal';sentinel.write_text('keep')
        self.install(ok=False);self.assertEqual(sentinel.read_text(),'keep')
    def test_version_gate(self):
        p=plistlib.loads(self.plist.read_bytes());p['CFBundleShortVersionString']='26.3'
        self.plist.write_bytes(plistlib.dumps(p))
        self.install(ok=False);self.install('--allow-untested')
    def test_launcher_detection_and_corruption(self):
        self.install();self.launch()
        (self.dst/self.librel).write_text('unexpected change');self.launch(ok=False)
    def test_ambiguous_bottles_require_choice(self):
        self.install();shutil.copytree(self.prefix,self.bottles/'Other')
        self.launch(ok=False);self.launch('--bottle','Steam')
    def test_launcher_rejects_pending_update_and_32bit(self):
        self.install();manifest=self.steam/'steamapps/appmanifest_392160.acf'
        manifest.write_text('"StateFlags" "1026"\n');self.launch(ok=False)
        manifest.write_text('"StateFlags" "4"\n')
        (self.prefix/'cxbottle.conf').write_text('"WineArch" = "win32"\n');self.launch(ok=False)
    def test_runtime_conflict_and_active_game(self):
        self.install()
        self.launch(ok=False,extra={'X4_FAKE_PROCESSES':'/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wineserver'})
        self.launch(ok=False,extra={'X4_FAKE_PROCESSES':r'C:\Steam\X4.exe'})
    def test_uninstaller_refuses_unknown_or_running(self):
        self.run_script('uninstall.sh','--app',self.src,'--dry-run',ok=False)
        self.install()
        self.run_script('uninstall.sh','--app',self.dst,'--dry-run')
        self.run_script('uninstall.sh','--app',self.dst,'--dry-run',ok=False,extra={'X4_FAKE_PROCESSES':str(self.dst)+'/Contents/MacOS/CrossOver'})
        self.assertTrue(self.dst.exists())

if __name__=='__main__':unittest.main(verbosity=2)
