---
name: mms-unix-sync-api-contract
description: >-
  Handles mms-unix offline cashier synchronization contracts with MMS Admin. Use when working on sync APIs, offline补传, syncQueue, order/member/ticket/catalog/staff/settings queue payloads, App-Id/Authorization headers, idempotency, or POS app version checks.
---

# mms-unix 同步接口契约

## 调用时机

遇到以下任务先读取本技能：

- 设计、修改或联调 `mms-unix` 与 MMS Admin 的同步接口。
- 处理离线收银、联网补传、`syncQueue`、本地优先数据写入。
- 讨论订单、会员、券码、基础资料、员工、设置的同步 payload。
- 排查同步失败、幂等去重、失败原因回写、本地营业不中断。
- 接入或校验 POS App 版本检测接口。

## 权威来源

源文档：`/Users/shanpengnian/MyWork/mms-cashier/mms-unix/docs/sync-api-contract.md`

维护规则：源文档若更新，先对照源文档刷新本技能，再执行开发或联调。

## 总体模型

`mms-unix` 离线收银端采用本地数据库优先：

1. 营业动作先写本地：`orders`、`members`、`ticketRecords`、`employees`、`settings`、`syncQueue`。
2. 联网后按 `syncQueue` 逐条补传。
3. 服务端以客户端 `id` 或 `receiptNo` 做幂等去重。
4. 失败原因写回 `syncQueue.errorMessage`。
5. 同步失败不阻断本地营业。

## 通用约定

- Base URL 来自本地设置：`settings.apiBaseUrl`。
- 请求头必须包含 `App-Id`。
- 登录后的接口额外包含 `Authorization`。
- 成功响应统一为：`{ "code": 200, "data": {}, "msg": "success" }`。
- 失败响应保留业务原因，由客户端回写本地队列错误信息。

## 接口清单

| 业务域 | Endpoint | 本地队列类型 | 关键约束 |
|---|---|---|---|
| 订单同步 | `POST /api/order/sync` | `order` | 以订单 `id` 或 `receiptNo` 幂等去重 |
| 会员操作 | `POST /api/member/operate` | `member` | 支持 `open`、`recharge`、`consume` |
| 券码核销 | `POST /api/ticket/verify` | `ticket` | 离线登记，联网后补传，失败原因写回核销记录 |
| 基础资料同步 | `POST /api/pos/basic/sync` | `catalog`、`staff`、`settings` | 支持菜品、员工、交班、设置动作 |
| 版本检测 | `GET /api/app/version?type=2&currentVersionCode=100` | 非队列 | 设置页触发，下载安装由 Android 更新流程接入 |

## Payload 约束

### 订单同步

请求体以 `orders` 数组承载订单。订单至少包含：

- 主标识：`id`、`receiptNo`
- 场景信息：`tableName`、`cashier`、`createdAt`
- 状态：`status`
- 明细：`items[]`
- 汇总：`summary`
- 支付：`payment`

### 会员操作

支持动作：

- `open`
- `recharge`
- `consume`

服务端返回最新会员余额和积分。客户端可在同步成功后刷新本地会员档案。

### 券码核销

请求至少包含：

- `action: "verify"`
- `code`
- `source: "offline"`
- `recordId`

响应 `data.status` 可为：`success`、`failed`、`pending`。失败时 `data.reason` 写入本地核销记录。

### 基础资料同步

支持动作：

- `createDish`
- `updateDish`
- `toggleDish`
- `createEmployee`
- `updateEmployee`
- `handover`
- `saveSettings`

## 处理顺序

1. 先确认本地队列类型与业务动作是否匹配。
2. 再确认请求头、Base URL、登录态来源。
3. 再确认 payload 是否携带客户端唯一标识。
4. 再确认服务端是否按 `id` 或 `receiptNo` 幂等去重。
5. 最后确认失败原因能否回写到本地队列或业务记录。

## 关联技能

- 研发流程：`mms-dev-workflow`
- `mms-unix` 运行与排障：`mms-unix-hbuilderx-runbook`
- `mms-unix` 编码与组件约束：`mms-unix-coding-standards`、`m-unix-component-api`