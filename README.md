<p align="center">
  <img src="https://img.shields.io/badge/ARSADM-Development-0A66C2?style=for-the-badge&logo=github&logoColor=white" alt="ARSADM Development"/>
</p>

<h1 align="center">termux-deepseek-harness</h1>

<p align="center">
  <strong>DeepSeek Harness (DSH) — Instalador One-Click para Android / Termux</strong><br/>
  <em>Disponibilizado e mantido por <strong>ARSADM Development</strong></em>
</p>

<p align="center">
  <a href="https://github.com/ARSADM7/termux-deepseek-harness"><img src="https://img.shields.io/badge/platform-Android%20%2F%20Termux-00C853?style=flat-square" alt="platform"/></a>
  <a href="https://github.com/ARSADM7/termux-deepseek-harness"><img src="https://img.shields.io/badge/arch-arm64%20%7C%20armv7%20%7C%20x86__64-blue?style=flat-square" alt="arch"/></a>
  <a href="https://github.com/ARSADM7/termux-deepseek-harness"><img src="https://img.shields.io/badge/maintained%20by-ARSADM%20Development-0A66C2?style=flat-square" alt="ARSADM"/></a>
  <a href="https://github.com/ARSADM7/termux-deepseek-harness/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="license"/></a>
  <img src="https://img.shields.io/badge/tested-Android%2011--16%20%7C%20Termux%20(F--Droid)-brightgreen?style=flat-square" alt="tested"/>
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

> **Missão:** Democratizar o acesso a IA e automação avançada em dispositivos Android, com qualidade profissional e suporte contínuo.

### O que disponibilizamos

| Área | Soluções |
|------|----------|
| **🤖 IA & Automação** | Instaladores otimizados para DeepSeek Harness, LLMs locais e agentes autónomos em Termux |
| **📱 Mobile & Android** | Ferramentas nativas, adaptações mobile (userscript, bookmarklet, CSS responsivo) |
| **📺 Streaming & IPTV** | Plataformas, painéis e geradores M3U de alta performance |
| **☁️ Cloud & Infra** | Soluções de nuvem, supercomputação e APIs |
| **🛠️ DevTools** | Compilação nativa ARM64, patches node-gyp, otimizações de performance |

**Este repositório** — `termux-deepseek-harness` — é um dos projetos flagship da ARSADM Development: um instalador que resolve de forma definitiva a instalação do `@deepseek-ai/dsh` em Android/Termux, onde o `npm install -g` oficial falha por falta de pré-compilados ARM64.

**Repositório oficial:** `ARSADM7/termux-deepseek-harness` • **Licença:** MIT • **Suporte:** GitHub Issues

---

## 📦 Sobre o projeto

Instalação **do zero ao funcionando** do [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`@deepseek-ai/dsh`) em **Android via Termux** com um único comando. Ideal para **Termux recém-instalado**: `pkg update`, toolchain, Node, compilação nativa, patches de runtime e permissões de armazenamento são todos automatizados.

**Sem root necessário** (funciona com root também). Testado em **Android 16 / aarch64 / Termux (F-Droid)**.

> Distribuído pela ARSADM Development como solução open-source pronta para produção.

---

## ✨ Funcionalidades

- ✅ **One-Click** — Um comando em Termux limpo, pronto para usar
- ✅ **Idempotente** — Falhou no meio? Rode de novo, continua de onde parou
- ✅ **Rede inteligente** — Detecta falha no `registry.npmjs.org` (8s) e troca automaticamente para `npmmirror`; retentativas com timeout otimizado
- ✅ **Anti-OOM** — Limita paralelismo de compilação do `koffi` para não matar celulares com pouca RAM
- ✅ **Workspace padrão = sdcard** — Web UI já lê/escreve no armazenamento do celular
- ✅ **Auto-verificação** — Checa `dsh` / `koffi` / `node-pty` / `sharp` / `sdcard` no final, erro sempre em vermelho (sem falhas silenciosas)
- ✅ **Suporte ARSADM** — Mantido e documentado pela equipa ARSADM Development

---

## 🧩 Por que este instalador existe

`@deepseek-ai/dsh` depende de módulos nativos **sem pré-build para android-arm64**:

| # | Módulo | Erro original | Como a ARSADM Development resolveu |
|---|--------|---------------|--------------------------------------|
| 1 | `koffi` | `CMake does not seem to be available` | Instala `cmake clang make python binutils pkg-config libandroid-spawn` |
| 2 | `koffi` | `statx` erro de compilação (bionic) | Compila com `-target aarch64-linux-android30` (API 30) |
| 3 | `node-pty` | `gyp: Undefined variable android_ndk_path` | Patch em `common.gypi` do cache node-gyp |
| 4 | todos | `install-scripts` bloqueados (npm 11.19+) | `npm config set allow-scripts=...` libera builds |
| 5 | `sharp` | `Could not load sharp android-arm64` | Fallback WebAssembly `@img/sharp-wasm32` |
| 6 | `cordis-plugin-hmr` | `--expose-internals is required` | Wrapper de inicialização substitui symlink `dsh` |

---

## 📋 Requisitos

- Android 11+ (API 30+, necessário para `statx`)
- [Termux **F-Droid**](https://f-droid.org/packages/com.termux/) — versão da Play Store está descontinuada
- ~4GB RAM, ~2GB armazenamento livre, internet estável
- Arquitetura: arm64 (principal) / armv7 / x86_64 / i686 — detecção automática

---

## 🚀 Instalação rápida

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

---

## ✅ Após instalar

```sh
dsh web
```

- No celular: abra `http://127.0.0.1:3080` ou `termux-open-url http://127.0.0.1:3080`
- No PC na mesma rede: `dsh web --host 0.0.0.0` → `http://IP-DO-CELULAR:3080`
- Configure sua API Key em **Configurações → Modelos** na Web UI

---

## 📁 Workspace padrão = sdcard

Distribuído pela ARSADM Development com integração total ao armazenamento:

1. **Permissão:** roda `termux-setup-storage` (Android 11+ abre tela "Acesso a todos os arquivos") e cria `~/storage/shared`
2. **Workspace fixo:** grava em `~/.dsh/profiles/web/cordis.patch.yml`:

```yaml
- id: fs-sandbox
  config:
    cwd: /data/data/com.termux/files/home/storage/shared
```

A Web UI passa a usar a sdcard como raiz, independente de onde o `dsh web` foi iniciado.

- Customizar na instalação: `DSH_WORKSPACE=/meu/caminho bash install.sh`
- Pular: `DSH_WORKSPACE="" bash install.sh`
- Alterar depois: edite o `cwd` em `cordis.patch.yml` e reinicie `dsh web`

---

## 📱 Adaptação mobile (opcional)

A Web UI recolhe a sidebar em telas estreitas, mas painéis laterais ainda espremem o chat no celular. A ARSADM Development inclui em `mobile/`:

| Método | Navegador | Nota |
|--------|-----------|------|
| `mobile/dsh-mobile.user.js` | Kiwi / Firefox + Tampermonkey | injeção automática |
| `mobile/bookmarklet.txt` | qualquer | salve o `javascript:` como favorito e toque após carregar |
| `mobile/mobile.css` | manual | injete via console ou Stylus |

Efeito: layout coluna única, painéis ocultos (chat ocupa tudo), modais quase tela cheia, alvos de toque maiores.

---

## 🔧 O que o script faz (fluxo completo)

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

Idempotente: pode re-rodar sempre.

---

## ⚙️ Parâmetros

| Flag / Variável | Descrição |
|-----------------|-----------|
| `--skip-upgrade` | pula `pkg update && pkg upgrade` |
| `--cn` | força mirror npmmirror |
| `DSH_WORKSPACE=/caminho` | workspace custom na instalação |
| `DSH_WORKSPACE=""` | pula configuração de workspace |
| `CMAKE_BUILD_PARALLEL_LEVEL=N` | paralelismo do koffi (padrão 2, use 1 em RAM baixa) |

---

## 🆘 Troubleshooting

| Sintoma | Solução |
|---------|---------|
| OpenSSL / `shared libraries` no Node | `pkg update && pkg upgrade -y` primeiro |
| `allow-scripts is not valid` | inofensivo — npm antigo já roda scripts por padrão |
| `CMake not available` | re-rode o script |
| `android_ndk_path` | re-rode o script |
| `No command dsh found` | falha no npm — veja erro em vermelho, tente `--cn` |
| >15 min sem output no npm | rede instável — Ctrl+C e `--cn` |
| Web UI sem sdcard | `termux-setup-storage` + permissão "Arquivos e mídia" |
| `EACCES link ...` | ROM bloqueia `link()` — re-rode para aplicar patch `rename()` |
| `[timed out]` bash | use `run_in_background: true` em dispositivos lentos |

Mais detalhes: [deepseek-harness #136](https://github.com/deepseek-ai/deepseek-harness/discussions/136) • [#248](https://github.com/deepseek-ai/deepseek-harness/discussions/248)

---

## 🛠️ Como funciona (resumo técnico)

- Clang do Termux mira API 24, mas `statx()` só existe em API >=30 → `-target ...android30`
- Node do Termux reporta `platform === 'android'` → `android_ndk_path` indefinido → patch `common.gypi`
- npm 11.19+ bloqueia install-scripts → `allow-scripts`
- `sharp` sem prebuild Android → WASM
- HMR exige `--expose-internals` → wrapper

---

## 💬 Suporte — ARSADM Development

Mantido com ❤️ pela **ARSADM Development**

- **GitHub:** [@ARSADM7](https://github.com/ARSADM7)
- **Repositório:** [ARSADM7/termux-deepseek-harness](https://github.com/ARSADM7/termux-deepseek-harness)
- **Issues:** [Abrir issue](https://github.com/ARSADM7/termux-deepseek-harness/issues) — respondemos em até 24h
- **Empresa:** Soluções profissionais em IA móvel, Android e automação

> Precisa de uma versão customizada para sua empresa, com branding, workspace ou modelo pré-configurado? Fale com a ARSADM Development via GitHub.

---

## 🌐 English

### About — Provided by ARSADM Development

One-click installer for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`@deepseek-ai/dsh`) on **Android / Termux**, **provided and maintained by ARSADM Development**. From fresh Termux to working Web UI with a single command. Fixes native build chain issues where official `npm i -g` fails on Android/arm64. No root required.

**Quick start (Termux):**
```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ARSADM7/termux-deepseek-harness/main/install.sh)"
```
Full docs above (Portuguese) apply — English troubleshooting and flags are identical. For support, open an issue at `ARSADM7/termux-deepseek-harness`.

---

## 📄 Licença

[MIT](./LICENSE) — © 2026 ARSADM Development & contributors. Baseado no projeto original `cokelaoshi1/android-termux-dsh` (MIT).

<p align="center">
  <sub>Disponibilizado por <strong>ARSADM Development</strong> • Building the future on Android • <a href="https://github.com/ARSADM7">github.com/ARSADM7</a></sub>
</p>
