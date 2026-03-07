# Alerta 项目群分析

> 更新时间：2026-03-06

这5个项目共同构成了一套完整的告警监控平台。

---

## 项目概览

### 1. alerta/ — 核心告警服务器（Python 后端）

**用途：** 分布式告警聚合系统，对多来源告警进行去重、关联、可视化。

**技术栈：**

| 类别 | 技术 |
|------|------|
| 语言 | Python 3.9+ |
| Web 框架 | Flask 3.0.3 + Werkzeug |
| 数据库 | MongoDB 6.0+ / PostgreSQL 13+（双后端支持）|
| 数据库驱动 | pymongo 4.4.1 / psycopg2 2.9.9 |
| 认证 | PyJWT、bcrypt、mohawk（Hawk 认证）|
| 其他 | Flask-Cors、Flask-Compress、Sentry SDK、PyYAML、requests |

**主要目录结构：**

```
alerta/alerta/
├── app.py          # Flask 应用入口
├── settings.py     # 默认配置
├── models/         # 数据模型（告警、用户、黑名单等）
├── views/          # API 路由/视图
├── auth/           # 认证模块
├── database/       # 数据库抽象层（MongoDB/PostgreSQL）
├── plugins/        # 插件机制
├── webhooks/       # Webhook 接收器（Prometheus、Grafana 等）
├── utils/          # 工具函数
└── sql/            # PostgreSQL 迁移 SQL 脚本
```

---

### 2. alerta-contrib/ — 插件与集成扩展库

**用途：** 非核心但实用的扩展集合，分三类：
- **Integrations**：对接 Nagios、Zabbix、Consul、Prometheus 等外部工具
- **Plugins**：Slack、PagerDuty、OpsGenie、Telegram、MsTeams 等 30+ 通知插件
- **Webhooks**：Azure Monitor、Sentry、Mailgun 等 Webhook 适配器

**技术栈：** Python，依赖 `alerta/` 的插件 API，每个插件以独立 Python 包形式安装。

**主要目录结构：**

```
alerta-contrib/
├── integrations/   # consul, fail2ban, mailer, nagios, syslog...
├── plugins/        # slack, pagerduty, telegram, msteams, influxdb...
└── webhooks/       # azuremonitor, sentry, mailgun...
```

---

### 3. alerta-webui/ — Web 前端控制台（Vue.js）

**用途：** 官方 Web 控制台 v8.7.1，提供告警可视化、过滤、确认、状态管理等交互功能，通过 REST API 与 alerta 服务端通信。

**技术栈：**

| 类别 | 技术 |
|------|------|
| 语言 | TypeScript + JavaScript |
| 前端框架 | Vue 2.x（vue-class-component 装饰器风格）|
| UI 组件库 | Vuetify 1.x（Material Design）|
| 状态管理 | Vuex 3.x |
| 路由 | Vue Router 3.x |
| HTTP 客户端 | Axios |
| 国际化 | vue-i18n |
| 模板引擎 | Nunjucks（告警模板渲染）|
| 构建工具 | Vue CLI 4（Webpack）|
| 测试 | Jest（单元）+ Cypress（E2E）|
| 容器化 | Nginx + Docker |

**运行机制：** 构建为静态文件（`npm run build` 产出 `dist/`），通过运行时 `config.json` 配置 API 地址，无需与后端强耦合。

---

### 4. docker-alerta/ — 生产容器化部署方案

**用途：** 官方 Docker 镜像，将 alerta-server + alerta-webui + Nginx + uWSGI 打包进单一容器，一键部署完整系统。

**技术栈：**

| 类别 | 技术 |
|------|------|
| 基础镜像 | `python:3.9-slim-buster`（Debian Buster）|
| Python 服务 | alerta-server + uWSGI（5个 worker 进程）|
| Web 服务器 | Nginx |
| 进程管理 | Supervisord |
| 对外端口 | `8080`（Web）、`1717`（健康检查）|

**构建逻辑：**
1. 安装系统依赖（build-essential、nginx、MongoDB shell 等）
2. 创建 Python virtualenv，安装 alerta-server 和 alerta CLI
3. 执行 `install-plugins.sh` 安装 `plugins.txt` 中列出的插件
4. 从 GitHub Release 下载 alerta-webui v8.7.1 预构建包
5. 以非 root 用户（uid=1001）运行，Supervisord 管理 nginx + uwsgi

---

### 5. prometheus-config/ — Prometheus + Alerta 集成配置

**用途：** 将 Prometheus 监控体系与 Alerta 打通的完整 Docker Compose 编排方案。

**服务清单：**

| 服务 | 端口 | 职责 |
|------|------|------|
| Prometheus | 9090 | 指标采集 + 告警规则触发 |
| Alertmanager | 9093 | 告警路由 → Webhook → Alerta |
| node-exporter | 9100 | 主机指标采集 |
| cAdvisor | 9880 | 容器指标采集 |
| collectd-exporter | 9103 | 系统/应用指标采集 |
| Alerta | 9080 | 告警展示控制台 |
| MongoDB | — | 数据存储 |

**集成机制：** Alertmanager 通过 `webhook_configs` 将告警 POST 到 `alerta:8080/webhooks/prometheus`，利用 alerta 内置的 Prometheus Webhook 处理器（支持 BasicAuth 或 API Key 认证）。

---

## 项目间关系

```
┌─────────────────────────────────────────────────────────┐
│               alerta/ (核心 API 服务器)                   │
│          Flask + MongoDB/PostgreSQL 后端                  │
└──────────┬───────────────┬──────────────────────────────┘
           │ REST API       │ Plugin Interface
    ┌──────▼──────┐   ┌─────▼──────────────┐
    │ alerta-     │   │  alerta-contrib/   │
    │ webui/      │   │  插件/集成扩展包    │
    │ Vue 2.x     │   └────────────────────┘
    └─────────────┘
           │ 整合打包进同一容器
    ┌──────▼──────────────┐
    │   docker-alerta/    │  ← 生产一体化镜像
    │  (nginx + uwsgi)    │
    └──────────────────────┘
                ▲
                │ 使用 Docker 镜像
    ┌───────────┴─────────────┐
    │   prometheus-config/    │  ← 场景化集成配置
    │  Alertmanager → Alerta  │
    └─────────────────────────┘
```

**依赖方向总结：**
- `alerta/` 是整个体系的核心，其余4个项目都围绕它展开
- `alerta-contrib/` 扩展其能力（插件接口）
- `alerta-webui/` 提供前端 UI（REST API）
- `docker-alerta/` 负责将 server + webui 打包为生产镜像
- `prometheus-config/` 是针对 Prometheus 场景的具体生产集成示例
