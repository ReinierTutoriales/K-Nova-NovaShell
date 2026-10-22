//@ pragma UseQApplication
//@ pragma StateDir $BASE/quickshell/novashell
// SPDX-License-Identifier: GPL-3.0-or-later
// StateDir fijo: `qs -c novashell` (instalado) y `qs -p <repo>/shell`
// (desarrollo) comparten los mismos datos de usuario.
import Quickshell
import qs.nova

ShellRoot {
    NovaShell {}
}
