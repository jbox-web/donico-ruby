# Donico

Donico est une gem Ruby pour **gérer facilement des matrices de construction d'images Docker** aussi bien localement que dans la CI, le but étant de standardiser la construction d'images Docker en utilisant au mieux les fonctionnalités offertes par la CI et le langage.

[[_TOC_]]

## Fonctionnement

Le fonctionnement de Donico repose sur un fichier de configuration : `donico.yml` ainsi que sur [Rake](https://github.com/ruby/rake), qui est l'équivalent en Ruby de [Make](https://www.gnu.org/software/make/).

Ce fichier de configuration permet de définir des matrices d'images Docker en se basant sur plusieurs dimensions :

* l'architecture cible (`i386`, `amd64`, `arm`)
* la distribution cible (`strech`, `buster`, `bullseye`)
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
registry: registry.digitick.net/images/base
image_name: foo
category: languages
matrix:
  - version: 3.0.1
    distro: bullseye
    archs: [amd64, arm64]

  - version: 3.0.1
    distro: buster
    archs: [amd64, arm64]

  - version: 2.7.3
    distro: buster
    archs: [amd64]

  - version: 2.6.8
    distro: stretch
    archs: [i386]
```

générera la matrice d'actions Rake suivante :

```sh
  rake amd64:bullseye:3.0.1:build    # Build docker image for amd64/bullseye/3.0.1
  rake amd64:bullseye:3.0.1:clean    # Clean docker image for amd64/bullseye/3.0.1
  rake amd64:bullseye:3.0.1:login    # Inspect docker image for amd64/bullseye/3.0.1
  rake amd64:bullseye:3.0.1:push     # Push docker image for amd64/bullseye/3.0.1
  rake amd64:bullseye:3.0.1:tag      # Tag docker image for amd64/bullseye/3.0.1
  rake amd64:bullseye:3.0.1:test     # Test docker image for amd64/bullseye/3.0.1
  rake amd64:buster:2.7.3:build      # Build docker image for amd64/buster/2.7.3
  rake amd64:buster:2.7.3:clean      # Clean docker image for amd64/buster/2.7.3
  rake amd64:buster:2.7.3:login      # Inspect docker image for amd64/buster/2.7.3
  rake amd64:buster:2.7.3:push       # Push docker image for amd64/buster/2.7.3
  rake amd64:buster:2.7.3:tag        # Tag docker image for amd64/buster/2.7.3
  rake amd64:buster:2.7.3:test       # Test docker image for amd64/buster/2.7.3
  rake amd64:buster:3.0.1:build      # Build docker image for amd64/buster/3.0.1
  rake amd64:buster:3.0.1:clean      # Clean docker image for amd64/buster/3.0.1
  rake amd64:buster:3.0.1:login      # Inspect docker image for amd64/buster/3.0.1
  rake amd64:buster:3.0.1:push       # Push docker image for amd64/buster/3.0.1
  rake amd64:buster:3.0.1:tag        # Tag docker image for amd64/buster/3.0.1
  rake amd64:buster:3.0.1:test       # Test docker image for amd64/buster/3.0.1
  rake arm64:bullseye:3.0.1:build    # Build docker image for arm64/bullseye/3.0.1
  rake arm64:bullseye:3.0.1:clean    # Clean docker image for arm64/bullseye/3.0.1
  rake arm64:bullseye:3.0.1:login    # Inspect docker image for arm64/bullseye/3.0.1
  rake arm64:bullseye:3.0.1:push     # Push docker image for arm64/bullseye/3.0.1
  rake arm64:bullseye:3.0.1:tag      # Tag docker image for arm64/bullseye/3.0.1
  rake arm64:bullseye:3.0.1:test     # Test docker image for arm64/bullseye/3.0.1
  rake arm64:buster:3.0.1:build      # Build docker image for arm64/buster/3.0.1
  rake arm64:buster:3.0.1:clean      # Clean docker image for arm64/buster/3.0.1
  rake arm64:buster:3.0.1:login      # Inspect docker image for arm64/buster/3.0.1
  rake arm64:buster:3.0.1:push       # Push docker image for arm64/buster/3.0.1
  rake arm64:buster:3.0.1:tag        # Tag docker image for arm64/buster/3.0.1
  rake arm64:buster:3.0.1:test       # Test docker image for arm64/buster/3.0.1
  rake i386:stretch:2.6.8:build      # Build docker image for i386/stretch/2.6.8
  rake i386:stretch:2.6.8:clean      # Clean docker image for i386/stretch/2.6.8
  rake i386:stretch:2.6.8:login      # Inspect docker image for i386/stretch/2.6.8
  rake i386:stretch:2.6.8:push       # Push docker image for i386/stretch/2.6.8
  rake i386:stretch:2.6.8:tag        # Tag docker image for i386/stretch/2.6.8
  rake i386:stretch:2.6.8:test       # Test docker image for i386/stretch/2.6.8
```

Les actions prédéfinies par Donico (`build`, `test`, `tag`, `push`, `login`, `clean`) ne sont en fait que des wrappers autour de différentes commandes `docker` :

| Commande                            | Traduction |
|-------------------------------------|------------|
| `rake amd64:bullseye:3.0.1:build`   | `docker build -f Dockerfile --tag amd64/bullseye/foo-3.0.1:20210603 --build-arg ARCH=amd64 --build-arg DISTRO_NAME=bullseye --build-arg FOO_VERSION=3.0.1 .`
| `rake amd64:bullseye:3.0.1:test`    | `bin/inspec amd64/bullseye/foo-3.0.1:20210603 3.0.1`
| `rake amd64:bullseye:3.0.1:tag`     | `docker tag amd64/bullseye/foo-3.0.1:20210603 registry.digitick.net/images/base/amd64/bullseye/foo:3.0.1`
| `rake amd64:bullseye:3.0.1:push`    | `docker push registry.digitick.net/images/base/amd64/bullseye/foo:3.0.1`
| `rake amd64:bullseye:3.0.1:login`   | `docker run -it --rm amd64/bullseye/foo-3.0.1:20210603 /bin/bash`
| `rake amd64:bullseye:3.0.1:clean`   | `docker rmi amd64/bullseye/foo-3.0.1:20210603`

Donico ajoute également des commandes utilitaires :

* `rake generate-files` : pour générer les fichiers de configuration pour Earthly et GitlabCI (voir plus bas [Intégration avec GitlabCI](#intégration-avec-gitlabci))
* `rake lint-commits` : pour linter les commits
* `rake lint-dockerfile` : pour linter le `Dockerfile`
* `rake version` : pour afficher la version de Donico


## Installation

1. Ajoutez un fichier `Gemfile` dans le dépôt de votre image Docker avec le contenu suivant


```ruby
# frozen_string_literal: true

source 'https://rubygems.org'

# When in CI use the installed gem, otherwise use latest stable version
opts = ENV.key?('CI') ? {} : { git: 'ssh://git@gitlab.digitick.net/infra/donico.git', tag: 'v1.6.0' }
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
registry: registry.digitick.net/infra/base
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

Donico fournit une image Docker pour s'intégrer facilement à GitlabCI.

Pour construire vos images Docker avec Donico dans GitlabCI il suffit :

1. De générer la matrice pour GitlabCI

```sh
bin/rake generate-matrix
```

2. De configurer GitlabCI

`.gitlab-ci.yml` :

```yml
---
.docker-in-docker:
  # Use custom Docker image with Docker installed inside
  image: registry.digitick.net/images/base/donico:latest

  # Only use Gitlab runners with "dind" (Docker in Docker) tag
  tags:
    - dind

  # Prepare build context
  before_script:
    # Login to Docker registry to push Docker image
    - mkdir ~/.docker && echo $REGISTRY_DOCKER_TOKEN > ~/.docker/config.json && chmod 600 ~/.docker/config.json

  # Build Debian images
  script: |
    # CI_JOB_NAME looks like : 'build: [buster]', here we only need the first part (before ':')
    JOB_NAME=$(echo $CI_JOB_NAME | cut -d ':' -f 1)
    # Job name that extends this job should match Rakefile recipe name.
    rake "$DOCKER_ARCH:$DOCKER_DISTRO:$VERSION:$JOB_NAME"

.image-push-rules:
  # Only publish image when:
  # - On master branch
  # - CI was triggered through GitLab UI
  # - CI was triggered through schedule
  rules:
    - if: $CI_COMMIT_BRANCH == "master"
    - if: $CI_PIPELINE_SOURCE == "web"
    - if: $CI_PIPELINE_SOURCE == "schedule"

# Include matrix build
include:
  - .gitlab-ci/extends/.matrix.yml

# Define stages to run
stages:
  - lint
  - build
  - test
  - tag
  - push
  - clean

# Define tasks to run
lint-commits:
  stage: lint

  # We can't access to $DOCKER_ARCH and $DOCKER_DISTRO here because
  # the GitlabCI matrix is not loaded
  # Anyway we don't care since it's just about mouting the current dir
  # inside commitlint container and run commitlint
  image: registry.digitick.net/images/base/amd64/buster/donico:latest

  # Only use Gitlab runners with "dind" (Docker in Docker) tag
  tags:
    - dind

  script:
    - rake $CI_JOB_NAME

lint-dockerfile:
  stage: lint

  # We can't access to $DOCKER_ARCH and $DOCKER_DISTRO here because
  # the GitlabCI matrix is not loaded
  # Anyway we don't care since it's just about mouting the current dir
  # inside hadolint container and run hadolint
  image: registry.digitick.net/images/base/amd64/buster/donico:latest

  # Only use Gitlab runners with "dind" (Docker in Docker) tag
  tags:
    - dind

  script:
    - rake $CI_JOB_NAME

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

## Configuration

Le fichier de configuration de Donico peut contenir les paramètres suivants :

| Nom          | Type           | Requis | Défaut | Description
|--------------|----------------|--------|--------|-------------
| `registry`   | `string`       | `oui`  | *na*   | Le chemin vers le registry pour pousser l'image Docker
| `image_name` | `string`       | `oui`  | *na*   | Le nom de l'image
| `category`   | `string`       | `oui`  | *na*   | La catégorie de l'image : `tools|web|db|whatever` (pour la génération automatique de la documentation)
| `matrix`     | `list[Matrix]` | `non`  | `[]`   | Une liste de `Matrix`

`Matrix` :

| Nom          | Type           | Requis | Défaut                       | Description
|--------------|----------------|--------|------------------------------|-------------
| `version`    | `string`       | `non`  | `latest`                     | La version de l'application à construire : `x.x.x|latest`
| `distro`     | `string`       | `non`  | `buster`                     | Le nom de la distribution à utiliser pour la construction : `stretch|buster|whatever`
| `archs`      | `list[string]` | `non`  | `[amd64]`                    | La liste des architectures à constuire : `[i386, amd64, whatever]`
| `build_args` | `list[string]` | `non`  | `[]`                         | Une liste d'arguments à passer au moment du build (voir: [build-time variables](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg))
| `test_args`  | `list[string]` | `non`  | `[]`                         | Une liste d'arguments à passer au moment des tests (voir: [Inspec inputs](https://docs.chef.io/inspec/inputs/))
| `tags`       | `list[string]` | `non`  | `["%<version>s-%<distro>s"]` | La liste des tags à produire

### Déclarer la liste des tags à produire

Il suffit de déclarer une liste de tags via la clé `tags` :

```yml
---
registry: registry.example.net/images/base
image_name: foo
matrix:
  - version: 1.0.0
    distro: buster
    archs: [amd64]
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

* `%<arch>s`
* `%<distro>s`
* `%<version>s`
* `%<timestamp>s`

Voir : https://ruby-doc.org/core-3.0.2/Kernel.html#method-i-sprintf

### Déclarer des arguments supplémentaires pour le build

Il suffit de déclarer une liste d'arguments via la clé `build_args` :

Exemple:

```yml
---
registry: registry.example.net/images/base
image_name: foo
matrix:
  - version: 1.0.0
    distro: buster
    archs: [amd64]
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
  - version: 1.0.0
    distro: buster
    archs: [amd64]
    test_args:
      - FOO=BAR
```

## Hooks

* `before`

Grâce au côté dynamique de Ruby, il est possible de se hooker sur une tâche en particulier pour effectuer une taĉhe **avant** la tâche Donico.

L'image Docker de Donico utilise elle même ce système de hook (grâce à la méthode `before`) pour télécharger la gem Donico avant de l'installer dans l'image Docker :)

Voir : https://gitlab.digitick.net/infra/docker-images/donico/-/blob/master/Rakefile#L14

* `redefine`

Il est également possible de **redéfinir** complètement une tâche Donico grâce à la méthode `redefine` :)

L'image Docker [gitlab-runner](https://gitlab.digitick.net/infra/docker-images/gitlab-runner) utilise cette méthode pour redéfinir complètement la tâche `inpsect` de Donico pour toutes les matrices afin d'implémenter des tests un peu plus sophistiqués.

Voir : https://gitlab.digitick.net/infra/docker-images/gitlab-runner/-/blob/master/Rakefile#L13


## Variables d'environnement

Donico embarque la gem [Dotenv](https://github.com/bkeepers/dotenv) afin de donner la possibilité de charger des variables d'environnement si besoin.

**Note:** Par défault Donico ne charge ni ne dépend d'aucune variable d'environnement. Tout passe par le fichier de configuration `donico.yml`.

L'image Docker de Donico utilise les variables d'environnement pour télécharger la gem Donico avant de l'installer dans l'image Docker :)

Voir : https://gitlab.digitick.net/infra/docker-images/donico/-/blob/master/Rakefile#L25

L'image Docker [gitlab-runner](https://gitlab.digitick.net/infra/docker-images/gitlab-runner) utilise également les variables d'environnement

Voir :

* https://gitlab.digitick.net/infra/docker-images/gitlab-runner/-/blob/master/.gitlab-ci.yml#L37
* https://gitlab.digitick.net/infra/docker-images/gitlab-runner/-/blob/master/Rakefile#L15
* https://gitlab.digitick.net/infra/docker-images/gitlab-runner/-/blob/master/bin/inspec#L56
* https://gitlab.digitick.net/infra/docker-images/gitlab-runner/-/blob/master/bin/spin-container#L12
