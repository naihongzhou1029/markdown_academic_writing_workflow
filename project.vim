args! project.vim
argadd **/*.md
argadd tools/**
argadd devops.sh
argadd devops.ps1
argadd reference.json
argadd zh-tw.ini
argadd cover_page.tex
argadd Dockerfile
argadd paper.toc
argadd paper.tex

if has('win32') || has('win64')
  set makeprg=powershell\ -ExecutionPolicy\ Bypass\ -File\ ./devops.ps1\ $*
else
  set makeprg=./devops.sh\ $*
endif
