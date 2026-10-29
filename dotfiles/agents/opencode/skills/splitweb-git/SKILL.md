---
name: splitweb-git
description: Git operations for the SplitWeb (Splitwise) repository on Gitea (git.asealab.lan/asealab/splitweb) — clone, pull, push, branches, API calls and credentials. Use whenever asked to do anything with the splitweb/splitwise git repo.
---

## Repo

- **Remoto actual**: `https://git.asealab.lan/asealab/splitweb.git`
- Rama por defecto: `main`
- Proyecto local: `/home/pozito/Documents/proyects/Asealab/splitweb`
- **NO tocar GitHub**: el remoto antiguo es `https://github.com/asealab/splitweb.git` y el usuario pidió no modificar nada remoto en GitHub.
- Gitea **no es espejo** de GitHub: historias distintas. Ramas en Gitea: `main`, `feat/new-design`, `fix-issue-1`, `fix-issue-13`, `test2`.

## Autenticación (HTTPS + PAT)

- **El token NO vive en el repo**: está cifrado con sops+age en `secrets/secrets.yaml` (clave `gitea_token`) y sops-nix lo descifra en runtime en `~/.config/gitea/token` (0400). Se lee con `$(cat ~/.config/gitea/token)`.
- Copia de trabajo en `~/.git-credentials` (helper `store`, 0600), así que `git pull/push/clone` con la URL HTTPS **ya funciona sin nada más**.
- Gitea **ignora el usuario** en la URL: sirve cualquiera (`https://cualquiera:TOKEN@git.asealab.lan/...`).
- Scopes: `write:repository` (+issues, packages...). **No tiene `read:user`**, por eso `GET /api/v1/user` devuelve error de scope — es esperado, no es un token roto.
- Para curl/API: `curl -H "Authorization: token $(cat ~/.config/gitea/token)" https://git.asealab.lan/api/v1/...`
- La instancia exige login para navegar: sin credenciales la web da **404** aunque el repo sea público (`private: false` en API).
- Revocar/regenerar: `https://git.asealab.lan/user/settings/applications`. Si lo regeneras, actualiza el secreto con `sops set secrets/secrets.yaml '["gitea_token"]' "<TOKEN>"'` y reconstruye (`home-manager` descifra en runtime).

## SSH (ROTO — no perder tiempo)

- `ssh_url`: `git@git.asealab.lan:asealab/splitweb.git`, clave en `~/.ssh/splitweb` (pub en `~/.ssh/splitweb.pub`, huella `SHA256:BTrFU+i+Pn+AolNNqN9T9ENguU5Jy0e5M9DTLayMAEg`).
- La clave **está registrada y verificada** en Gitea (firma `ssh-keygen -Y sign -n gitea`), pero el `sshd` del servidor la rechaza para **todos** los usuarios (`git`, `gitea`, `forgejo`...) → falta la integración `AuthorizedKeysCommand`↔Gitea en el servidor. Puerto 2222 cerrado; el banner de conexión dice `Not allowed at this time`.
- Hasta que el admin arregle eso, usar siempre HTTPS+token.

## Comandos útiles

```bash
# estado
git -C /home/pozito/Documents/proyects/Asealab/splitweb remote -v

# ramas remotas
git ls-remote --heads https://git.asealab.lan/asealab/splitweb.git

# API
curl -s -H "Authorization: token $(cat ~/.config/gitea/token)" \
  https://git.asealab.lan/api/v1/repos/asealab/splitweb
```

## Backup histórico (rama de GitHub)

- `/tmp/opencode/backup-splitweb-20260930/`: `splitweb.bundle` (historial completo de `main` + `feat/improve-dev-setup` del clon de GitHub, HEAD `83c6d5c`), `.env` y `Makefile.patch`.
- Restaurar una rama: `git fetch <ruta-al-bundle> 'refs/heads/*:refs/remotes/old/*'`
- Ojo: `/tmp` puede limpiarse al reiniciar; copiarlo a un sitio durable si interesa conservarlo.
