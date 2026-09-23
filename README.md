# Donico

Donico est une gem Ruby pour **gérer facilement des matrices de construction d'images Docker** aussi bien localement que dans la CI, le but étant de standardiser la construction d'images Docker en utilisant au mieux les fonctionnalités offertes par la CI et le langage.

[[_TOC_]]

## Fonctionnement

Le fonctionnement de Donico repose sur un fichier de configuration : `donico.yml` ainsi que sur [Rake](https://github.com/ruby/rake), qui est l'équivalent en Ruby de [Make](https://www.gnu.org/software/make/).

Ce fichier de configuration permet de définir des matrices d'images Docker en se basant sur plusieurs dimensions :

* l'architecture cible (`linux/386`, `linux/amd64`, `linux/arm64`)
* la distribution cible (`stretch`, `buster`, `bullseye`)
* la version cible de l'application (`2.7.3`, `3.0.1`)

ainsi que sur des actions prédéfinies par Donico :

* `build`
* `test`
* `tag`
* `push`
* `login`
* `clean`


Ainsi, le fichier de configuration Donico suivant :

```yaml
---
registry: harbor.thetuxhouse.org/jbox/base
image_name: foo
matrix:
  - version: "3.0.1"
    distro: bullseye
    archs: [linux/amd64, linux/arm64]

  - version: "3.0.1"
    distro: buster
    archs: [linux/amd64, linux/arm64]

  - version: "2.7.3"
    distro: buster
    archs: [linux/amd64]

  - version: "2.6.8"
    distro: stretch
    archs: [linux/386]
```

> **Quotez toujours `version`.** YAML convertit une valeur non quotée comme
> `version: 3.10` en flottant `3.1` : l'image serait construite **et taguée** en
> `3.1`. Donico refuse désormais une version non textuelle plutôt que de laisser
> passer l'erreur.

générera la matrice d'actions Rake suivante :

```sh
  bin/rake 386:stretch:2.6.8:build     # Build docker image for linux/386/stretch/2.6.8
  bin/rake 386:stretch:2.6.8:clean     # Clean docker image for linux/386/stretch/2.6.8
  bin/rake 386:stretch:2.6.8:login     # Login into docker image for linux/386/stretch/2.6.8
  bin/rake 386:stretch:2.6.8:push      # Push docker image for linux/386/stretch/2.6.8
  bin/rake 386:stretch:2.6.8:tag       # Tag docker image for linux/386/stretch/2.6.8
  bin/rake 386:stretch:2.6.8:test      # Test docker image for linux/386/stretch/2.6.8
  bin/rake amd64:bullseye:3.0.1:build  # Build docker image for linux/amd64/bullseye/3.0.1
  bin/rake amd64:bullseye:3.0.1:clean  # Clean docker image for linux/amd64/bullseye/3.0.1
  bin/rake amd64:bullseye:3.0.1:login  # Login into docker image for linux/amd64/bullseye/3.0.1
  bin/rake amd64:bullseye:3.0.1:push   # Push docker image for linux/amd64/bullseye/3.0.1
  bin/rake amd64:bullseye:3.0.1:tag    # Tag docker image for linux/amd64/bullseye/3.0.1
  bin/rake amd64:bullseye:3.0.1:test   # Test docker image for linux/amd64/bullseye/3.0.1
  bin/rake amd64:buster:2.7.3:build    # Build docker image for linux/amd64/buster/2.7.3
  bin/rake amd64:buster:2.7.3:clean    # Clean docker image for linux/amd64/buster/2.7.3
  bin/rake amd64:buster:2.7.3:login    # Login into docker image for linux/amd64/buster/2.7.3
  bin/rake amd64:buster:2.7.3:push     # Push docker image for linux/amd64/buster/2.7.3
  bin/rake amd64:buster:2.7.3:tag      # Tag docker image for linux/amd64/buster/2.7.3
  bin/rake amd64:buster:2.7.3:test     # Test docker image for linux/amd64/buster/2.7.3
  bin/rake amd64:buster:3.0.1:build    # Build docker image for linux/amd64/buster/3.0.1
  bin/rake amd64:buster:3.0.1:clean    # Clean docker image for linux/amd64/buster/3.0.1
  bin/rake amd64:buster:3.0.1:login    # Login into docker image for linux/amd64/buster/3.0.1
  bin/rake amd64:buster:3.0.1:push     # Push docker image for linux/amd64/buster/3.0.1
  bin/rake amd64:buster:3.0.1:tag      # Tag docker image for linux/amd64/buster/3.0.1
  bin/rake amd64:buster:3.0.1:test     # Test docker image for linux/amd64/buster/3.0.1
  bin/rake arm64:bullseye:3.0.1:build  # Build docker image for linux/arm64/bullseye/3.0.1
  bin/rake arm64:bullseye:3.0.1:clean  # Clean docker image for linux/arm64/bullseye/3.0.1
  bin/rake arm64:bullseye:3.0.1:login  # Login into docker image for linux/arm64/bullseye/3.0.1
  bin/rake arm64:bullseye:3.0.1:push   # Push docker image for linux/arm64/bullseye/3.0.1
  bin/rake arm64:bullseye:3.0.1:tag    # Tag docker image for linux/arm64/bullseye/3.0.1
  bin/rake arm64:bullseye:3.0.1:test   # Test docker image for linux/arm64/bullseye/3.0.1
  bin/rake arm64:buster:3.0.1:build    # Build docker image for linux/arm64/buster/3.0.1
  bin/rake arm64:buster:3.0.1:clean    # Clean docker image for linux/arm64/buster/3.0.1
  bin/rake arm64:buster:3.0.1:login    # Login into docker image for linux/arm64/buster/3.0.1
  bin/rake arm64:buster:3.0.1:push     # Push docker image for linux/arm64/buster/3.0.1
  bin/rake arm64:buster:3.0.1:tag      # Tag docker image for linux/arm64/buster/3.0.1
  bin/rake arm64:buster:3.0.1:test     # Test docker image for linux/arm64/buster/3.0.1
  bin/rake generate-files              # Generate GitlabCI matrix and Bakefile
  bin/rake image-builder               # Print the configured image builder
  bin/rake lint-commits                # Lint commits
  bin/rake lint-dockerfile             # Lint Dockerfile
  bin/rake version                     # Version
```

> Cette liste est la sortie exacte de `bin/rake` (tâche par défaut : `help`) pour
> la configuration ci-dessus. En backend `bake`, la dimension architecture
> disparaît des noms de tâches : `bin/rake bullseye:3.0.1:build`.

Les actions prédéfinies par Donico (`build`, `test`, `tag`, `push`, `login`, `clean`) ne sont en fait que des wrappers autour de différentes commandes `docker` :

| Commande                            | Traduction |
|-------------------------------------|------------|
| `rake amd64:bullseye:3.0.1:build`   | `docker build -f Dockerfile --tag amd64/bullseye/foo-3.0.1:20210603 --build-arg ARCH=amd64 --build-arg DISTRO_NAME=bullseye --build-arg FOO_VERSION=3.0.1 .`
| `rake amd64:bullseye:3.0.1:test`    | `bin/inspec donico amd64/bullseye/foo-3.0.1:20210603 arch=amd64 build_date=20210603 distro_name=bullseye foo_version=3.0.1`
| `rake amd64:bullseye:3.0.1:tag`     | `docker tag amd64/bullseye/foo-3.0.1:20210603 harbor.thetuxhouse.org/jbox/base/foo:3.0.1-bullseye`
| `rake amd64:bullseye:3.0.1:push`    | `docker push harbor.thetuxhouse.org/jbox/base/foo:3.0.1-bullseye`
| `rake amd64:bullseye:3.0.1:login`   | `docker run -it --rm amd64/bullseye/foo-3.0.1:20210603 /bin/bash`
| `rake amd64:bullseye:3.0.1:clean`   | `docker rmi amd64/bullseye/foo-3.0.1:20210603`

Donico ajoute également des commandes utilitaires :

* `rake generate-files` : pour générer les fichiers de configuration pour Docker Bake et GitlabCI (voir plus bas [Intégration avec GitlabCI](#intégration-avec-gitlabci))
* `rake lint-commits` : pour linter les messages de commit (voir [Périmètre du lint des commits](#périmètre-du-lint-des-commits))
* `rake lint-dockerfile` : pour linter le `Dockerfile` (sort en erreur si hadolint remonte une violation, et respecte le `.hadolint.yaml` du projet)
* `rake image-builder` : pour afficher le backend configuré (`docker` ou `bake`) ; c'est ce qu'utilisent les templates GitlabCI pour choisir leur branche
* `rake version` : pour afficher la version de Donico
* `rake help` : la tâche par défaut, qui liste tout ce qui précède


## Migration 1.x → 2.0

La 2.0 refuse au chargement des configurations que la 1.x acceptait en produisant
silencieusement une image fausse. Le passage échoue donc **au démarrage**, avec un
message nommant la clé fautive, plutôt qu'à la publication.

| Ce qui échoue désormais | Pourquoi | Correctif |
|---|---|---|
| `version: 3.4` (non quotée) | YAML la convertit en flottant ; `3.10` devenait `3.1`, et l'image était construite **et taguée** en 3.1 | Quoter : `version: "3.4"` |
| Aucun `image_name` | Le nom valait `nil` : tags à segment vide (`/1.0.0/buster:…`), variable `_VERSION` | Déclarer `image_name` au top-level ou sur chaque entrée de matrice |
| `image_builder` inconnu | La valeur partait dans un chemin de fichier chargé par `load` | Utiliser `docker` ou `bake` |
| `%<arch>s` en backend `bake` | bake résout lui-même la liste des plateformes : aucune architecture unique au moment du tag | Retirer la macro, ou passer au backend `docker` |
| `%` littéral dans un tag | Il était absorbé silencieusement : `100%-slim` produisait `100{version: "1.0.0"}lim` | Retirer le `%` |
| `secret_envs` / `secret_files` incomplets | Un secret sans `id` produisait du HCL valide qui ne montait rien | Renseigner `id`, et `src` pour les fichiers |

Deux changements de comportement, sans erreur au chargement :

* **Les valeurs des inputs Inspec ne sont plus minusculisées** — seule la clé l'est.
  Un test qui attendait `bar_version=zm9vcg==` doit attendre `bar_version=Zm9vCg==`.
* **Les build-args de `donico.yml` priment sur l'environnement.** Une variable
  `RUBY_VERSION` exportée par votre shell n'écrase plus la version déclarée.

Enfin, si votre `Rakefile` manipule un objet image via un hook, `build_args` a été
scindé en `raw_build_args` (liste `CLÉ=VALEUR`) et `cli_build_args` (forme
`--build-arg …`).

## Installation

1. Ajoutez un fichier `Gemfile` dans le dépôt de votre image Docker avec le contenu suivant


```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

# When in CI use the installed gem, otherwise use latest stable version
opts = ENV.key?('CI') ? {} : { git: 'ssh://git@gitlab.thetuxhouse.org/docker-image-factory/donico-cli.git', tag: 'v2.0.5' }
gem 'donico', opts
```

puis lancez `bundle install` pour installer la gem.

2. Générez ensuite les binstubs pour `Rake` et `Bundler`

```sh
bundle binstub rake
bundle binstub bundler
```

3. Ajoutez un fichier `Rakefile` à la racine avec le contenu suivant

```ruby
# frozen_string_literal: true

require "donico"
Donico.load!
```

4. Ajoutez un fichier `donico.yml` à la racine avec le contenu suivant

```yaml
---
registry: harbor.thetuxhouse.org/jbox/base
image_name: skeleton
```

5. Enfin, commitez le tout!

```sh
git add Gemfile
git add Gemfile.lock
git add bin/
git add Rakefile
git add donico.yml
git commit -m "ci: build Docker image with Donico"
git push
```

## Utilisation

Vous pouvez maintenant construire, tester et pousser votre première image avec Donico :

1. `build`

```sh
bin/rake amd64:buster:latest:build
```

Lance la construction de l'image (`docker build`).

Les arguments suivants sont passés par défaut lors du build ([`--build-arg`](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg)) :

* `DISTRO_NAME` (ex: `buster`)
* `ARCH` (ex: `amd64`)
* `<image_name>_<version>` (ex: `NODEJS_VERSION`)

Vous pouvez déclarer des arguments supplémentaires via la clé [`build_args`](#déclarer-des-arguments-supplémentaires-pour-le-build).


2. `test`

```sh
bin/rake amd64:buster:latest:test
```

Lance les tests Inspec.

Les arguments suivants sont passés par défaut lors des tests ([`--input`](https://docs.chef.io/inspec/inputs/)) :

* `distro_name` (ex: `buster`)
* `arch` (ex: `amd64`)
* `<image_name>_<version>` (ex: `nodejs_version`)

Vous pouvez déclarer des arguments supplémentaires via la clé [`test_args`](#déclarer-des-arguments-supplémentaires-pour-les-tests).


3. `login`

```sh
bin/rake amd64:buster:latest:login
```

Permet de se "logger" dans l'image Docker que l'on vient de construire.


4. `tag`

```sh
bin/rake amd64:buster:latest:tag
```

Créé les tags Docker pour l'image que l'on vient de construire.

Si aucun tag n'est spécifié le tag par défaut `<version>-<distro_name>` sera créé.

Vous pouvez déclarer la liste des tags à créer via la clé [`tags`](#déclarer-la-liste-des-tags-à-produire).


5. `push`

```sh
bin/rake amd64:buster:latest:push
```

Pousse les tags que l'on vient de créer vers le registry Docker.


6. `clean`

```sh
bin/rake amd64:buster:latest:clean
```

Supprime l'image que l'on vient de construire (ex: `amd64/bullseye/foo-3.0.1:20210603`). Les tags ne sont pas touchés.


## Intégration avec GitlabCI

Donico fournit une image Docker ainsi qu'un ensemble de templates GitlabCI partagés (dans [`gitlab-templates/`](gitlab-templates/donico)) pour s'intégrer facilement à GitlabCI.

Pour construire vos images Docker avec Donico dans GitlabCI il suffit :

1. De générer les fichiers de CI

```sh
bin/rake generate-files
```

Cette commande génère `.gitlab-ci/extends/.matrix.yml` (la matrice de build) et, en mode `bake`, un `docker-bake.hcl`.

2. De configurer GitlabCI en incluant les templates Donico

`.gitlab-ci.yml` :

```yml
---
include:
  # Templates partagés fournis par Donico
  - project: docker-image-factory/donico-cli
    ref: master
    file:
      - gitlab-templates/donico/extends/.docker-in-docker.yml
      - gitlab-templates/donico/extends/.image-push-rules.yml
      - gitlab-templates/donico/stages/lint/commits.yml
      - gitlab-templates/donico/stages/lint/dockerfile.yml
  # Matrice générée par `bin/rake generate-files`
  - local: .gitlab-ci/extends/.matrix.yml

# Define stages to run
stages:
  - lint
  - build
  - test
  - tag
  - push
  - clean

build:
  stage: build
  extends:
    - .matrix
    - .docker-in-docker

test:
  stage: test
  extends:
    - .matrix
    - .docker-in-docker
  needs:
    - build

tag:
  stage: tag
  extends:
    - .matrix
    - .docker-in-docker
    - .image-push-rules
  needs:
    - test

push:
  stage: push
  extends:
    - .matrix
    - .docker-in-docker
    - .image-push-rules
  needs:
    - tag

clean:
  stage: clean
  extends:
    - .matrix
    - .docker-in-docker
    - .image-push-rules
  needs:
    - push
```

Les jobs `lint-commits` et `lint-dockerfile` sont fournis clés en main par les templates `stages/lint/*` inclus ci-dessus.

Le template `.docker-in-docker` détecte automatiquement le backend (`docker` ou `bake`) et configure QEMU/buildx pour les builds multi-architecture en mode `bake`.

### Périmètre du lint des commits

`rake lint-commits` n'analyse pas tout l'historique : il passe à commitlint une
plage explicite, dont la borne de départ dépend du pipeline.

| Contexte | Point de départ | Variable GitLab |
|---|---|---|
| Merge request | La base de la MR | `CI_MERGE_REQUEST_DIFF_BASE_SHA` |
| Poussée sur une branche | L'état de la branche avant la poussée | `CI_COMMIT_BEFORE_SHA` |
| En local, ou première poussée d'une branche | `HEAD~1` | *aucune* |

Ces variables sont posées par GitlabCI, il n'y a rien à configurer. En local, seul
le dernier commit est vérifié.

> L'invocation historique `commitlint /app` ne fonctionnait que par accident :
> l'argument positionnel est ignoré, et commitlint retombait sur « tout
> l'historique ». Ce repli a disparu en version 13 — la commande lit alors
> l'entrée standard, fermée en CI, et échoue donc sur **chaque** commit. D'où la
> plage explicite.

### Le linter et le `mise.toml` du projet

Les deux tâches de lint disent à leur conteneur d'ignorer le `mise.toml` du
projet monté. Les images de linters étant basées sur mise, et mise lisant la
configuration du répertoire où il démarre, il tentait de provisionner la chaîne
d'outils du projet et abandonnait avant que le linter ne s'exécute.

Le répertoire de travail reste dans `/app` : hadolint y cherche le
`.hadolint.yaml` du projet, et commitlint y lance `git`.

## Configuration

Le fichier de configuration de Donico peut contenir les paramètres suivants :

| Nom             | Type           | Requis | Défaut     | Description
|-----------------|----------------|--------|------------|-------------
| `registry`      | `string`       | `oui`  | *na*       | Le chemin vers le registry pour pousser l'image Docker
| `image_name`    | `string`       | `oui`* | *na*       | Le nom de l'image. *Requis ici **ou** sur chaque entrée de `matrix` ; la valeur de la matrice prime.
| `image_builder` | `string`       | `non`  | `docker`   | Le backend de construction : `docker` ou `bake`. Toute autre valeur est refusée au chargement. En `bake`, la dimension architecture disparaît des noms de tâches et `generate-files` produit un `docker-bake.hcl`.
| `commit_linter` | `string`       | `non`  | *image commitlint Donico* | L'image Docker utilisée par `rake lint-commits`
| `docker_linter` | `string`       | `non`  | *image hadolint Donico*   | L'image Docker utilisée par `rake lint-dockerfile`
| `matrix`        | `list[Matrix]` | `non`  | `[{}]`     | Une liste de `Matrix`

`Matrix` :

| Nom            | Type           | Requis | Défaut                       | Description
|----------------|----------------|--------|------------------------------|-------------
| `image_name`   | `string`       | `non`  | *`image_name` du top-level*  | Le nom de l'image pour cette entrée uniquement. Prime sur le `image_name` global.
| `version`      | `string`       | `non`  | `latest`                     | La version de l'application à construire : `x.x.x` ou `latest`. **Doit être quotée** : YAML transformerait `3.10` en flottant `3.1`.
| `distro`       | `string`       | `non`  | `buster`                     | Le nom de la distribution à utiliser pour la construction : `stretch`, `buster`, `bookworm`…
| `archs`        | `list[string]` | `non`  | `["linux/amd64"]`            | La liste des plateformes à construire, au format `os/arch` : `[linux/386, linux/amd64, linux/arm64]`
| `dockerfile`   | `string`       | `non`  | `Dockerfile`                 | Le chemin du Dockerfile à utiliser pour cette entrée (permet un Dockerfile par version)
| `build_args`   | `list[string]` | `non`  | `[]`                         | Une liste d'arguments `CLÉ=VALEUR` à passer au moment du build (voir: [build-time variables](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg))
| `test_args`    | `list[string]` | `non`  | `[]`                         | Une liste d'arguments `CLÉ=VALEUR` à passer au moment des tests (voir: [Inspec inputs](https://docs.chef.io/inspec/inputs/)). Seule la clé est minusculisée, la valeur est transmise telle quelle.
| `secret_envs`  | `list[Secret]` | `non`  | `[]`                         | Secrets montés depuis l'environnement. Chaque entrée exige un `id`. **Backend `bake` uniquement** — un avertissement est émis en backend `docker`.
| `secret_files` | `list[Secret]` | `non`  | `[]`                         | Secrets montés depuis un fichier. Chaque entrée exige un `id` et un `src`. **Backend `bake` uniquement**.
| `tags`         | `list[string]` | `non`  | `["%<version>s-%<distro>s"]` | La liste des tags à produire

Exemple de secrets (backend `bake`) :

```yaml
matrix:
  - version: "3.4"
    distro: bookworm
    secret_envs:
      - id: GITHUB_TOKEN
    secret_files:
      - id: aws
        src: "${HOME}/.aws/credentials"
```

Un `secret_envs` suppose que la variable soit **exportée** dans l'environnement du
build :

```sh
export GITHUB_TOKEN=…
bin/rake bookworm:3.4:build
```

Donico le vérifie avant d'appeler `docker` et s'arrête en nommant la variable
manquante. Sans ce contrôle, buildx retombe sur une lecture de *fichier* portant
le nom de l'`id` et signale `failed to stat GITHUB_TOKEN: no such file or
directory` — un fichier que personne n'a jamais mentionné. Même contrôle sur le
`src` d'un `secret_files`, sauf s'il contient une référence HCL (`${HOME}/…`),
que bake résout lui-même.

### Déclarer la liste des tags à produire

Il suffit de déclarer une liste de tags via la clé `tags` :

```yml
---
registry: registry.example.net/images/base
image_name: foo
matrix:
  - version: "1.0.0"
    distro: buster
    archs: [linux/amd64]
    tags:
      - latest                                          # latest
      - "%<version>s"                                   # 1.0.0
      - "%<version>s-%<distro>s"                        # 1.0.0-buster
      - "%<timestamp>s-%<distro>s"                      # 20210603-buster
      - "%<version>s-%<timestamp>s-%<distro>s"          # 1.0.0-20210603-buster
      - "%<version>s-%<timestamp>s-%<distro>s-%<arch>s" # 1.0.0-20210603-buster-amd64
```

Les tags peuvent être personnalisés grâce à des macros qui seront évaluées au moment de la création des tags.

Les macros suivantes sont disponibles :

| Macro          | Backend `docker` | Backend `bake` |
|----------------|------------------|----------------|
| `%<version>s`  | ✅               | ✅             |
| `%<distro>s`   | ✅               | ✅             |
| `%<timestamp>s`| ✅               | ✅             |
| `%<arch>s`     | ✅               | ❌ (bake résout lui-même la liste des plateformes : il n'y a pas d'architecture unique au moment du tag) |

Les tags sont validés au chargement de `donico.yml` : une macro inconnue ou un `%`
littéral est refusé avec un message nommant le tag fautif. Sans cette validation,
un `%` littéral était silencieusement absorbé (`100%-slim` produisait
`100{version: "1.0.0"}lim`).

Voir : https://ruby-doc.org/core-3.0.2/Kernel.html#method-i-sprintf

### Déclarer des arguments supplémentaires pour le build

Il suffit de déclarer une liste d'arguments via la clé `build_args` :

Exemple:

```yml
---
registry: registry.example.net/images/base
image_name: foo
matrix:
  - version: "1.0.0"
    distro: buster
    archs: [linux/amd64]
    build_args:
      - FOO=BAR
```

### Déclarer des arguments supplémentaires pour les tests

Il suffit de déclarer une liste d'arguments via la clé `test_args` :

Exemple:

```yml
---
registry: registry.example.net/images/base
image_name: foo
matrix:
  - version: "1.0.0"
    distro: buster
    archs: [linux/amd64]
    test_args:
      - FOO=BAR
```

## Modèle de sécurité

Donico est un outil de build interne. Trois surfaces sont **assumées** par
conception ; elles sont listées ici pour qu'elles soient connues, pas pour être
contournées.

1. **`donico.yml` est évalué comme un template ERB avant d'être parsé.**

   C'est ce qui permet d'y écrire `<%= ENV.fetch('FOO') %>`. Corollaire : quiconque
   peut modifier `donico.yml` peut exécuter du code arbitraire dans le runner CI,
   lequel détient le token du registry et le socket Docker. `YAML.safe_load`
   protège du YAML malveillant mais ne protège **pas** de l'ERB, qui s'exécute
   avant lui.

   → Traitez `donico.yml` comme du code : review obligatoire, `CODEOWNERS`.

2. **Le socket Docker de l'hôte est monté dans le conteneur Inspec.**

   Nécessaire pour tester une image depuis l'intérieur d'un conteneur (DinD).
   Cela donne à tout code s'exécutant dans ce conteneur — y compris vos propres
   contrôles Inspec — le contrôle du démon Docker de l'hôte, soit l'équivalent
   d'un accès root sur le runner.

   → Isolez les runners `dind` ; ne les partagez pas avec des projets non fiables.

3. **Les images outils (`hadolint`, `commitlint`, `inspec`) sont référencées par
   tag mutable et tirées avec `--pull always`.**

   Les builds ne sont donc pas reproductibles dans le temps, et une image amont
   modifiée s'exécute sans changement de commit.

   → Les clés `commit_linter` et `docker_linter` permettent d'épingler vos propres
   images par digest depuis `donico.yml`.

## Hooks

* `before`

Grâce au côté dynamique de Ruby, il est possible de se hooker sur une tâche en particulier pour effectuer une taĉhe **avant** la tâche Donico.

L'image Docker de Donico utilise elle même ce système de hook (grâce à la méthode `before`) pour télécharger la gem Donico avant de l'installer dans l'image Docker :)

Voir : https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/donico/-/blob/master/Rakefile#L14

* `after`

Le pendant de `before`, pour exécuter une tâche **après** la tâche Donico.

> ⚠️ **`after` ne fonctionne pas sur les tâches `build`, `test`, `clean`, `login`
> (ni `push` en backend `bake`).** Ces tâches se terminent par `Kernel.exec`, qui
> **remplace** le process courant : le bloc `after` n'est jamais atteint, et rien
> ne le signale (code de sortie 0). Utilisez `before` ou `redefine` pour ces
> tâches. Cette sémantique `exec` est volontaire (elle nettoie l'environnement
> Bundler avant d'appeler `bin/inspec`, voir le commentaire dans `lib/donico.rb`).

* `redefine`

Il est également possible de **redéfinir** complètement une tâche Donico grâce à la méthode `redefine` :)

L'image Docker [gitlab-runner](https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/gitlab-runner) utilise cette méthode pour redéfinir complètement la tâche `inpsect` de Donico pour toutes les matrices afin d'implémenter des tests un peu plus sophistiqués.

Voir : https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/gitlab-runner/-/blob/master/Rakefile#L13


## Variables d'environnement

Donico embarque la gem [Dotenv](https://github.com/bkeepers/dotenv) afin de donner la possibilité de charger des variables d'environnement si besoin.

**Note:** Par défault Donico ne charge ni ne dépend d'aucune variable d'environnement. Tout passe par le fichier de configuration `donico.yml`.

Deux variables sont toutefois lues par Donico lui-même :

| Variable              | Effet |
|-----------------------|-------|
| `CI_COMMIT_TIMESTAMP` | Positionnée par GitlabCI. Sert d'horodatage du tag de build (`%Y%m%d%H%M%S`). En son absence, Donico utilise la date du jour (`%Y%m%d`).
| `DONICO_QUIET`        | Si définie, Donico n'affiche plus les commandes `docker` qu'il exécute.

⚠️ Les build args déclarés dans `donico.yml` **priment** sur les variables de même
nom présentes dans l'environnement. Une variable `RUBY_VERSION` exportée par
chruby/rvm/direnv ne peut donc plus écraser silencieusement la version déclarée.

L'image Docker de Donico utilise les variables d'environnement pour télécharger la gem Donico avant de l'installer dans l'image Docker :)

Voir : https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/donico/-/blob/master/Rakefile#L25

L'image Docker [gitlab-runner](https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/gitlab-runner) utilise également les variables d'environnement

Voir :

* https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/gitlab-runner/-/blob/master/.gitlab-ci.yml#L37
* https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/gitlab-runner/-/blob/master/Rakefile#L15
* https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/gitlab-runner/-/blob/master/bin/inspec#L56
* https://gitlab.thetuxhouse.org/docker-image-factory/docker-images/gitlab-runner/-/blob/master/bin/spin-container#L12
