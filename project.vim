args! project.vim
argadd **/*.md

if has('win32') || has('win64')
  set makeprg=.\devops.ps1
else
  set makeprg=./devops.sh
endif
