<p align="center">
  <img src="https://img.shields.io/badge/ARSADM-Development-0A66C2?style=for-the-badge&logo=github&logoColor=white" alt="ARSADM Development"/>
</p>

<h1 align="center">termux-deepseek-harness</h1>

<p align="center">
  <strong>DeepSeek Harness (DSH) — Instalador One-Click para Android / Termux e Alpine Linux</strong><br/>
  <em>Disponibilizado e mantido por <strong>ARSADM Development</strong></em>
</p>

<p align="center">
  <a href="https://github.com/ARSADM7/termux-deepseek-harness"><img src="https://img.shields.io/badge/platform-Android%20%2F%20Termux%20%7C%20Alpine%20Linux-00C853?style=flat-square" alt="platform"/></a>
  <a href="https://github.com/ARSADM7/termux-deepseek-harness"><img src="https://img.shields.io/badge/arch-arm64%20%7C%20armv7%20%7C%20x86__64%20%7C%20aarch64-blue?style=flat-square" alt="arch"/></a>
  <a href="https://github.com/ARSADM7/termux-deepseek-harness"><img src="https://img.shields.io/badge/maintained%20by-ARSADM%20Development-0A66C2?style=flat-square" alt="ARSADM"/></a>
  <a href="https://github.com/ARSADM7/termux-deepseek-harness/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="license"/></a>
  <img src="https://img.shields.io/badge/tested-Android%2011--16%20%7C%20Termux%20(F--Droid)%20%7C%20Alpine%203.18%2B-brightgreen?style=flat-square" alt="tested"/>
</p>

<p align="center">
  <a href="#-sobre-a-arsadm-development">Sobre a ARSADM</a> •
  <a href="#-instalação-rápida">Instalação</a> •
  <a href="#-funcionalidades">Funcionalidades</a> •
  <a href="#-suporte">Suporte</a> •
  <a href="#english">English</a>
</p>

---

## 🏢 Sobre a ARSADM Development

A **ARSADM Development** é uma empresa de desenvolvimento de software focada em soluções móveis, automação e inteligência artificial para Android e plataformas emergentes.

Disponibilizamos ferramentas open-source, instaladores otimizados e infraestruturas prontas para produção que eliminam a complexidade técnica e levam tecnologia de ponta diretamente ao dispositivo do utilizador — **sem root, sem complicação, apenas funciona.**

> **Missão:** Democratizar o acesso a IA e automação avançada em dispositivos Android e Linux, com qualidade profissional e suporte contínuo.

### O que disponibilizamos

| Área | Soluções |
|------|----------|
| **🤖 IA & Automação** | Instaladores otimizados para DeepSeek Harness, LLMs locais e agentes autónomos em Termux e Alpine |
| **📱 Mobile & Android** | Ferramentas nativas, adaptações mobile (userscript, bookmarklet, CSS responsivo) |
| **📺 Streaming & IPTV** | Plataformas, painéis e geradores M3U de alta performance |
| **☁️ Cloud & Infra** | Soluções de nuvem, supercomputação e APIs |
| **🛠️ DevTools** | Compilação nativa ARM64, patches node-gyp, otimizações de performance |

**Este repositório** — `termux-deepseek-harness` — é um dos projetos flagship da ARSADM Development: instaladores que resolvem de forma definitiva a instalação do `@deepseek-ai/dsh` em **Android/Termux** e **Alpine Linux**, onde o `npm install -g` oficial falha por falta de pré-compilados ARM64.

**Repositório oficial:** `ARSADM7/termux-deepseek-harness` • **Licença:** MIT • **Suporte:** GitHub Issues

---

## 📦 Sobre o projeto

Instalação **do zero ao funcionando** do [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`@deepseek-ai/dsh`) em:

| Plataforma | Instalador | Comando |
|------------|------------|---------|
| **Android / Termux** | `install.sh` | `bash install.sh` |
| **Alpine Linux 3.18+** | `install-alpine.sh` | `sh install-alpine.sh` |

Ambos são ideais para **ambientes recém-instalados**: atualização de pacotes, toolchain, Node, compilação nativa, patches de runtime e configuração de workspace são todos automatizados.

**Sem root necessário** (funciona com root também). Testado em **Android 11-16 / aarch64 / Termux (F-Droid)** e **Alpine 3.18+ / x86_64, aarch64, armv7**.

> Distribuído pela ARSADM Development como solução open-source pronta para produção.

---

## ✨ Funcionalidades

- ✅ **One-Click** — Um comando em ambiente limpo, pronto para usar
- ✅ **Idempotente** — Falhou no meio? Rode de novo, continua de onde parou
- ✅ **Rede inteligente** — Detecta falha no `registry.npmjs.org` (8s) e troca automaticamente para `npmmirror`; retentativas com timeout otimizado
- ✅ **Anti-OOM** — Limita paralelismo de compilação do `koffi` para não matar dispositivos com pouca RAM
- ✅ **Workspace padrão** — Termux: sdcard (`~/storage/shared`) | Alpine: `~/dsh-workspace`
- ✅ **Auto-verificação** — Checa `dsh` / `koffi` / `node-pty` / `sharp` / workspace no final, erro sempre em vermelho (sem falhas silenciosas)
- ✅ **Suporte ARSADM** — Mantido e documentado pela equipa ARSADM Development

---

## 🧩 Por que estes instaladores existem

`@deepseek-ai/dsh` depende de módulos nativos **sem pré-build para arm64** (Android e Alpine):

| # | Módulo | Erro original | Como a ARSADM Development resolveu |
|---|--------|---------------|--------------------------------------|
| 1 | `koffi` | `CMake does not seem to be available` | Instala `cmake clang make python binutils pkg-config` + toolchain completa |
| 2 | `koffi` | `statx` erro de compilação (bionic) | **Termux:** Compila com `-target aarch64-linux-android30` (API 30) |
| 3 | `node-pty` | `gyp: Undefined variable android_ndk_path` | **Termux:** Patch em `common.gypi` do cache node-gyp |
| 4 | todos | `install-scripts` bloqueados (npm 11.19+) | `npm config set allow-scripts=...` libera builds |
| 5 | `sharp` | `Could not load sharp android-arm64` | Fallback WebAssembly `@img/sharp-wasm32` (ambos) |
| 6 | `cordis-plugin-hmr` | `--expose-internals is required` | Wrapper de inicialização substitui symlink `dsh` (ambos) |
| 7 | sessões/attachments | `EACCES: permission denied, link()` | Patch `link() → rename()` para ROMs/sistemas que bloqueiam `link()` (ambos) |

---

## 📋 Requisitos

### Termux (Android)
- Android 11+ (API 30+, necessário para `statx`)
- [Termux **F-Droid**](https://f-droid.org/packages/com.termux/) — versão da Play Store está descontinuada
- ~4GB RAM, ~2GB armazenamento livre, internet estável
- Arquitetura: arm64 (principal) / armv7 / x86_64 / i686 — detecção automática

### Alpine Linux
- Alpine Linux 3.18+ (`/etc/alpine-release`)
- ~2GB RAM, ~2GB armazenamento livre, internet estável
- Arquitetura: x86_64 / aarch64 / armv7 — detecção automática
- Usuário não-root recomendado

---

## 🚀 Instalação rápida

### Android / Termux

Execute **dentro do Termux** (sem precisar clonar):

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ARSADM7/termux-deepseek-harness/main/install.sh)"
```

Ou clonando:

```sh
pkg install -y git
git clone https://github.com/ARSADM7/termux-deepseek-harness.git
cd termux-deepseek-harness
bash install.sh
```

> - O script roda `pkg upgrade` — **deixe terminar** (Termux não suporta upgrade parcial). Para pular: `bash install.sh --skip-upgrade`
> - Rede lenta/China: `bash install.sh --cn` (usa mirror npmmirror — detecção automática se registry oficial falhar)
> - O passo `npm install` é o mais longo (centenas de pacotes + compilação `koffi`, ~5–15 min). **Ficar sem output durante download é normal** — mantenha a tela ligada

### Alpine Linux

Execute no shell do Alpine:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ARSADM7/termux-deepseek-harness/main/install-alpine.sh)"
```

Ou clonando:

```sh
apk add --no-cache git
git clone https://github.com/ARSADM7/termux-deepseek-harness.git
cd termux-deepseek-harness
sh install-alpine.sh
```

> - O script roda `apk upgrade` — **deixe terminar**. Para pular: `sh install-alpine.sh --skip-upgrade`
> - Rede lenta/China: `sh install-alpine.sh --cn` (usa mirror npmmirror — detecção automática se registry oficial falhar)
> - Requer Node.js ≥ 22.12 — Alpine 3.19+ tem nas repositórios padrão; 3.18 pode precisar de edge/testing

---

## ✅ Após instalar (ambos)

```sh
dsh web
```

- **Termux:** No celular, abra `http://127.0.0.1:3080` ou `termux-open-url http://127.0.0.1:3080`
- **Alpine:** No navegador, abra `http://127.0.0.1:3080`
- **Rede local (ambos):** `dsh web --host 0.0.0.0` → `http://IP-DO-DISPOSITIVO:3080`
- Configure sua API Key em **Configurações → Modelos** na Web UI

---

## 📁 Workspace padrão

| Plataforma | Workspace padrão | Configuração |
|------------|------------------|--------------|
| **Termux** | `~/storage/shared` (sdcard) | `cordis.patch.yml` com `cwd: /data/data/com.termux/files/home/storage/shared` |
| **Alpine** | `~/dsh-workspace` | `cordis.patch.yml` com `cwd: /home/user/dsh-workspace` |

A Web UI passa a usar o workspace como raiz, independente de onde o `dsh web` foi iniciado.

- Customizar na instalação: `DSH_WORKSPACE=/meu/caminho bash install.sh` (ou `sh install-alpine.sh`)
- Pular: `DSH_WORKSPACE="" bash install.sh`
- Alterar depois: edite o `cwd` em `~/.dsh/profiles/web/cordis.patch.yml` e reinicie `dsh web`

---

## 📱 Adaptação mobile (opcional — apenas Termux)

A Web UI recolhe a sidebar em telas estreitas, mas painéis laterais ainda espremem o chat no celular. A ARSADM Development inclui em `mobile/`:

| Método | Navegador | Nota |
|--------|-----------|------|
| `mobile/dsh-mobile.user.js` | Kiwi / Firefox + Tampermonkey | injeção automática |
| `mobile/bookmarklet.txt` | qualquer | salve o `javascript:` como favorito e toque após carregar |
| `mobile/mobile.css` | manual | injete via console ou Stylus |

Efeito: layout coluna única, painéis ocultos (chat ocupa tudo), modais quase tela cheia, alvos de toque maiores.

---

## 🔧 O que o script faz (fluxo completo)

### Termux (`install.sh`)
1. Checagem Termux / arquitetura
2. `pkg update && pkg upgrade`
3. Toolchain: `git curl cmake clang make python binutils pkg-config libandroid-spawn`
4. Node >= 22.12
5. npm: libera `allow-scripts`, timeouts, mirror `--cn`
6. Patch `common.gypi` (`android_ndk_path`)
7. `npm i -g @deepseek-ai/dsh` (flag API 30, build `koffi` limitado, retry com mirror, checagem `dsh`)
8. Fallback sharp WASM (`@img/sharp-wasm32`)
9. Patch `link() → rename()` para ROMs que bloqueiam `link()`
10. Wrapper `--expose-internals` + pnpm
11. Permissão sdcard + workspace fixo
12. Verificação final + instruções

### Alpine (`install-alpine.sh`)
1. Checagem Alpine / arquitetura
2. `apk update && apk upgrade`
3. Toolchain: `git curl cmake clang make python3 binutils pkgconfig linux-headers build-base`
4. Node >= 22.12
5. npm: libera `allow-scripts`, timeouts, mirror `--cn`
6. `npm i -g @deepseek-ai/dsh` (build nativo `koffi`/`node-pty`, retry com mirror, checagem `dsh`)
7. Fallback sharp WASM (`@img/sharp-wasm32`)
8. Patch `link() → rename()` para sistemas que bloqueiam `link()`
9. Wrapper `--expose-internals` + pnpm
10. Workspace padrão `~/dsh-workspace`
11. Verificação final + instruções

**Ambos são idempotentes: pode re-rodar sempre.**

---

## ⚙️ Parâmetros

| Flag / Variável | Descrição | Termux | Alpine |
|-----------------|-----------|--------|--------|
| `--skip-upgrade` | pula `pkg`/`apk` update && upgrade | ✅ | ✅ |
| `--cn` | força mirror npmmirror | ✅ | ✅ |
| `DSH_WORKSPACE=/caminho` | workspace custom na instalação | ✅ | ✅ |
| `DSH_WORKSPACE=""` | pula configuração de workspace | ✅ | ✅ |
| `CMAKE_BUILD_PARALLEL_LEVEL=N` | paralelismo do koffi (padrão 2, use 1 em RAM baixa) | ✅ | ✅ |

---

## 🆘 Troubleshooting

| Sintoma | Plataforma | Solução |
|---------|------------|---------|
| OpenSSL / `shared libraries` no Node | Termux | `pkg update && pkg upgrade -y` primeiro |
| `allow-scripts is not valid` | Ambos | inofensivo — npm antigo já roda scripts por padrão |
| `CMake not available` | Ambos | re-rode o script |
| `android_ndk_path` | Termux | re-rode o script |
| `No command dsh found` | Ambos | falha no npm — veja erro em vermelho, tente `--cn` |
| >15 min sem output no npm | Ambos | rede instável — Ctrl+C e `--cn` |
| Web UI sem sdcard | Termux | `termux-setup-storage` + permissão "Arquivos e mídia" |
| `EACCES link ...` | Ambos | ROM/sistema bloqueia `link()` — re-rode para aplicar patch `rename()` |
| `[timed out]` bash | Termux | use `run_in_background: true` em dispositivos lentos |
| Node version < 22.12 | Alpine | `apk add nodejs=22 --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main` |

Mais detalhes: [deepseek-harness #136](https://github.com/deepseek-ai/deepseek-harness/discussions/136) • [#248](https://github.com/deepseek-ai/deepseek-harness/discussions/248)

---

## 🛠️ Como funciona (resumo técnico)

- **Termux Clang** mira API 24, mas `statx()` só existe em API >=30 → `-target ...android30`
- **Termux Node** reporta `platform === 'android'` → `android_ndk_path` indefinido → patch `common.gypi`
- **npm 11.19+** bloqueia install-scripts → `allow-scripts`
- **sharp** sem prebuild arm64 → WASM fallback
- **HMR** exige `--expose-internals` → wrapper custom
- **link()** falha em ROMs customizadas / alguns kernels → `rename()` atômico no mesmo diretório

---

## 💬 Suporte — ARSADM Development

Mantido com ❤️ pela **ARSADM Development**

- **GitHub:** [@ARSADM7](https://github.com/ARSADM7)
- **Repositório:** [ARSADM7/termux-deepseek-harness](https://github.com/ARSADM7/termux-deepseek-harness)
- **Issues:** [Abrir issue](https://github.com/ARSADM7/termux-deepseek-harness/issues) — respondemos em até 24h
- **Empresa:** Soluções profissionais em IA móvel, Android, Linux e automação

> Precisa de uma versão customizada para sua empresa, com branding, workspace ou modelo pré-configurado? Fale com a ARSADM Development via GitHub.

---

## 🌐 English

### About — Provided by ARSADM Development

One-click installers for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`@deepseek-ai/dsh`) on **Android / Termux** and **Alpine Linux**, **provided and maintained by ARSADM Development**. From fresh environment to working Web UI with a single command. Fixes native build chain issues where official `npm i -g` fails on arm64. No root required.

**Quick start (Termux):**
```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ARSADM7/termux-deepseek-harness/main/install.sh)"
```

**Quick start (Alpine):**
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ARSADM7/termux-deepseek-harness/main/install-alpine.sh)"
```

Full docs above (Portuguese) apply — English troubleshooting and flags are identical. For support, open an issue at `ARSADM7/termux-deepseek-harness`.

---

## 📄 Licença

[MIT](./LICENSE) — © 2026 ARSADM Development & contributors. Baseado no projeto original `cokelaoshi1/android-termux-dsh` (MIT).

<p align="center">
  <sub>Disponibilizado por <strong>ARSADM Development</strong> • Building the future on Android & Linux • <a href="https://github.com/ARSADM7">github.com/ARSADM7</a></sub>
</p>