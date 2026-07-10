# Donico 1.14.0 — Audit TODO

Findings de l'audit du code. Sévérité : 🔴 déclenché en usage normal · 🟠 latent / edge · 🟡 design / robustesse.
Couverture SimpleCov mesurée : 83.29 % lignes. Bugs C1–C4 prouvés empiriquement.

## 1. Correctness (bugs)

- [ ] 🔴 **C1 — `underscore` backreferences cassées** — `lib/donico/images/base.rb:64-65`
  `"\1_\2"` (double quotes) = octet de contrôle `0x01`, pas une backreference.
  Prouvé : `underscore("MyApp")` → `"m_pp"`. Latent (déclenché si `image_name` CamelCase).
  **Fix** : `'\1_\2'` (single quotes) ou `"\\1_\\2"`. Ajouter test unitaire `underscore`/`version_env_var`.

- [ ] 🔴 **C2 — `.downcase` corrompt la valeur des inputs de test** — `lib/donico/images/docker.rb:36`, `lib/donico/images/bake.rb:47`
  `.downcase` s'applique à `CLÉ=VALEUR` entier. Prouvé : `"BAR_VERSION=Zm9vCg=="` → `"bar_version=zm9vcg=="`.
  Incohérence : le bakefile garde la valeur correcte, mais le test Inspec la reçoit corrompue.
  Le fixture `spec/donico/rake/tasks/bake_spec.rb:189` fige ce bug.
  **Fix** : downcaser la clé uniquement. Corriger les 2 backends + le fixture.

- [ ] 🔴 **C3 — `run_cmd` : deux types de retour → `NoMethodError`** — `lib/donico.rb:125-141`
  Nominal `[success, out]`, rescue `false`. `result, log = false` → `log = nil` → `render_logs` fait `nil.empty?`.
  Prouvé : `NoMethodError`. Déclencheur : `docker` absent du PATH (`Errno::ENOENT`).
  **Fix** : `rescue` → `[false, e.message]`. Ajouter test du chemin d'exception.

- [ ] 🟠 **C4 — `cut -d '=' -f 2` tronque les valeurs contenant `=`** — `bash/donico.lib.sh:16` (`load_env`)
  Prouvé : `BAR_VERSION=Zm9vCg==` → `Zm9vCg` (padding perdu). Base64/JWT/query-strings cassés.
  **Fix** : `value=${val#*=}` (ou `cut -d '=' -f 2-`). Vérifier aussi `split_test_inputs` (word-splitting non quoté, `donico.lib.sh:91`).

- [ ] 🟠 **C5 — `Config#dockerfiles` sans `.uniq`** — `lib/donico/config.rb:30-32` (via `common.rake:8-14`)
  8 matrices `dockerfile: Dockerfile` (défaut) → hadolint lancé 8× sur le même fichier.
  **Fix** : `.uniq`. `/app` codé en dur (couplage mount CI) → extraire en constante si réutilisé.

- [ ] 🟠 **C6 — `exec` : priorité d'environnement inversée** — `lib/donico.rb:120`
  `env.merge(Bundler.original_env)` : l'env système écrase les build-args explicites.
  **Fix** : `Bundler.original_env.merge(env)`.

## 2. Concurrence / fiber-safety

- [ ] 🟡 **F1 — État global mutable au niveau module** — `lib/donico.rb:36-53`
  `@config` singleton, séquentiel-bloquant. Design mono-process par conception (parallélisme via matrice GitLab CI).
  Pas de bug actuel mais empêche multi-config / build in-process ; force `Rake::Task.clear` dans les specs.
  **Fix** : documenter l'invariant « 1 process = 1 config » OU encapsuler l'état dans une instance.

- [ ] 🟠 **F2 — `format_tag` mute `$VERBOSE` global** — `lib/donico/images/base.rb:72-79`
  Effet de bord global non réentrant pour museler un warning.
  **Fix** : restreindre les clés passées à `format` pour éliminer le besoin.

- [ ] 🟠 **F3 — `config_file` mémoïse `Dir.pwd`** — `lib/donico.rb:47-49`
  Figé au 1er appel ; `Dir.chdir` ultérieur ignoré.

## 3. Modèle d'erreur

- [ ] 🔴 **E1 — `image_builder` arbitraire → 3 points de défaillance** — `lib/donico/config.rb:11`
  Valeur non validée → `LoadError` (donico.rb:57), `raise` (matrix.rb:46-54), `NameError` (images/base.rb:22).
  **Fix** : valider `image_builder ∈ {docker, bake}` dans `Config#initialize` avec message clair.

- [ ] 🟠 **E2 — `image_name` peut être `nil` silencieusement** — `lib/donico/config.rb:8` + `lib/donico/images/base.rb:14`
  Ni top-level ni matrice → `name = nil` → tags malformés sans erreur. Spec désactivé (`config_spec.rb:16-24`).
  **Fix** : exiger `image_name` (config OU matrice) + réactiver le test.

- [ ] 🟠 **E3 — Macros de tags non validées** — `lib/donico/images/base.rb:72`
  Tag `"%<foo>s"` → `KeyError` brut non capturé.
  **Fix** : valider les macros (`arch|distro|version|timestamp`) au chargement.

- [ ] 🟠 **E4 — Secrets ignorés silencieusement en backend docker** — `lib/donico/matrix.rb:41-42`
  `secret_envs`/`secret_files` exploités seulement par le template bake ; droppés en docker sans warning.
  **Fix** : warning si `secrets?` avec backend docker.

- [ ] 🟡 **E5 — Template ERB : `secret["id"]` sans garde** — `lib/donico/data/templates/bakefile.erb:33,66`
  Secret sans `id` → `id = ""` → HCL invalide silencieux.

- [ ] 🟡 **E6 — `run_cmd` avale les exceptions** — `lib/donico.rb:137-140`
  `rescue StandardError => e; puts e; false` masque la cause (cf. C3).

## 4. Perf / mémoire / CPU

- [ ] 🟠 **P1 — hadolint N× redondant** — cf. C5 (`.uniq`).
- [ ] 🟡 **P2 — tag/push séquentiels** — `lib/donico/tasks/docker.rb:52` — un `capture3` par tag ; parallélisable si volume.
- [ ] 🟡 **P3 — `images_list` non mémoïsé** — `lib/donico.rb:85-87` — négligeable (1 appel réel).

## 5. Design d'API

- [ ] 🟠 **D1 — `Tasks::Base.tag` non implémenté par `Bake`** — `lib/donico/tasks/base.rb:15-17` vs `lib/donico/tasks/bake.rb`
  Interface de classe mensongère (`Tasks::Bake.tag` → `NoMethodError`). Non déclenché (bake.rake n'a pas de task `:tag`).
  **Fix** : ne pas hériter `tag` côté Bake OU expliciter la divergence.

- [ ] 🟠 **D2 — `build_args` : même nom, sémantiques divergentes** — `lib/donico/images/docker.rb:29-32` vs `lib/donico/images/bake.rb:26-28`
  Docker retourne la forme aplatie `--build-arg`, Bake la liste brute (forme CLI = `formatted_build_args`).
  **Fix** : `raw_build_args` / `cli_build_args`.

- [ ] 🟠 **D3 — Tri des tags incohérent entre backends** — `lib/donico/images/bake.rb:22` (sort) vs `lib/donico/tasks/docker.rb:20` (ordre YAML).

- [ ] 🟡 **D4 — Dispatch dynamique fragile** — `lib/donico/images/base.rb:22` + `lib/donico/utils.rb`
  Résolution de classe par string → `NameError` obscur. Whitelist explicite rendrait `utils.rb` supprimable.

- [ ] 🟡 **D5 — `Hooks` couplé aux internes de Rake** — `lib/donico/rake/hooks.rb:12,27,44`
  `instance_variable_get(:@tasks)` (ivar privé) → casse potentielle à l'upgrade Rake. Zéro test.

- [ ] 🟡 **D6 — `load!` couple config + tasks** — `lib/donico.rb:30-33`
  Granularité publique mal découpée (specs contournent via `load_config`/`load_tasks` séparés).

## 6. Couverture de tests + fichiers non audités

Zones totalement non testées :

- [ ] `lib/donico/utils.rb` (`constantize`) — 0 test.
- [ ] `lib/donico/images/*.rb` — aucun spec unitaire (`spec/donico/images/` absent) → C1/C2 invisibles.
- [ ] `lib/donico/matrix.rb` `generate`/`write_matrix` — 0 test (génération `.gitlab-ci/extends/.matrix.yml`).
- [ ] `lib/donico/rake/hooks.rb` — 0 test.
- [ ] `lib/donico.rb` `run_cmd` (rescue), `exec` (env merge) — non couverts (C3/C6).
- [ ] `common.rake` `generate-files`, `version`, `help` — non testés.
- [ ] `bash/donico.lib.sh`, `exe/inspec` — 0 test (C4 + word-splitting).

Faiblesses des tests existants :

- [ ] `config_spec.rb:16-24` — cas `image_name` absent commenté (E2 non gardé).
- [ ] `spec/donico/rake/tasks/bake_spec.rb:189` — fixture fige le bug C2.
- [ ] Aucun test `image_builder` invalide (E1).
- [ ] `Matrix.generate` non couvert (moitié de `generate-files`).

Actions de test prioritaires :

- [ ] Spec unitaire `Images::{Base,Docker,Bake}` → attrape C1, C2.
- [ ] Spec `run_cmd` chemin exception → attrape C3.
- [ ] Réactiver spec `image_name` manquant (E2) + ajouter `image_builder` invalide (E1).
- [ ] Harnais bats/shellcheck sur `donico.lib.sh` → attrape C4 + quoting.

## 7. Templates GitLab CI fournis (gitlab-templates/)

- [ ] 🟠 **T1 — Détection du backend par `grep -q bake donico.yml`** — `gitlab-templates/donico/extends/.docker-in-docker.yml:20`
  Le choix docker/bake se fait par grep du texte du fichier, pas par parsing de la clé `image_builder`.
  Faux positif si `bake` apparaît ailleurs (build_arg, commentaire, image_name). Fragile.
  **Fix** : `rake` expose déjà `image_builder` ; s'appuyer dessus ou parser le YAML.

- [ ] 🟡 **T2 — Commentaire erroné « Makefile recipe »** — `.docker-in-docker.yml:35` — devrait être « Rakefile ».

## 8. État de vérification

- [x] Suite RSpec exécutée via `mise test` : **64 exemples, 0 échec**. Couverture **83.52 % (370/443 lignes)**.
- [x] RuboCop exécuté via `mise lint-project` : **30 fichiers, 0 offense**.
- [x] Environnement : exécution OK sous le Ruby de `mise` (3.4.9) ; le shell direct utilisait 4.0.5 (hors contexte mise).
- [ ] C1–C4 confirmés par repro isolée (Ruby/bash), **pas encore** matérialisés en test rouge dans la suite (à faire lors du fix TDD).

## 9. Sécurité (threat-model)

Modèle de confiance : outil de build interne. Entrées = `donico.yml` (contrôlé dev), env CI, secrets CI (`REGISTRY_DOCKER_TOKEN`, `CI_JOB_TOKEN`). Sévérité : 🔴 critique · 🟠 élevé · 🟡 à durcir.

**Triage (arbitrage utilisateur) :** S1–S4 = acceptés / won't-fix (risque assumé, contexte interne). S5 = retenu (à corriger, groupé avec C4). S6 = retenu, faible priorité (fix gratuit `umask 077`).

- [ ] 🔴 ~~**S1 — ERB sur `donico.yml` = RCE par conception**~~ — WON'T FIX (risque assumé) — `lib/donico.rb:44`
  `YAML.safe_load(ERB.new(File.read(file)).result)` : le YAML est évalué comme **template ERB avant** le parsing → `donico.yml` peut contenir `<%= system(...) %>`. Utilisé légitimement (`fixtures/docker/erb.yml`) mais quiconque modifie `donico.yml` (PR non revue, dépôt compromis) obtient une RCE dans le runner CI **qui détient les secrets registry**. `safe_load` protège du YAML malveillant mais est court-circuité par l'ERB.
  **Fix** : review obligatoire de `donico.yml` ; rendre l'ERB opt-in ; a minima documenter la surface. Envisager de restreindre le binding ERB.

- [ ] 🟠 **S2 — `docker run --privileged` + image non pinnée (binfmt)** — `gitlab-templates/donico/extends/.docker-in-docker.yml:26`
  `docker run --rm --privileged tonistiigi/binfmt --install all` : conteneur privilégié exécutant une image tierce sans digest. Supply-chain : image amont compromise → exécution privilégiée sur le runner.
  **Fix** : pinner `tonistiigi/binfmt@sha256:...`.

- [ ] 🟠 **S3 — Images linters/inspec en `:latest` + `--pull always`** — `lib/donico.rb:27-28`, `common.rake:10,18`, `bash/donico.lib.sh:5`
  `commitlint:latest`, `hadolint:latest`, `inspec:latest` : tags mutables → non-reproductible + surface supply-chain (l'image peut changer sous le pied).
  **Fix** : pinner par digest ou version figée.

- [ ] 🟠 **S4 — Socket Docker hôte monté dans le conteneur Inspec** — `bash/donico.lib.sh:127`
  `--mount source=/var/run/docker.sock` = contrôle du démon Docker hôte ≈ root sur l'hôte. Inhérent au design DinD, mais tout code dans le conteneur Inspec pilote l'hôte.
  **Fix** : documenter le risque ; isoler le runner ; envisager un daemon Docker dédié/éphémère.

- [ ] 🟡 **S5 — Quoting bash absent (`load_env`, `split_test_inputs`)** — `bash/donico.lib.sh:13-19,82-97`
  `for val in ${@}` et `export ${key}=${value}` non quotés → word-splitting/globbing sur les valeurs (`*` glob-expandé, etc.). Dominé par S1 aujourd'hui (valeurs issues de donico.yml), mais fragile si les inputs viennent un jour d'une source non maîtrisée.
  **Fix** : quoter (`"${@}"`, `export "${key}=${value}"`) ; `shellcheck` en CI.

- [ ] 🟡 **S6 — Écriture des credentials registry avant `chmod`** — `.docker-in-docker.yml:13`, `.gitlab-ci.yml:47-51`
  `echo $TOKEN > ~/.docker/config.json && chmod 600` : le fichier existe brièvement avec l'umask par défaut avant le chmod. Token en clair sur le runner ; fuite possible via `set -x`/traces.
  **Fix** : `install -m 600 /dev/null <file>` puis écrire ; ou `umask 077` avant.

- [x] 🟢 **Bon point — `YAML.safe_load`** (pas `load`) : pas de désérialisation d'objets Ruby arbitraires (mais cf. S1).

## Top 5 actionable

## Top 5 actionable

| # | Fichier:ligne | Correctif |
|---|---|---|
| C1 | `images/base.rb:64-65` | `'\1_\2'` (single quotes) |
| C2 | `images/docker.rb:36`, `bake.rb:47` | downcaser la clé uniquement |
| C3 | `donico.rb:139` | `rescue` → `[false, e.message]` |
| C4 | `bash/donico.lib.sh:16` | `value=${val#*=}` |
| E1 | `config.rb:11` | valider `image_builder ∈ {docker,bake}` |
