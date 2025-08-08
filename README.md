# sriov-nic

Systemd 模板服务与脚本，用于在 Proxmox VE（PVE）等环境下启用 SR‑IOV 并为 Virtual Functions（VF）分配自定义 MAC 地址。

## 文件说明

| 文件名               | 功能说明                                        |
|----------------------|--------------------------------------------------|
| `sriov-nic@.service` | systemd 模板服务，调用脚本完成 VF 配置          |
| `sriov-setup.sh`     | 主脚本，包含参数解析、SR‑IOV 清除与设置逻辑      |

## 使用指南

### 部署文件

将 `sriov-nic@.service` 放到 `/etc/systemd/system/`，将 `sriov-setup.sh` 安装至 `/usr/local/bin/` 并赋予可执行权限：

```bash
chmod +x /usr/local/bin/sriov-setup.sh
````

### 启用 SR‑IOV 配置

假设你要为网卡 `enp1s0f0np0` 启用 8 个 VF，MAC 前缀为 `a0a0`，则运行：

```bash
systemctl enable sriov-nic@enp1s0f0np0-8-a0a0 --now
```

设置已完成后，VF 将自动生成并带有如下形式的 MAC 地址：

```
<VendorPrefix>:a0:a0:00
<VendorPrefix>:a0:a0:01
...
<VendorPrefix>:a0:a0:07
```

### 移除 SR‑IOV 配置

若需清除 VF 设置，可将 `numvfs` 设置为 `0`：

```bash
systemctl start sriov-nic@enp1s0f0np0-0-any
```

脚本会自动清除现有 VF 并退出。

### 模拟执行（Dry‑Run）

如需验证命令而不执行：

```bash
/usr/local/bin/sriov-setup.sh -s enp1s0f0np0-8-a0a0
```

脚本将打印日志，而不进行实际操作。

## 注意事项

* 脚本需以 **root** 权限运行，才能修改 `sriov_numvfs` 和执行 `ip link` 操作。
* `sriov-nic@.service` 类型为 `oneshot`，服务完成即结束，日志状态为 `inactive (dead)` 属正常行为。
* 建议首次使用时，搭配 Dry‑Run 验证后再正式启用配置。
