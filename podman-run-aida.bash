podman build --no-cache --rm --file Containerfile --tag aida:demo .
podman run --interactive --tty --publish 8282:8080 aida:demo
echo "browse https://localhost:8282/"
