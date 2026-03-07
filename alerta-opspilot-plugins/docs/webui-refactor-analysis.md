# alerta-webui 重构分析（Vue 3 + Vite + Tailwind）

> 更新时间：2026-03-06
> 目标：从当前 `alerta-webui`（Vue 2 + Vuetify 1 + Vuex）迁移到 `Vue 3 + Vite + JavaScript + Tailwind`，并支持后端独立部署、前端嵌入 Electron。

---

## 1. 现状调研结论

### 1.1 目录与规模

- `src/views/`：19 个视图组件
- `src/components/`：30 个功能组件（含 `auth/`、`lib/`、`reports/`）
- `.vue` 组件总数：49
- `store/modules/`：14 个 Vuex 模块
- `locales/`：4 种语言（`en/fr/de/tr`）
- `filters/`：8 个 Vue2 全局 filter

### 1.2 技术特征

- 前端框架：Vue 2.7
- UI 框架：Vuetify 1.5（旧语法，如 `slot-scope`、`v-data-table` 老 API）
- 状态管理：Vuex 3（多模块 + 动态注册 auth 模块）
- 路由：vue-router 3（history 模式 + beforeEach 守卫）
- i18n：vue-i18n 8
- HTTP：axios + service 层 + 拦截器
- 配置加载：启动时异步三层合并（env → local config → remote config）

### 1.3 关键复杂点

- `AlertList.vue` 约 826 行，Vuetify 深度耦合，是迁移最大工作量
- 认证依赖 `@alerta/vue-authenticate`（Vue2 生态）
- Vue2 filters 在 Vue3 已移除，需全量改造

---

## 2. 迁移到 Vue3 的主要挑战

### 高优先级挑战（必须重构）

1. **Vuetify 1.x → Tailwind**
   - 原组件大量依赖 `v-data-table`、`v-layout`、旧插槽语法
   - 基本无法平滑升级，需要重写主要页面结构

2. **Vuex → Pinia**
   - 14 个模块迁移，尤其是 `alerts`、`auth`、`prefs`
   - 原 `store.registerModule('auth', ...)` 的动态注册逻辑需重构

3. **vue-authenticate 替换**
   - 该插件无 Vue3 直接兼容路径
   - 需改为自定义 auth store（token / userinfo / OAuth 跳转）

4. **Filters 替换**
   - `capitalize/date/timeago/shortId/...` 需改为工具函数或 composables

### 中优先级挑战（可分阶段处理）

- vue-router 3 → 4：语法调整较多但逻辑可迁移
- vue-i18n 8 → 9：初始化 API 变化，消息内容可复用
- `Vue.prototype.$config` 全局注入模式需改为 `provide/inject` 或 store
- stylus 全局样式向 Tailwind 原子类迁移

---

## 3. 建议的目标架构

```
Electron (前端壳)
└── 内嵌 alerta-opspilot-ui (Vue3 + Vite + Tailwind)
    └── HTTP 调用 Alerta API

K8s (后端)
└── Helm 部署 alerta backend（API）
    └── PostgreSQL（已有独立实例）
```

说明：
- 前后端彻底解耦，后端只提供 `/api`
- 前端通过 `config.json` 或环境变量注入 `endpoint`
- Electron 仅作为容器，不承载业务后端逻辑

---

## 4. 分阶段重构计划（建议执行顺序）

### 阶段 1：新工程搭建

- 新建 `alerta-opspilot-ui`（Vite + Vue3 + JS）
- 接入基础依赖：`vue-router@4`、`pinia`、`axios`、`vue-i18n@9`、`tailwindcss`
- 配置 `vite proxy` 对接后端 API（开发环境）

### 阶段 2：基础能力迁移

- 迁移 `services/api`（保留原接口封装思想）
- 迁移拦截器（request-id、错误处理、401 处理）
- 迁移配置加载机制（保留三层合并逻辑）

### 阶段 3：状态与路由迁移

- Vuex 14 模块映射到 Pinia stores
- 迁移路由表与守卫逻辑（19 routes）
- 建立权限控制（替代 `v-has-perms`）

### 阶段 4：UI 重构（重点）

- 先做基础 Layout（侧边栏、顶栏、通知）
- 再做核心页面：`AlertList` / `AlertDetail` / `AlertActions`
- 最后迁移管理页（Users/Groups/Keys/Blackouts/Reports）

### 阶段 5：i18n 与 Electron 集成

- 迁移现有 `en/fr/de/tr`，补充 `zh`
- Electron 加载 `dist`，运行时读取 `config.json` 指向 API

---

## 5. 迁移映射建议

| 现有技术 | 目标技术 | 迁移建议 |
|---|---|---|
| Vue2 Options API | Vue3 Composition API（可混用） | 先保留 Options API 迁移，再逐步组合式化 |
| Vuex 3 | Pinia | 按模块一对一迁移，优先 `alerts/auth/prefs` |
| Vuetify 1.5 | Tailwind + Headless UI（可选） | 不做 Vuetify 升级，直接重写核心页面 |
| Vue Filters | Utils / Composables | 建立 `utils/formatters.js` 统一替换 |
| moment | dayjs（可选） | 先兼容后替换，减少首期风险 |

---

## 6. 风险与建议

### 风险

- `AlertList` 复杂度高，若一次性重写，回归风险最大
- 认证链路重做，容易出现登录态兼容问题
- Electron 场景下要处理 CORS、API endpoint 动态注入

### 建议

1. 采用 **双轨并行**：保留老 `alerta-webui`，新项目逐页替换
2. 采用 **MVP 迁移顺序**：先「告警列表 + 详情 + 登录」形成可用闭环
3. 后端接口保持不变，前端重构独立推进
4. 每迁移 1 个模块就进行联调与截图回归

---

## 7. 可执行的下一步（落地）

1. 在 `alerta-opspilot-plugins/` 下创建 `alerta-opspilot-ui/`
2. 初始化 Vite + Vue3 + Tailwind
3. 先实现以下 3 个页面：
   - Login
   - Alerts（列表）
   - Alert Detail（详情）
4. 打通与当前 K8s 后端 API 的联调
5. 再接入 Electron
