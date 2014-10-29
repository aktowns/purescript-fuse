module Fuse.Binding where

import Debug.Trace
import Control.Monad.Eff

type Stat = { bsize :: Number, frsize :: Number, blocks :: Number, bfree :: Number, bavail :: Number, files :: Number, ffree :: Number, favail :: Number, fsid :: Number, flag :: Number, namemax :: Number }


foreign import data Fuse :: !

-- I'm stuck here, i want to be able to return any kind in
-- functions this is applied to { fuse :: Fuse | * } but
-- i get unification errors when using trace since it doesn't unify with '| eXX'
type FuseEff e = Eff (fuse :: Fuse, trace :: Trace | e) Unit


{-
  Handler for the getattr() system call.
  path: the path to the file
  cb: a callback of the form cb(err, stat), where err is the Posix return code
      and stat is the result in the form of a stat structure (when err === 0)
-}
type GetAttrHandler = forall e. String -> (Number -> Stat -> Unit) -> FuseEff e

{-
  Handler for the readdir() system call.
  path: the path to the file
  cb: a callback of the form cb(err, names), where err is the Posix return code
      and names is the result in the form of an array of file names (when err === 0).
-}
type ReadDirHandler = forall e. String -> (Number -> [String] -> Unit) -> FuseEff e

{-
  Handler for the readlink() system call.
  path: the path to the file
  cb: a callback of the form cb(err, name), where err is the Posix return code
      and name is symlink target (when err === 0).
-}
type ReadLinkHandler = forall e. String -> (Number -> String -> Unit) -> FuseEff e

{-
  Handler for the chmod() system call.
  path: the path to the file
  mode: the desired permissions
  cb: a callback of the form cb(err), where err is the Posix return code.
-}
type ChmodHandler = forall e. String -> Number -> (Number -> Unit) -> FuseEff e

{-
  Handler for the open() system call.
  path: the path to the file
  flags: requested access flags as documented in open(2)
  cb: a callback of the form cb(err, [fh]), where err is the Posix return code
      and fh is an optional numerical file handle, which is passed to subsequent
      read(), write(), and release() calls (set to 0 if fh is unspecified)
-}
type OpenHandler = forall e. String -> Number -> (Number -> Number -> Unit) -> FuseEff e

{-
  Handler for the read() system call.
  path: the path to the file
  offset: the file offset to read from
  len: the number of bytes to read
  buf: the Buffer to write the data to
  fh:  the optional file handle originally returned by open(), or 0 if it wasn't
  cb: a callback of the form cb(err), where err is the Posix return code.
      A positive value represents the number of bytes actually read.
-}
type ReadHandler = forall e. String -> Number -> Number -> [String] -> Number -> (Number -> Unit) -> FuseEff e

{-
  Handler for the write() system call.
  path: the path to the file
  offset: the file offset to write to
  len: the number of bytes to write
  buf: the Buffer to read data from
  fh:  the optional file handle originally returned by open(), or 0 if it wasn't
  cb: a callback of the form cb(err), where err is the Posix return code.
      A positive value represents the number of bytes actually written.
-}
type WriteHandler = forall e. String -> Number -> Number -> [String] -> Number -> (Number -> Unit) -> FuseEff e

{-
  Handler for the release() system call.
  path: the path to the file
  fh:  the optional file handle originally returned by open(), or 0 if it wasn't
  cb: a callback of the form cb(err), where err is the Posix return code.
-}
type ReleaseHandler = forall e. String -> Number -> (Number -> Unit) -> FuseEff e

{-
  Handler for the create() system call.
  path: the path of the new file
  mode: the desired permissions of the new file
  cb: a callback of the form cb(err, [fh]), where err is the Posix return code
      and fh is an optional numerical file handle, which is passed to subsequent
      read(), write(), and release() calls (it's set to 0 if fh is unspecified)
-}
type CreateHandler = forall e. String -> Number -> (Number -> Number -> Unit) -> FuseEff e

{-
  Handler for the unlink() system call.
  path: the path to the file
  cb: a callback of the form cb(err), where err is the Posix return code.
-}
type UnlinkHandler = forall e. String -> (Number -> Unit) -> FuseEff e

{-
  Handler for the rename() system call.
  src: the path of the file or directory to rename
  dst: the new path
  cb: a callback of the form cb(err), where err is the Posix return code.
-}
type RenameHandler = forall e. String -> String -> (Number -> Unit) -> FuseEff e

{-
 * Handler for the mkdir() system call.
 * path: the path of the new directory
 * mode: the desired permissions of the new directory
 * cb: a callback of the form cb(err), where err is the Posix return code.
-}
type MkdirHandler = forall e. String -> Number -> (Number -> Unit) -> FuseEff e

{-
  Handler for the rmdir() system call.
  path: the path of the directory to remove
  cb: a callback of the form cb(err), where err is the Posix return code.
-}
type RmdirHandler = forall e. String -> (Number -> Unit) -> FuseEff e

{-
  Handler for the init() FUSE hook. You can initialize your file system here.
  cb: a callback to call when you're done initializing. It takes no arguments.
-}
type InitHandler = forall e. (Unit) -> FuseEff e

{-
  Handler for the destroy() FUSE hook. You can perform clean up tasks here.
  cb: a callback to call when you're done. It takes no arguments.
-}
type DestroyHandler = forall e. (Unit) -> FuseEff e

{-
  Handler for the statfs() FUSE hook.
  cb: a callback of the form cb(err, stat), where err is the Posix return code
      and stat is the result in the form of a statvfs structure (when err === 0)
-}
type StatFSHandler = forall e. (Number -> Stat -> Unit) -> FuseEff e

type Handlers = {
  getattr  :: GetAttrHandler,
  readdir  :: ReadDirHandler,
  readlink :: ReadLinkHandler,
  chmod    :: ChmodHandler,
  open     :: OpenHandler,
  read     :: ReadHandler,
  write    :: WriteHandler,
  release  :: ReleaseHandler,
  create   :: CreateHandler,
  unlink   :: UnlinkHandler,
  rename   :: RenameHandler,
  mkdir    :: MkdirHandler,
  rmdir    :: RmdirHandler,
  init     :: InitHandler,
  destroy  :: DestroyHandler,
  statfs   :: StatFSHandler }


{-
  !! ACHTUNG !!
  since we're handing our function stubs back to the javascript world
  we have to uncurry them, the hack below loops through the handlers
  and wraps them in a variadic function. which loops through the args
  unwrapping. This is a hack, this is bad. work arounds?
-}
foreign import prepareHandlers """
  function prepareHandlers(handlers) {
    function uncurry(f) {
      if (typeof f != "function" || f.length == 0) {
        return f;
      }
      return function() {
        var r = f;
        for (var i = 0; i < arguments.length; i++) {
          r = r(arguments[i]);
        }
        return r();
      };
    }

    Object.keys(handlers).map(function (key) {
      handlers[key] = uncurry(handlers[key]);
    });

    return handlers;
  }
""" :: Handlers -> Handlers

foreign import start """
  function start(mountPoint) {
    return function(handlers) {
      return function(debug) {
        require('fuse4js').start(mountPoint, handlers, debug);
        return {};
      };
    };
  } """ :: String -> Handlers -> Boolean -> Unit
