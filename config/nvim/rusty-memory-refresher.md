# Rusty Memory Refresher

Cheat sheet for *this* Neovim config. Keys marked **LSP** only work in a buffer
where a language server is attached (Zig, via ZLS).

## Reading the notation

| Written | Means |
| --- | --- |
| `<C-o>` | hold Ctrl, tap `o`, release - like Ctrl+C to copy |
| `<C-w>v` | hold Ctrl, tap `w`, release, *then* tap `v` |
| `<leader>gd` | tap Space, then `g`, then `d` - three separate presses |
| `<CR>` | Enter |
| `<S-Tab>` | hold Shift, tap Tab |
| `<Esc>` / `<BS>` / `<Tab>` | those keys |
| `gd` | tap `g`, then `d` - no modifier at all |
| `dw` | tap `d`, then `w` |

So `<...>` is one chord with a modifier held down; plain letters side by side
are separate taps in sequence. Vim gives you as long as you like between taps.

Capital letters mean Shift: `G` is Shift+g. A leading `:` means type it as a
command line and press Enter.

---

## The ones you keep forgetting

| Want to | Press |
| --- | --- |
| Jump to end of line | `$` |
| Jump to start of line | `0` (column 0) or `^` (first non-blank) |
| Jump to start of file | `gg` |
| Jump to end of file | `G` |
| Go to definition | `gd` **LSP** |
| Go to implementation | `gi` **LSP** |
| **Go back** (after any jump) | `<C-o>` — forward again is `<C-i>` |
| Open / close file tree | `<C-n>` toggles it (or `q` while inside it) |
| Open git diff view | `<leader>gd` |
| Close git diff view | `<leader>gq` |
| Format code | `<leader>f` (also automatic on save for `.zig` / `.zon`) |

---

## Moving around

### Within a line
| Key | Moves to |
| --- | --- |
| `0` / `^` / `$` | column 0 / first non-blank / end of line |
| `w` / `W` | next word / next WORD (whitespace-delimited) |
| `b` / `B` | back a word / WORD |
| `e` / `ge` | end of this word / end of previous word |
| `f<char>` / `F<char>` | forward / backward to `<char>` on this line |
| `t<char>` / `T<char>` | same, but stop just before it |
| `;` / `,` | repeat the last `f`/`t` forward / backward |
| `%` | jump to the matching bracket |

### Within the file
| Key | Moves to |
| --- | --- |
| `gg` / `G` | first line / last line |
| `{number}G` or `:{number}` | that line number |
| `{` / `}` | previous / next blank line (paragraph) |
| `H` / `M` / `L` | top / middle / bottom of the visible screen |
| `<C-d>` / `<C-u>` | half a screen down / up |
| `<C-f>` / `<C-b>` | full screen forward / back |
| `zz` / `zt` / `zb` | redraw with the cursor centred / at top / at bottom |
| `<C-o>` / `<C-i>` | back / forward through the jump list |
| `` `` `` | back to the position before the last jump |
| `` `. `` | to the last edit |

Scrolloff is 6, so the view keeps six lines of context around the cursor.

---

## Editing

| Key | Does |
| --- | --- |
| `i` / `a` | insert before / after the cursor |
| `I` / `A` | insert at first non-blank / end of line |
| `o` / `O` | open a line below / above |
| `x` / `X` | delete character under / before the cursor |
| `r<char>` | replace one character |
| `dd` / `yy` / `cc` | delete / yank / change the whole line |
| `D` / `C` / `Y` | to end of line: delete / change / yank |
| `p` / `P` | paste after / before the cursor |
| `u` / `<C-r>` | undo / redo |
| `.` | repeat the last change |
| `J` | join this line with the next |
| `>>` / `<<` | indent / dedent the line |
| `gU` / `gu` + motion | upper- / lowercase |

Operators (`d` delete, `c` change, `y` yank, `>` indent, `gU` uppercase) combine
with any motion or text object:

| Example | Effect |
| --- | --- |
| `dw` / `d$` / `dgg` | delete to next word / end of line / start of file |
| `ciw` | change the word under the cursor |
| `ci"` `ci(` `ci{` | change inside quotes / parens / braces |
| `da(` | delete a paren group *including* the parens |
| `yap` | yank a paragraph |
| `d5j` | delete this line and the 5 below |

`i` = inner (contents only), `a` = around (contents plus delimiters).

### Visual mode
| Key | Does |
| --- | --- |
| `v` / `V` / `<C-v>` | charwise / linewise / block selection |
| `o` | jump to the other end of the selection |
| `>` / `<` | indent / dedent (`gv` reselects afterwards) |
| `y` / `d` / `c` | yank / delete / change the selection |

Clipboard is `unnamedplus`, so yanks go to the system clipboard — `y` here
pastes with Ctrl+V elsewhere, and vice versa.

---

## Search and replace

| Key | Does |
| --- | --- |
| `/text` / `?text` | search forward / backward |
| `n` / `N` | next / previous match |
| `*` / `#` | search for the word under the cursor forward / backward |
| `:noh` | clear the search highlight |
| `:%s/old/new/g` | replace in the whole file |
| `:%s/old/new/gc` | same, confirming each one |
| `:s/old/new/g` | replace on the current line only |

Search is case-insensitive until you type a capital (`ignorecase` + `smartcase`).

---

## LSP — code intelligence

Attached automatically for Zig via ZLS.

| Key | Does |
| --- | --- |
| `gd` | go to definition |
| `gD` | go to declaration |
| `gi` | go to implementation |
| `gr` | list references |
| `K` | hover documentation |
| `<C-o>` | **go back** where you came from |
| `<leader>rn` | rename symbol (project-wide) |
| `<leader>ca` | code action |
| `<leader>e` | show diagnostics for this line |
| `]d` / `[d` | next / previous diagnostic |
| `<leader>f` | format buffer |

Formatting uses the LSP formatter when one is attached, and falls back to
`zig fmt` for `.zig`/`.zon` files. On save, only the LSP path runs.

### Completion (insert mode)
| Key | Does |
| --- | --- |
| `<C-Space>` | trigger completion |
| `<Tab>` / `<S-Tab>` | next / previous item, or jump through a snippet |
| `<CR>` | confirm the selected item |
| `<C-e>` | dismiss the menu |

---

## File tree

| Key | Does |
| --- | --- |
| `<C-n>` | open / close the tree |
| `<leader>n` | open it with the current file revealed |
| `q` | close it (from inside the tree) |

Inside the tree:

| Key | Does |
| --- | --- |
| `<CR>` / `o` | open file, or expand / collapse a directory |
| `<Tab>` | preview without leaving the tree |
| `<C-v>` / `<C-x>` / `<C-t>` | open in vsplit / split / new tab |
| `a` | create a file (end the name with `/` to make a directory) |
| `r` / `e` | rename / rename just the basename |
| `d` / `D` | delete / move to trash |
| `x` / `c` / `p` | cut / copy / paste |
| `y` / `Y` / `gy` | copy filename / relative path / absolute path |
| `P` / `-` | jump to parent directory / move the tree root up |
| `E` / `W` | expand all / collapse all |
| `H` / `I` | toggle dotfiles / gitignored files |
| `f` / `F` | live filter / clear the filter |
| `R` | refresh |
| `]c` / `[c` | next / previous git-changed file |
| `g?` | full help |

---

## Git

### In any file
| Key | Does |
| --- | --- |
| `]c` / `[c` | next / previous changed hunk |
| `<leader>gp` | preview the hunk under the cursor |
| `<leader>gs` | stage the hunk |
| `<leader>gr` | reset the hunk |
| `<leader>gb` | blame this line (full detail) |

Gutter markers: `│` added or changed, `_` deleted below, `‾` deleted at the
top, `~` changed and deleted, `┆` untracked.

### Diff view
| Key | Does |
| --- | --- |
| `<leader>gd` | open the diff view for the working tree |
| `<leader>gq` | close it |
| `<leader>gh` | history for the whole repo |
| `<leader>gf` | history for the current file |

Inside the diff view:

| Key | Does |
| --- | --- |
| `<Tab>` / `<S-Tab>` | next / previous changed file |
| `j` / `k` then `<CR>` | pick a file from the panel |
| `s` or `-` | stage / unstage the selected entry |
| `S` / `U` | stage all / unstage all |
| `X` | restore the file to the left-hand version |
| `<leader>b` | toggle the file panel |
| `i` | switch the panel between list and tree layout |
| `g?` | full help |

Note: inside diffview `<leader>e` focuses the file panel — it's the diagnostics
key everywhere else.

---

## Windows, tabs, buffers

`<C-w>` is the window prefix (which is why the file tree is on `<C-n>`).

| Key | Does |
| --- | --- |
| `<C-w>v` / `<C-w>s` | split vertically / horizontally |
| `<C-w>h` `j` `k` `l` | move to the window left / down / up / right |
| `<C-w>q` / `<C-w>o` | close this window / close all others |
| `<C-w>=` | equalise window sizes |
| `<C-w>+` `-` `<` `>` | resize taller / shorter / narrower / wider |
| `:tabnew` / `gt` / `gT` | new tab / next / previous |
| `:e path` | open a file |
| `:ls` | list open buffers |
| `:bn` / `:bp` / `:bd` | next / previous / close buffer |
| `<C-6>` | jump back to the previously edited buffer |

---

## Files and quitting

| Command | Does |
| --- | --- |
| `:w` / `:w path` | save / save as |
| `:q` / `:q!` | quit / quit discarding changes |
| `:wq` or `:x` | save and quit |
| `:qa!` | quit everything, discarding changes |
| `:e!` | reload the file from disk, discarding changes |

Undo is persistent (`undofile`), so `u` still works after reopening a file.

---

## Housekeeping

| Command | Does |
| --- | --- |
| `:Lazy` | plugin manager UI |
| `:Lazy update` | update plugins — rewrites `lazy-lock.json` |
| `:checkhealth` | diagnose a broken setup |
| `:LspInfo` | which language server is attached |
| `:Inspect` | what highlight group is under the cursor |

**This config is a symlink into the `miscellaneous` repo.** Editing anything in
`~/.config/nvim`, and any `:Lazy update`, shows up as an uncommitted change
there — commit it afterwards.

---

## Two quirks of this setup

`gr` is bound to LSP references, which shadows Neovim 0.11's built-in `gr`
prefix (`grn` rename, `gra` code action, `grr` references, `gri`
implementation). Use `<leader>rn` and `<leader>ca` instead — tutorials written
for stock 0.11 will mention the `gr*` ones.

Icons need a Nerd Font selected in your terminal profile.
`fedora/install-nerd-font.sh` installs JetBrainsMono; Neovim itself has no
font setting.
