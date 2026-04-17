default:
    @just --list

build:
    nix build

deploy: build
    rsync -avz --delete result/ peter@luffy:/srv/html/teamsnelgrove/
