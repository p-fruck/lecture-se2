@help:
    just --list

# show some slides. E.g.: just present slides/00-introduction.md [additional args]
@present *args:
    presenterm -c config.yaml -x {{ args }}

# e.g. just export pdf
[group('build')]
@export type file output *args:
    presenterm -x --export-{{ type }} {{ file }} --output {{ output }} {{ args }}

[group('build')]
@export-all *args:
    rm -rf _site && mkdir _site
    echo '# Software Engineering II' > _site/index.md
    echo -e '\nYou can view or download the latest slides here:\n' >> _site/index.md
    for file in slides/*.md; do \
        echo $file; \
        name=$(basename "${file}" | cut -d . -f 1); \
        echo "- ${name} [[html](${name}.html)][[pdf](${name}.pdf)]" >> _site/index.md; \
        just export pdf ${file} _site/${name}.pdf {{ args }}; \
        just export html ${file} _site/${name}.html {{ args }}; \
    done
    pandoc _site/index.md -o _site/index.html
