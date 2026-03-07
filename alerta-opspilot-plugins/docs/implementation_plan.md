# Alerta WebUI Refactoring Analysis & Migration Strategy

## 1. Current Architecture Overview

`alerta-webui` is a single-page monitoring dashboard currently built on an older frontend stack. Below is the breakdown of its current state:

*   **Framework:** Vue.js 2.7.16
*   **Component Style:** Primarily **Options API** (e.g., `data: () => ({...})`, `computed`, [watch](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/App.vue#798-801), `methods`) with some TypeScript typing. Despite the presence of `vue-class-component` in dependencies, core components like [App.vue](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/App.vue), [Alerts.vue](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/views/Alerts.vue), and [AlertList.vue](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/components/AlertList.vue) use the standard Options API.
*   **Build Tooling:** Vue CLI 4 (Webpack-based), Babel, and node-sass.
*   **State Management:** **Vuex 3**. The store is highly modularized under `src/store/` with 13 different modules ([alerts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/views/Alerts.vue#214-226), `auth`, `config`, etc.).
*   **Routing:** **Vue Router 3** ([src/router.ts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/router.ts)), utilizing lazy loading ([() => import(...)](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/views/Alerts.vue#403-406)) and hash/history mode fallback.
*   **UI Library & Styling:** **Vuetify 1.5**. The project heavily relies on Vuetify's strictly defined grid system (`<v-layout>`, `<v-flex>`), components (`<v-data-table>`, `<v-toolbar>`, `<v-btn>`), and its Material Design icon set.
*   **Language:** **TypeScript**. Most logic files ([main.ts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/main.ts), [router.ts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/router.ts), `store/*.ts`) are TypeScript, while Vue Single File Components (SFCs) are a mix but heavily lean towards standard JS inside the `<script>` tags.
*   **Authentication:** Uses `@alerta/vue-authenticate` (a custom fork of `vue-authenticate`) and Axios interceptors for handling OAuth/Basic Auth token lifecycles.

---

## 2. Target Architecture (Vue 3 + Vite + JS + Tailwind)

Based on your requirement, the new stack will be:
*   **Vue 3** (Composition API via `<script setup>`)
*   **Vite** (Next-generation, extremely fast bundler)
*   **JavaScript** (Removing TypeScript to simplify the toolchain)
*   **Tailwind CSS** (Utility-first CSS, replacing Vuetify 1.5)
*   **Pinia** (Modern Vue state management, replacing Vuex)
*   **Vue Router 4** (Vue 3 compatible)

---

## 3. Deep Analysis & Migration Challenges

### A. UI Framework Replacement (Vuetify 1.5 -> Tailwind CSS)
**This will be the most labor-intensive part of the refactor.**
*   **Markup Rewrite:** Every single `<v-...>` component must be rewritten using native HTML tags styled with Tailwind utility classes.
*   **Data Tables:** Vuetify's `<v-data-table>` (used heavily in [AlertList.vue](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/components/AlertList.vue) for sorting, pagination, and multi-select) provides a lot of out-of-the-box functionality. We will need to either build a custom Tailwind data table or adopt a headless UI table library (like `@tanstack/vue-table`).
*   **Forms & Modals:** `<v-dialog>`, `<v-text-field>`, and `<v-switch>` need to be rebuilt using Tailwind (potentially utilizing Headless UI or Radix Vue for accessibility).

### B. State Management (Vuex -> Pinia)
*   The current Vuex store uses `store.dispatch` and `store.getters` extensively across all components.
*   **Migration Path:** Pinia is the official Vue 3 recommended store. It is much simpler and eliminates mutations. We will need to rewrite the 13 Vuex modules into Pinia setup stores. Since we are moving to standard JS, we won't need the complex TypeScript interface definitions currently present in the Vuex modules.

### C. Build Tooling (Vue CLI/Webpack -> Vite)
*   Drop [vue.config.js](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/vue.config.js) and [babel.config.js](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/babel.config.js) entirely.
*   Introduce `vite.config.js`.
*   Migrate environment variables from `process.env.VUE_APP_*` to `import.meta.env.VITE_*`.
*   The [config.json](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/tsconfig.json) dynamic loading (fetching runtime config dynamically in [main.ts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/main.ts) before mounting) is a great pattern that works identically in Vite.

### D. Component Logic (Options API -> Composition API)
*   While Vue 3 supports the Options API, refactoring to `<script setup>` with Composition API will significantly reduce boilerplate, especially when consuming Pinia stores and Vue Router 4 composables (`useRouter`, `useRoute`).

### E. Downgrading TS to JS
*   As requested, moving to pure JS means stripping TypeScript types from [main.ts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/main.ts), [router.ts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/router.ts), and the store files. This simplifies the build step but removes strict compilation checks.

## 4. Proposed Execution Plan (Aligned with OpsPilot UI Strategy)

I recommend a **Double-Track Development (双轨并行) & MVP Strategy** rather than an in-place upgrade, which aligns perfectly with your [webui-refactor-analysis.md](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-opspilot-plugins/docs/webui-refactor-analysis.md) document.

**Phase 1: Foundation (Scaffolding)**
1. Initialize a new Vite + Vue 3 + Tailwind CSS project alongside the old code (e.g., `alerta-opspilot-ui`).
2. Set up Vue Router 4 and Pinia.
3. Configure `vite proxy` for local development against the existing backend API.
4. Establish the new config loading mechanism (merging env -> local -> remote).

**Phase 2: Core Infrastructure & Auth**
5. Migrate `services/api` and Axios interceptors.
6. Build a custom Pinia `auth` store to replace `@alerta/vue-authenticate`.
7. Reimplement critical utils and Vue 2 filters as composables/utility functions.

**Phase 3: MVP UI Reconstruction (Focus Area)**
8. Build shared Tailwind UI components (Buttons, Inputs, Severity Badges).
9. Implement the core MVP loop first:
   - Login Frame
   - **[AlertList](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/src/views/Alerts.vue#171-172)** (The most complex view, requiring a custom Tailwind data table or Headless UI approach)
   - `AlertDetail` (Detail view)

**Phase 4: Electron Integration & i18n**
10. Ensure the built `dist` can resolve dynamic endpoints via runtime [config.json](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-webui/tsconfig.json).
11. Embed the new `alerta-opspilot-ui` into the Electron shell acting strictly as a container hitting the K8s API.
12. Migrate `vue-i18n` to version 9 and port existing translation strings.

**Phase 5: Polish & Parity (Iterative)**
13. Port remaining management views (`Users`, `Groups`, `Settings`, etc.) one by one.

---
## User Review Required
I have successfully aligned with your [webui-refactor-analysis.md](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alerta-opspilot-plugins/docs/webui-refactor-analysis.md) document. The plan now focuses on creating a new `alerta-opspilot-ui` project configured for eventual embedding into Electron, communicating with your K8s-deployed backend.

**Critical Question:** For Phase 3 (AlertList), since it's the heaviest component, should we:
A. Write a highly customized, raw Tailwind table from scratch for maximum control?
B. Introduce a lightweight Headless Table library like `@tanstack/vue-table` to handle sorting, filtering, and pagination while we styling it with Tailwind?

Please confirm if you are ready to proceed with Phase 1 (Scaffolding the new Vite project).
