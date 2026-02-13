#!/bin/bash
set -euo pipefail

rm -rf _site && mkdir _site
echo '# Software Engineering II' > _site/index.md
echo -e '\nYou can view or download the latest slides here:\n' >> _site/index.md

for pause in pause nopause; do
if [[ "${pause}" == "nopause" ]]; then
    config=config.yaml
else
    config=$(mktemp)
    yq eval '.export.pauses = "new_slide"' config.yaml > "${config}"
fi

for theme in dark light; do
for file in slides/*.md; do
    echo "Building ${file} ${theme} ${pause}"
    echo $config
    name=$(basename "${file}" | cut -d . -f 1)
    source=<(sed "s#path: ../themes/dhbw_.*.yml#path: ../themes/dhbw_${theme}.yml#g" "${file}")
    echo "- ${name} [[html](${name}.html)][[pdf](${name}.pdf)]" >> _site/index.md
    just export pdf ${file} _site/${name}_${theme}_${pause}.pdf -c ${config} $@
    just export html ${file} _site/${name}_${theme}_${pause}.html -c ${config} $@
done
done
done
pandoc _site/index.md -o _site/index.html
