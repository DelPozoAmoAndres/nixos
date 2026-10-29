# Inventario de credenciales

Todas las credenciales de servicios viven **cifradas** en este repositorio con
`sops` + `age`. El repositorio es público: lo que hay aquí es texto cifrado, y
la clave que lo descifra **no** está en el repo.

- Clave age (privada): `~/.config/sops/age/keys.txt` (0600, fuera del repo).
  Sin ella no se puede descifrar nada: es el punto único de fallo.
- Ficheros cifrados:
  - `secrets/secrets.yaml` → ámbito **usuario** (home-manager).
  - `secrets/system-secrets.yaml` → ámbito **sistema** (NixOS).
- Descifrado: en runtime, por el servicio `sops-nix` (usuario) y el script de
  activación (sistema). El texto plano vive solo en `$XDG_RUNTIME_DIR`
  (tmpfs) o en `/run/secrets-for-users`, **nunca** en el nix store ni en disco.
- Las plantillas (`sops.templates`) se renderizan sustituyendo marcadores
  literales (`__GITHUB_TOKEN__`, `__GITEA_TOKEN__`, ...) por los valores.

## Secretos de usuario (`secrets/secrets.yaml`)

| Clave | Servicio | Qué es | Dónde se usa | Cómo rotarlo |
|-------|----------|--------|--------------|--------------|
| `github_token` | GitHub | PAT (`ghp_…`) | `~/.config/github/token`, helper de git (`~/.config/git/credentials`), `gh` (`~/.config/gh/hosts.yml`) | `sops set secrets/secrets.yaml '["github_token"]' "<PAT>"'` + `nixos-rebuild switch` |
| `gitea_token` | Gitea (`git.asealab.lan`) | PAT, scope `write:repository` | `~/.config/gitea/token`, helper de git | `sops set secrets/secrets.yaml '["gitea_token"]' "<PAT>"'` |
| `docker_auth` | Docker (`docker.asealab.lan`) | `auth` base64 del registro | `~/.config/docker/auth`, `~/.config/docker/config.json` | `sops set secrets/secrets.yaml '["docker_auth"]' "<base64>"'` |
| `penpot_mcp_key` | Penpot | MCP key (`userToken=…`) | `~/.config/penpot/mcp-key`, MCP de opencode | `sops set secrets/secrets.yaml '["penpot_mcp_key"]' "<KEY>"'` |
| `stitch_api_key` | Stitch (Google) | `X-Goog-Api-Key` | `~/.config/stitch/api-key`, MCP de opencode | `sops set secrets/secrets.yaml '["stitch_api_key"]' "<KEY>"'` |
| `splitweb_ssh_key` | Gitea (SSH) | clave privada OpenSSH | `~/.ssh/splitweb` | `sops set secrets/secrets.yaml '["splitweb_ssh_key"]' "<clave>"'` |
| `id_oracle` | VPS Oracle | clave privada RSA | `~/.ssh/id_oracle` | `sops set secrets/secrets.yaml '["id_oracle"]' "<clave>"'` |
| `social_network_backend_env` | social-network (backend) | `.env.dev` (DB, Redis, OpenRouter, tokens de revisión) | symlink `backend/.env.dev` → `~/.config/sops-nix/secrets/social-network-backend.env` | `sops set secrets/secrets.yaml '["social_network_backend_env"]' "$(cat .env.dev)"` |
| `social_network_app_env` | social-network-app | `.env` (Supabase) | symlink `.env` → `~/.config/sops-nix/secrets/social-network-app.env` | `sops set secrets/secrets.yaml '["social_network_app_env"]' "$(cat .env)"` |

## Secretos de sistema (`secrets/system-secrets.yaml`)

| Clave | Servicio | Qué es | Dónde se usa | Cómo rotarlo |
|-------|----------|--------|--------------|--------------|
| `user_password_hash` | Sistema | hash de la contraseña de `pozito` | `/run/secrets-for-users/user_password_hash` (lo lee `users-groups` en la activación) | `sops set secrets/system-secrets.yaml '["user_password_hash"]' "<hash>"'` |

## Proyectos de asealab (NO se tocan)

`splitweb`, `splitapp` y el resto de repos de `asealab` **no están gestionados
por sops y no se tocan**: sus credenciales se quedan en sus `.env` locales y
nada de ellos se sube a este repositorio (ni a ningun repo nuestro). Si un
propio de asealab pide un cambio, se hace solo en su maquina y nunca se pushea.

## Excepciones (fuera de sops, a propósito)

| Credencial | Dónde | Por qué no se sopea |
|------------|-------|---------------------|
| `splitweb/.env` (postgres, pocketbase, session secret) | disco, 0644 | Proyecto de asealab: sus credenciales no se mueven ni se guardan en este repo. |
| `~/.config/pangolin/accounts.json` (sessionToken + secreto OLM) | disco, 0600 | La app **gestiona y refresca** su propio token de sesión. Si el fichero viniera de sops, en el siguiente arranque se usaría un token caducado y la VPN no conectaría. |
| Clave age privada | `~/.config/sops/age/keys.txt`, 0600 | Es la clave maestra: no puede estar cifrada con sí misma. Necesita backup cifrado **fuera de este disco**. |
| `~/.config/sops/age/keys.txt` (pública) `age16vsm…` | `secrets/*.yaml` | Recipient público: cifrado, se puede publicar. |

## Procedimiento habitual

```bash
# 1. Editar un secreto (abre el editor con el valor descifrado)
sops secrets/secrets.yaml

# 2. Aplicar (descifra en runtime y vuelve a renderizar las plantillas)
sudo nixos-rebuild switch --flake ~/nixos#pozito-desktop

# 3. Comprobar que no queda nada en claro
git grep -nE "(ghp_|glpat-|sk-[a-z]{20,}|AIza|-----BEGIN .*PRIVATE KEY)" HEAD
```

Los proyectos de aplicación toman sus variables de los `.env` que son
**symlinks** a los secretos descifrados, así que tras rotar un secreto basta
con reconstruir el sistema (o reiniciar la sesión) para que las apps lo vean.

## Qué NO debe volver a pasar

- Ningún secreto en claro en el repo (ni en los repos de las apps).
- Los `.env` de las apps son symlinks, no ficheros reales: `git add` de un
  symlink es inofensivo, pero no debe sustituirse por un fichero real.
- Revisar `git log -p` antes de hacer públicos los repos de las apps.
