# Alerta WebUI 功能分析报告

通过对 `alerta-webui` 源码库中的 [package.json](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alert-webui/package.json) 以及路由配置（[src/router.ts](file:///Users/kevinliangx/Developer/Repos/PublicCodeHub/KevinLiangX/alerta/alert-webui/src/router.ts)）和代码结构的深入分析，以下是该项目的主要技术栈以及功能模块总结。

## 1. 技术栈 (Tech Stack)
该项目是一个由 Vue.js 构建的单页面应用 (SPA)，主要使用的技术包括：
*   **核心框架:** Vue 2.7
*   **UI 组件库:** Vuetify 1.5.24 (Material Design 风格)
*   **路由管理:** Vue Router
*   **状态管理:** Vuex + vuex-router-sync
*   **语言:** TypeScript & JavaScript混合使用
*   **构建工具:** Vue CLI (基于 Webpack)
*   **请求库:** Axios
*   **图表与数据处理:** 包含汇出为 CSV (`export-to-csv`)、时间处理 (`moment`) 等功能。

## 2. 核心功能模块 (Core Features)

根据前端路由和页面视图 (`src/views/`)，系统主要包含以下几个核心模块配置：

### 2.1 告警管理 (Alert Management)
*   **告警列表 (`/alerts`):** 系统的核心页面。展示从 API 接收到的所有告警，支持通过搜索、过滤（如按环境、服务、严重程度等）来定位告警。具有 Kiosk 模式可以全屏展示作大屏监控。
*   **告警详情 (`/alert/:id`):** 查看单个告警的详细上下文及历史记录等所有关联信息。

### 2.2 监控与配置 (Monitoring & Configuration)
*   **心跳监控 (`/heartbeats`):** 接收来自其他系统或内部组件的心跳信号，用于检测监控系统本身或关键服务的存活性。
*   **静默期管理 (`/blackouts`):** 允许用户配置特定环境或服务的静默规则（Blackout），在设定时间内屏蔽不必要的告警通知（例如在系统常规维护期间）。
*   **API 密钥管理 (`/keys`):** 允许用户生成和管理 API Keys，以便第三方应用或脚本通过 API 调用与 Alerta 交互。
*   **统计分析报表 (`/reports`):** 提供告警数据的报表功能，如统计严重程度分布、发生趋势等。

### 2.3 后台管理 (Admin / Access Control)
针对管理权限的用户，系统提供了多维度的系统及权限管理能力：
*   **用户管理 (`/users`):** 管理注册系统的用户账户。
*   **分组管理 (`/groups`):** 管理用户分组，用于批量权限控制或通知路由。
*   **客户 (租户) 管理 (`/customers`):** 支持多租户或多客户的数据隔离设置。
*   **权限控制 (`/perms`):** 细粒度的角色和资源访问权限配置。

### 2.4 用户认证与个人中心 (Authentication & Profile)
*   **认证体系:** 集成了基于 `vue-authenticate` 的认证机制。包含 登录 (`/login`)、注册 (`/signup`)、登出 (`/logout`)。
*   **密码与邮箱验证:** 提供注册后的邮箱确认 (`/confirm/:token`)、忘记密码 (`/forgot`) 和重置密码 (`/reset/:token`) 流程。
*   **个人中心 (`/profile`) & 设置 (`/settings`):** 用户可以查看和修改个人信息、UI 偏好和其他系统配置属性。

## 总结
`alerta-webui` 作为一个监控报警系统的可视化控制台，功能十分完备。不仅满足了基本的告警展示、查询与详情溯源，还内置了心跳检测保障系统可用性、Blackout 规避告警风暴，并且拥有完善的用户和权限管理体系，能够满足企业级多团队、多租户的监控运维需求。
