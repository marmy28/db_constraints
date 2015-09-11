cd docs
for i in ./*.html; do mv "$i" "${i%\.html}.md"; done
