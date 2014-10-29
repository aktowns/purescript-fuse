module Demo.Mirror where

import Debug.Trace
import qualified Fuse.Binding as Fuse

getattr :: Fuse.GetAttrHandler
getattr path cb = return unit

readdir :: Fuse.ReadDirHandler
readdir path cb = return unit

readlink :: Fuse.ReadLinkHandler
readlink path cb = return unit

chmod :: Fuse.ChmodHandler
chmod path mode cb = return unit

open :: Fuse.OpenHandler
open path flags cb = return unit

readH :: Fuse.ReadHandler
readH path offset len buf fh cb = return unit

write :: Fuse.WriteHandler
write path offset len buf fh cb = return unit

release :: Fuse.ReleaseHandler
release path fh cb = return unit

create :: Fuse.CreateHandler
create path mode cb = return unit

unlink :: Fuse.UnlinkHandler
unlink path cb = return unit

rename :: Fuse.RenameHandler
rename src dst cb = return unit

mkdir :: Fuse.MkdirHandler
mkdir path mode cb = return unit

rmdir :: Fuse.RmdirHandler
rmdir path cb = return unit

initH :: Fuse.InitHandler
initH cb = do
  trace "* initH"
  Fuse.callback cb

destroy :: Fuse.DestroyHandler
destroy cb = do
  trace "* destroy"
  Fuse.callback cb

statfs :: Fuse.StatFSHandler
statfs cb = do
  trace "* statfs"
  Fuse.callback cb $ 0 { bsize: 1000000, frsize: 1000000, blocks: 1000000, bfree: 1000000, bavail: 1000000, files: 1000000, ffree: 1000000, favail: 1000000, fsid: 1000000, flag: 1000000, namemax: 1000000 }

handlers :: Fuse.Handlers
handlers = { getattr: getattr, readdir: readdir, readlink: readlink, chmod: chmod, open: open, read: readH, write: write, release: release, create: create, unlink: unlink, rename: rename, mkdir: mkdir, rmdir: rmdir, init: initH, destroy: destroy, statfs: statfs }

startMirrorFS :: Unit
startMirrorFS = Fuse.start "/tmp/test" (Fuse.prepareHandlers handlers) true
