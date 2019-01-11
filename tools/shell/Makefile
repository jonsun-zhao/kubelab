doc:
	echo '# Functions\n' > func.md
	echo '```sh' >> func.md
	egrep '^k|^g' k8s.sh | sort -u >> func.md
	echo '```' >> func.md