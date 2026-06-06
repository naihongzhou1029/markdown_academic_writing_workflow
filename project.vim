args! project.vim
argadd **/*.md
argadd make-docker.*
argadd paper.tex
argadd chicago-author-date.csl
argadd .api_key
argadd .gitignore
argadd Dockerfile
argadd bibliography.bib
argadd references.json

if has('win32') || has('win64')
  set makeprg=.\devops.ps1
else
  set makeprg=./devops.sh
endif
